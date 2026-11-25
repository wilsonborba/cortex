import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/remote_cli.dart';
import 'remote_cli_gateway.dart';

enum RemoteCliCommandStatus {
  none,
  promptSent,
  promptQueuedOffline,
  commandExpired,
  cancelPending,
  cancelled,
}

class RemoteCliAttachment {
  const RemoteCliAttachment({required this.name, required this.fileId});
  final String name;
  final String fileId;
}

/// Owns remote-session state, stream reconnection and command deduplication.
class RemoteCliController extends ChangeNotifier {
  RemoteCliController({
    required this.gateway,
    this.reconnectDelay = const Duration(seconds: 2),
  });

  final RemoteCliGateway gateway;
  final Duration reconnectDelay;
  final sessions = <RemoteCliSession>[];
  final events = <RemoteCliEvent>[];
  final attachments = <RemoteCliAttachment>[];
  final answeringApprovals = <String>{};
  final answeredApprovals = <String>{};

  RemoteCliSession? activeSession;
  bool loadingSessions = false;
  bool reconnecting = false;
  bool streamExpired = false;
  bool cancelQueued = false;
  Object? failure;
  RemoteCliCommandStatus commandStatus = RemoteCliCommandStatus.none;
  int lastEventId = 0;
  int _generation = 0;
  bool _disposed = false;

  List<RemoteCliEvent> get approvalRequests => events
      .where((event) => event.kind == 'approval_request')
      .where((event) {
        final id = _approvalId(event);
        return id != null && !answeredApprovals.contains(id);
      })
      .toList(growable: false);

  static String? _approvalId(RemoteCliEvent event) {
    final id = event.payload['approval_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> refreshSessions() async {
    loadingSessions = true;
    failure = null;
    _notify();
    try {
      final updated = await gateway.sessions();
      sessions
        ..clear()
        ..addAll(updated);
      final current = activeSession;
      if (current != null) {
        activeSession = sessions.where((s) => s.id == current.id).firstOrNull;
      }
    } catch (error) {
      failure = error;
    } finally {
      loadingSessions = false;
      _notify();
    }
  }

  Future<void> openSession(RemoteCliSession session) async {
    _generation++;
    activeSession = session;
    events.clear();
    attachments.clear();
    answeringApprovals.clear();
    answeredApprovals.clear();
    lastEventId = 0;
    streamExpired = false;
    reconnecting = false;
    cancelQueued = false;
    commandStatus = RemoteCliCommandStatus.none;
    failure = null;
    _notify();
    unawaited(_listen(session.id, _generation));
  }

  Future<void> _listen(String sessionId, int generation) async {
    while (!_disposed && generation == _generation && !streamExpired) {
      try {
        await for (final event in gateway.events(
          sessionId,
          after: lastEventId,
        )) {
          if (_disposed || generation != _generation) return;
          if (event.id <= lastEventId) continue;
          lastEventId = event.id;
          events.add(event);
          _observe(event);
          reconnecting = false;
          failure = null;
          _notify();
        }
        if (_disposed || generation != _generation) return;
        reconnecting = true;
        _notify();
      } catch (error) {
        if (_disposed || generation != _generation) return;
        if (error is RemoteCliFailure && error.expired) {
          streamExpired = true;
          reconnecting = false;
          failure = error;
          _notify();
          return;
        }
        reconnecting = true;
        failure = error;
        _notify();
      }
      await Future<void>.delayed(reconnectDelay);
    }
  }

  void _observe(RemoteCliEvent event) {
    switch (event.kind) {
      case 'command_expired':
        commandStatus = RemoteCliCommandStatus.commandExpired;
        break;
      case 'turn_end':
        final status = event.payload['status'];
        cancelQueued = false;
        commandStatus = status == 'cancelled'
            ? RemoteCliCommandStatus.cancelled
            : RemoteCliCommandStatus.none;
        break;
      case 'approval_answer':
        final id = event.payload['approval_id'];
        if (id is String) answeredApprovals.add(id);
        break;
      case 'cancel':
        cancelQueued = true;
        break;
    }
  }

  Future<void> sendPrompt(String prompt) async {
    final session = activeSession;
    final text = prompt.trim();
    if (session == null || text.isEmpty) return;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    _notify();
    try {
      await gateway.sendPrompt(
        session.id,
        text,
        fileIds: [for (final file in attachments) file.fileId],
      );
      attachments.clear();
      commandStatus = session.online
          ? RemoteCliCommandStatus.promptSent
          : RemoteCliCommandStatus.promptQueuedOffline;
    } catch (error) {
      failure = error;
    }
    _notify();
  }

  Future<void> attachImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  }) async {
    final session = activeSession;
    if (session == null) return;
    failure = null;
    _notify();
    try {
      final id = await gateway.uploadImage(
        name: name,
        bytes: bytes,
        contentType: contentType,
      );
      attachments.add(RemoteCliAttachment(name: name, fileId: id));
    } catch (error) {
      failure = error;
    }
    _notify();
  }

  void removeAttachment(RemoteCliAttachment attachment) {
    attachments.remove(attachment);
    _notify();
  }

  Future<void> answerApproval(
    String approvalId, {
    required bool approved,
  }) async {
    final session = activeSession;
    if (session == null ||
        answeredApprovals.contains(approvalId) ||
        !answeringApprovals.add(approvalId)) {
      return;
    }
    failure = null;
    _notify();
    try {
      await gateway.answerApproval(session.id, approvalId, approved: approved);
      answeredApprovals.add(approvalId);
    } catch (error) {
      if (error is RemoteCliFailure && error.status == 409) {
        answeredApprovals.add(approvalId);
      } else {
        failure = error;
      }
    } finally {
      answeringApprovals.remove(approvalId);
      _notify();
    }
  }

  Future<void> cancel({String? turnId}) async {
    final session = activeSession;
    if (session == null) return;
    failure = null;
    _notify();
    try {
      await gateway.cancel(session.id, turnId: turnId);
      cancelQueued = true;
      commandStatus = RemoteCliCommandStatus.cancelPending;
    } catch (error) {
      failure = error;
    }
    _notify();
  }

  Future<void> closeSession() async {
    _generation++;
    activeSession = null;
    events.clear();
    attachments.clear();
    answeringApprovals.clear();
    answeredApprovals.clear();
    lastEventId = 0;
    reconnecting = false;
    streamExpired = false;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
