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
  static const maxStoredEvents = 500;
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
  bool sendingPrompt = false;
  bool turnRunning = false;
  Object? failure;
  RemoteCliCommandStatus commandStatus = RemoteCliCommandStatus.none;
  int lastEventId = 0;
  int _generation = 0;
  int _sessionListGeneration = 0;
  bool _disposed = false;
  StreamIterator<RemoteCliEvent>? _eventIterator;
  final Map<String, StringBuffer> _turnAnswers = {};
  final Set<String> _endedTurnIds = {};
  int _legacyTurnSequence = 0;
  String? _currentAnswerKey;
  String? _activeTurnId;
  String get answerText => _turnAnswers.values
      .map((answer) => answer.toString())
      .where((answer) => answer.isNotEmpty)
      .join('\n\n');
  int get operationEpoch => _generation;

  bool isCurrentSession(String sessionId, int epoch) =>
      !_disposed && _generation == epoch && activeSession?.id == sessionId;

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
    final generation = _sessionListGeneration;
    loadingSessions = true;
    failure = null;
    _notify();
    try {
      final updated = await gateway.sessions();
      if (_disposed || generation != _sessionListGeneration) return;
      sessions
        ..clear()
        ..addAll(updated);
      final current = activeSession;
      if (current != null) {
        activeSession = sessions.where((s) => s.id == current.id).firstOrNull;
        if (activeSession == null) unawaited(closeSession());
      }
    } catch (error) {
      if (_disposed || generation != _sessionListGeneration) return;
      failure = error;
      if (error is RemoteCliFailure && error.expired) {
        await closeSession(clearSessions: true);
        if (_disposed) return;
        failure = error;
        streamExpired = true;
      }
    } finally {
      if (!_disposed && generation == _sessionListGeneration) {
        loadingSessions = false;
        _notify();
      }
    }
  }

  Future<void> openSession(RemoteCliSession session) async {
    _generation++;
    final previous = _eventIterator;
    _eventIterator = null;
    if (previous != null) {
      unawaited(previous.cancel().catchError((Object _) {}));
    }
    activeSession = session;
    events.clear();
    _clearTurns();
    attachments.clear();
    answeringApprovals.clear();
    answeredApprovals.clear();
    lastEventId = 0;
    streamExpired = false;
    reconnecting = false;
    cancelQueued = false;
    sendingPrompt = false;
    commandStatus = RemoteCliCommandStatus.none;
    failure = null;
    _notify();
    unawaited(_listen(session.id, _generation));
  }

  Future<void> _listen(String sessionId, int generation) async {
    while (!_disposed && generation == _generation && !streamExpired) {
      final iterator = StreamIterator<RemoteCliEvent>(
        gateway.events(sessionId, after: lastEventId),
      );
      _eventIterator = iterator;
      try {
        while (await iterator.moveNext()) {
          if (_disposed || generation != _generation) return;
          final event = iterator.current;
          if (event.id <= lastEventId) continue;
          lastEventId = event.id;
          _recordAnswer(event);
          events.add(event);
          if (events.length > maxStoredEvents) {
            events.removeRange(0, events.length - maxStoredEvents);
          }
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
      } finally {
        if (identical(_eventIterator, iterator)) _eventIterator = null;
        await iterator.cancel();
      }
      await Future<void>.delayed(reconnectDelay);
    }
  }

  void _observe(RemoteCliEvent event) {
    final turnId = event.payload['turn_id'];
    final suppliedTurnId = turnId is String && turnId.isNotEmpty
        ? turnId
        : null;
    switch (event.kind) {
      case 'command_expired':
        commandStatus = RemoteCliCommandStatus.commandExpired;
        break;
      case 'turn_end':
        final status = event.payload['status'];
        if (suppliedTurnId != null) _endedTurnIds.add(suppliedTurnId);
        if (suppliedTurnId == null || suppliedTurnId == _activeTurnId) {
          turnRunning = false;
          _activeTurnId = null;
          if (suppliedTurnId == null && _currentAnswerKey != null) {
            _endedTurnIds.add(_currentAnswerKey!);
            _currentAnswerKey = null;
          }
        }
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
      case 'progress':
      case 'answer_part':
      case 'approval_request':
        if (suppliedTurnId == null || !_endedTurnIds.contains(suppliedTurnId)) {
          turnRunning = true;
          if (suppliedTurnId != null) _activeTurnId = suppliedTurnId;
        }
        break;
    }
  }

  void _recordAnswer(RemoteCliEvent event) {
    if (event.kind != 'answer_part') return;
    final rawTurnId = event.payload['turn_id'];
    final turnId = rawTurnId is String && rawTurnId.isNotEmpty
        ? rawTurnId
        : null;
    final key =
        turnId ??
        (_currentAnswerKey != null && !_endedTurnIds.contains(_currentAnswerKey)
            ? _currentAnswerKey!
            : 'legacy-${++_legacyTurnSequence}');
    final answer = _turnAnswers.putIfAbsent(key, StringBuffer.new);
    _currentAnswerKey = key;
    answer.write(event.payload['text'] ?? '');
  }

  void _clearTurns() {
    _turnAnswers.clear();
    _endedTurnIds.clear();
    _legacyTurnSequence = 0;
    _currentAnswerKey = null;
    _activeTurnId = null;
    turnRunning = false;
  }

  Future<bool> sendPrompt(String prompt) async {
    final session = activeSession;
    final generation = _generation;
    final text = prompt.trim();
    if (session == null || text.isEmpty || sendingPrompt) return false;
    final sentAttachments = List<RemoteCliAttachment>.of(attachments);
    sendingPrompt = true;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    _notify();
    try {
      await gateway.sendPrompt(
        session.id,
        text,
        fileIds: [for (final file in sentAttachments) file.fileId],
      );
      if (!isCurrentSession(session.id, generation)) return false;
      attachments.removeWhere(sentAttachments.contains);
      commandStatus = session.online
          ? RemoteCliCommandStatus.promptSent
          : RemoteCliCommandStatus.promptQueuedOffline;
      return true;
    } catch (error) {
      if (!isCurrentSession(session.id, generation)) return false;
      failure = error;
      return false;
    } finally {
      if (isCurrentSession(session.id, generation)) {
        sendingPrompt = false;
        _notify();
      }
    }
  }

  Future<void> attachImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  }) async {
    final session = activeSession;
    if (session == null) return;
    final generation = _generation;
    failure = null;
    _notify();
    try {
      final id = await gateway.uploadImage(
        name: name,
        bytes: bytes,
        contentType: contentType,
      );
      if (_disposed || generation != _generation) return;
      attachments.add(RemoteCliAttachment(name: name, fileId: id));
    } catch (error) {
      if (_disposed || generation != _generation) return;
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
    final generation = _generation;
    failure = null;
    _notify();
    try {
      await gateway.answerApproval(session.id, approvalId, approved: approved);
      if (_disposed || generation != _generation) return;
      answeredApprovals.add(approvalId);
    } catch (error) {
      if (_disposed || generation != _generation) return;
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
    final generation = _generation;
    failure = null;
    _notify();
    try {
      await gateway.cancel(session.id, turnId: turnId);
      if (_disposed || generation != _generation) return;
      cancelQueued = true;
      commandStatus = RemoteCliCommandStatus.cancelPending;
    } catch (error) {
      if (_disposed || generation != _generation) return;
      failure = error;
    }
    _notify();
  }

  Future<void> closeSession({bool clearSessions = false}) async {
    _generation++;
    if (clearSessions) _sessionListGeneration++;
    final previous = _eventIterator;
    _eventIterator = null;
    activeSession = null;
    if (clearSessions) sessions.clear();
    events.clear();
    _clearTurns();
    attachments.clear();
    answeringApprovals.clear();
    answeredApprovals.clear();
    lastEventId = 0;
    reconnecting = false;
    streamExpired = false;
    cancelQueued = false;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    loadingSessions = false;
    sendingPrompt = false;
    _notify();
    if (previous != null) {
      unawaited(previous.cancel().catchError((Object _) {}));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _sessionListGeneration++;
    final iterator = _eventIterator;
    _eventIterator = null;
    if (iterator != null) {
      unawaited(iterator.cancel().catchError((Object _) {}));
    }
    sessions.clear();
    activeSession = null;
    events.clear();
    attachments.clear();
    answeringApprovals.clear();
    answeredApprovals.clear();
    _clearTurns();
    lastEventId = 0;
    loadingSessions = false;
    reconnecting = false;
    streamExpired = false;
    cancelQueued = false;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    super.dispose();
  }
}
