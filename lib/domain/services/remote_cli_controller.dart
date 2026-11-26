import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/api.dart';
import '../models/remote_cli.dart';
import 'remote_cli_gateway.dart';

enum RemoteCliCommandStatus {
  none,
  promptSent,
  promptQueuedOffline,
  commandExpired,
  cancelPending,
  cancelled,
  turnFailed,
  turnIncomplete,
}

class RemoteCliAttachment {
  const RemoteCliAttachment({required this.name, required this.fileId});
  final String name;
  final String fileId;
}

enum RemoteCliTurnStatus {
  queued,
  awaitingResponse,
  running,
  complete,
  incomplete,
  failed,
  cancelled,
}

/// One serialized CLI turn. The service does not emit child IDs for most
/// events, so locally submitted turns are separated at each terminal event;
/// an explicit service turn_id is retained whenever it is present.
class RemoteCliTurn {
  RemoteCliTurn({
    required this.key,
    required this.prompt,
    this.remoteTurnId,
    this.commandId,
    this.status = RemoteCliTurnStatus.awaitingResponse,
  });

  final String key;
  String prompt;
  String? remoteTurnId;
  int? commandId;
  final List<RemoteCliEvent> events = [];
  final StringBuffer _answer = StringBuffer();
  RemoteCliTurnStatus status;
  bool cancelPending = false;

  String get answer => _answer.toString();
  bool get active =>
      status == RemoteCliTurnStatus.queued ||
      status == RemoteCliTurnStatus.awaitingResponse ||
      status == RemoteCliTurnStatus.running;

  void appendAnswer(Object? text) => _answer.write(text ?? '');
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
  bool get turnRunning =>
      _activeTurn?.status == RemoteCliTurnStatus.awaitingResponse ||
      _activeTurn?.status == RemoteCliTurnStatus.running;
  bool get promptAwaitingStart =>
      _activeTurn?.status == RemoteCliTurnStatus.awaitingResponse ||
      _activeTurn?.status == RemoteCliTurnStatus.queued;
  Object? failure;
  RemoteCliCommandStatus commandStatus = RemoteCliCommandStatus.none;
  int lastEventId = 0;
  int _generation = 0;
  int _sessionListGeneration = 0;
  bool _disposed = false;
  StreamIterator<RemoteCliEvent>? _eventIterator;
  final turns = <RemoteCliTurn>[];
  final Map<String, RemoteCliTurn> _turnsByRemoteId = {};
  final Map<int, RemoteCliTurn> _turnsByEventId = {};
  final Set<int> _expiredCommandIds = {};
  int _legacyTurnSequence = 0;
  RemoteCliTurn? _activeTurn;
  String get answerText =>
      turns.where((turn) => turn.answer.isNotEmpty).lastOrNull?.answer ?? '';
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
    turns.clear();
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
    final suppliedTurnId = _remoteTurnId(event);
    final turn = _turnForEvent(event, suppliedTurnId);
    if (turn != null) {
      _turnsByEventId[event.id] = turn;
      turn.events.add(event);
    }
    switch (event.kind) {
      case 'command_expired':
        final commandId = event.payload['command_id'];
        if (commandId is num) {
          final expiredTurn = turns
              .where((item) => item.commandId == commandId.toInt())
              .firstOrNull;
          if (expiredTurn != null && expiredTurn.active) {
            expiredTurn.status = RemoteCliTurnStatus.failed;
            if (identical(_activeTurn, expiredTurn)) {
              _activeTurn = null;
              commandStatus = RemoteCliCommandStatus.commandExpired;
            }
          } else if (expiredTurn == null && sendingPrompt) {
            _expiredCommandIds.add(commandId.toInt());
          }
        }
        break;
      case 'turn_end':
        if (turn == null || !turn.active) break;
        final wasCurrentTurn = identical(_activeTurn, turn);
        final status = event.payload['status'];
        turn.status = switch (status) {
          'cancelled' => RemoteCliTurnStatus.cancelled,
          'error' => RemoteCliTurnStatus.failed,
          'incomplete' => RemoteCliTurnStatus.incomplete,
          _ => RemoteCliTurnStatus.complete,
        };
        turn.cancelPending = false;
        if (wasCurrentTurn) {
          _activeTurn = null;
          cancelQueued = false;
          commandStatus = switch (status) {
            'cancelled' => RemoteCliCommandStatus.cancelled,
            'error' => RemoteCliCommandStatus.turnFailed,
            'incomplete' => RemoteCliCommandStatus.turnIncomplete,
            _ => RemoteCliCommandStatus.none,
          };
        }
        break;
      case 'approval_answer':
        final id = event.payload['approval_id'];
        if (id is String) answeredApprovals.add(id);
        break;
      case 'cancel':
        if (turn != null && turn.active && identical(_activeTurn, turn)) {
          turn.cancelPending = true;
          cancelQueued = true;
          commandStatus = RemoteCliCommandStatus.cancelPending;
        }
        break;
      case 'progress':
        if (turn != null && turn.active) {
          turn.status = RemoteCliTurnStatus.running;
          if (_activeTurn == null || identical(_activeTurn, turn)) {
            _activeTurn = turn;
          }
          if (identical(_activeTurn, turn)) {
            switch (event.payload['status']) {
              case 'cancel_requested':
              case 'cancel_pending':
                turn.cancelPending = true;
                cancelQueued = true;
                commandStatus = RemoteCliCommandStatus.cancelPending;
              case 'cancel_failed':
                turn.cancelPending = false;
                cancelQueued = false;
                if (commandStatus == RemoteCliCommandStatus.cancelPending) {
                  commandStatus = RemoteCliCommandStatus.none;
                }
            }
          }
        }
        break;
      case 'answer_part':
      case 'approval_request':
      case 'artifact':
        if (turn != null && turn.active) {
          turn.status = RemoteCliTurnStatus.running;
          if (_activeTurn == null || identical(_activeTurn, turn)) {
            _activeTurn = turn;
          }
        }
        break;
    }
  }

  void _recordAnswer(RemoteCliEvent event) {
    if (event.kind != 'answer_part') return;
    final turn =
        _turnsByEventId[event.id] ?? _turnForEvent(event, _remoteTurnId(event));
    turn?.appendAnswer(event.payload['text']);
  }

  void _clearTurns() {
    turns.clear();
    _turnsByRemoteId.clear();
    _turnsByEventId.clear();
    _expiredCommandIds.clear();
    _legacyTurnSequence = 0;
    _activeTurn = null;
  }

  static String? _remoteTurnId(RemoteCliEvent event) {
    final id = event.payload['turn_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  RemoteCliTurn? _turnForEvent(RemoteCliEvent event, String? remoteTurnId) {
    if (event.kind == 'command_expired' || event.kind == 'command') {
      final commandId = event.payload['command_id'];
      if (commandId is! num) return null;
      return turns
          .where((turn) => turn.commandId == commandId.toInt())
          .firstOrNull;
    }
    if (event.kind == 'progress' &&
        event.payload['status'] == 'command_received' &&
        remoteTurnId == null) {
      final commandId = event.payload['command_id'];
      if (commandId is! num) return null;
      return turns
          .where((turn) => turn.commandId == commandId.toInt())
          .firstOrNull;
    }
    if (remoteTurnId != null) {
      final known = _turnsByRemoteId[remoteTurnId];
      if (known != null) return known;
      final active = _activeTurn;
      if (active != null && active.active && active.remoteTurnId == null) {
        active.remoteTurnId = remoteTurnId;
        _turnsByRemoteId[remoteTurnId] = active;
        return active;
      }
      return _turnsByRemoteId.putIfAbsent(remoteTurnId, () {
        final turn = RemoteCliTurn(
          key: 'remote-$remoteTurnId',
          remoteTurnId: remoteTurnId,
          prompt: '',
        );
        turns.add(turn);
        return turn;
      });
    }
    if (event.kind == 'turn_end' || event.kind == 'approval_answer') {
      return _activeTurn;
    }
    if (event.kind == 'progress' &&
        !event.payload.containsKey('event') &&
        !event.payload.containsKey('stage') &&
        !event.payload.containsKey('step') &&
        !event.payload.containsKey('notice') &&
        !event.payload.containsKey('message')) {
      return null;
    }
    final current = _activeTurn;
    if (current != null) return current;
    final turn = RemoteCliTurn(
      key: 'implicit-${++_legacyTurnSequence}',
      prompt: '',
    );
    turns.add(turn);
    _activeTurn = turn;
    return turn;
  }

  Future<bool> sendPrompt(String prompt) async {
    final session = activeSession;
    final generation = _generation;
    final text = prompt.trim();
    if (session == null ||
        text.isEmpty ||
        sendingPrompt ||
        promptAwaitingStart ||
        turnRunning) {
      return false;
    }
    final sentAttachments = List<RemoteCliAttachment>.of(attachments);
    final turn = RemoteCliTurn(
      key: 'local-${++_legacyTurnSequence}',
      prompt: text,
      status: session.online
          ? RemoteCliTurnStatus.awaitingResponse
          : RemoteCliTurnStatus.queued,
    );
    turns.add(turn);
    _activeTurn = turn;
    sendingPrompt = true;
    failure = null;
    commandStatus = RemoteCliCommandStatus.none;
    _notify();
    try {
      final commandId = await gateway.sendPrompt(
        session.id,
        text,
        fileIds: [for (final file in sentAttachments) file.fileId],
      );
      if (!isCurrentSession(session.id, generation)) return false;
      turn.commandId = commandId;
      if (commandId != null && _expiredCommandIds.remove(commandId)) {
        turn.status = RemoteCliTurnStatus.failed;
        if (identical(_activeTurn, turn)) _activeTurn = null;
        commandStatus = RemoteCliCommandStatus.commandExpired;
      }
      attachments.removeWhere(sentAttachments.contains);
      if (turn.active &&
          commandStatus != RemoteCliCommandStatus.commandExpired) {
        commandStatus = session.online
            ? RemoteCliCommandStatus.promptSent
            : RemoteCliCommandStatus.promptQueuedOffline;
      }
      _expiredCommandIds.clear();
      return true;
    } catch (error) {
      if (!isCurrentSession(session.id, generation)) return false;
      turn.status = RemoteCliTurnStatus.failed;
      if (identical(_activeTurn, turn)) _activeTurn = null;
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
    final turn = _activeTurn;
    if (session == null || turn == null || !turn.active || turn.cancelPending) {
      return;
    }
    final generation = _generation;
    final activeKey = turn.key;
    failure = null;
    turn.cancelPending = true;
    cancelQueued = true;
    commandStatus = RemoteCliCommandStatus.cancelPending;
    _notify();
    try {
      await gateway.cancel(session.id, turnId: turnId ?? turn.remoteTurnId);
      if (!isCurrentSession(session.id, generation) ||
          _activeTurn?.key != activeKey) {
        return;
      }
      cancelQueued = true;
      commandStatus = RemoteCliCommandStatus.cancelPending;
    } catch (error) {
      if (!isCurrentSession(session.id, generation) ||
          _activeTurn?.key != activeKey) {
        return;
      }
      turn.cancelPending = false;
      cancelQueued = false;
      failure = error;
    }
    _notify();
  }

  Future<DownloadedFileContent?> artifactImage(
    String fileId, {
    required String sessionId,
    required int epoch,
  }) async {
    if (!isCurrentSession(sessionId, epoch)) return null;
    final content = await gateway.artifactImage(fileId);
    return isCurrentSession(sessionId, epoch) ? content : null;
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
