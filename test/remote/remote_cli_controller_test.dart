import 'dart:async';

import 'package:cortex/domain/models/remote_cli.dart';
import 'package:cortex/domain/models/api.dart';
import 'package:cortex/domain/services/remote_cli_controller.dart';
import 'package:cortex/domain/services/remote_cli_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements RemoteCliGateway {
  bool streamCancelled = false;
  Completer<void>? cancelGate;
  Completer<void>? cancelRequestGate;
  Completer<void>? promptGate;
  Future<List<RemoteCliSession>>? pendingSessions;
  late final stream = StreamController<RemoteCliEvent>.broadcast(
    onCancel: () async {
      streamCancelled = true;
      await cancelGate?.future;
    },
  );
  final cursors = <int>[];
  final scriptedStreams = <Stream<RemoteCliEvent>>[];
  final prompts = <({String sessionId, String prompt, List<String> fileIds})>[];
  final approvals = <({String approvalId, bool approved})>[];
  final cancelled = <String>[];
  final cancelledTurnIds = <String?>[];
  int uploads = 0;

  @override
  Future<List<RemoteCliSession>> sessions() async =>
      await pendingSessions ?? [_session()];

  @override
  Stream<RemoteCliEvent> events(String sessionId, {required int after}) {
    cursors.add(after);
    if (scriptedStreams.isNotEmpty) return scriptedStreams.removeAt(0);
    return stream.stream;
  }

  @override
  Future<int?> sendPrompt(
    String sessionId,
    String prompt, {
    List<String> fileIds = const [],
  }) async {
    prompts.add((sessionId: sessionId, prompt: prompt, fileIds: [...fileIds]));
    await promptGate?.future;
    return prompts.length;
  }

  @override
  Future<void> answerApproval(
    String sessionId,
    String approvalId, {
    required bool approved,
  }) async {
    approvals.add((approvalId: approvalId, approved: approved));
  }

  @override
  Future<void> cancel(String sessionId, {String? turnId}) async {
    cancelled.add(sessionId);
    cancelledTurnIds.add(turnId);
    await cancelRequestGate?.future;
  }

  @override
  Future<String> uploadImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  }) async {
    uploads++;
    return 'file-$uploads';
  }

  @override
  Future<DownloadedFileContent> artifactImage(String fileId) async =>
      const DownloadedFileContent(contentType: 'image/png', bytes: [1, 2]);

  Future<void> dispose() => stream.close();
}

RemoteCliSession _session({bool online = true, String id = 'session-1'}) =>
    RemoteCliSession(
      id: id,
      deviceName: 'Laptop',
      platform: 'linux',
      lastSeen: DateTime.fromMillisecondsSinceEpoch(1000),
      online: online,
    );

RemoteCliEvent _event(
  int id,
  String kind, [
  Map<String, dynamic> payload = const {},
]) => RemoteCliEvent(
  id: id,
  kind: kind,
  payload: payload,
  createdAt: DateTime.fromMillisecondsSinceEpoch(id * 1000),
);

void main() {
  test(
    'reconnects from last cursor and suppresses replayed event ids',
    () async {
      final gateway = _Gateway();
      gateway.scriptedStreams.add(
        Stream<RemoteCliEvent>.multi((sink) {
          sink.add(_event(4, 'progress'));
          sink.addError(const FormatException('invalid next durable event'));
          sink.close();
        }),
      );
      gateway.scriptedStreams.add(
        Stream.fromIterable([
          _event(4, 'progress', {'text': 'duplicate replay'}),
          _event(5, 'progress', {'text': 'continued'}),
        ]),
      );
      final controller = RemoteCliController(
        gateway: gateway,
        reconnectDelay: const Duration(milliseconds: 1),
      );
      await controller.openSession(_session());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.events.map((event) => event.id), [4, 5]);
      expect(gateway.cursors.take(2), [0, 4]);
      expect(controller.lastEventId, 5);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test(
    'reconnect replay keeps separate turns and late events stay terminal',
    () async {
      final gateway = _Gateway();
      gateway.scriptedStreams.add(
        Stream<RemoteCliEvent>.multi((sink) {
          sink.add(
            _event(1, 'answer_part', {'turn_id': 'turn-1', 'text': 'first'}),
          );
          sink.addError(const FormatException('reconnect'));
          sink.close();
        }),
      );
      gateway.scriptedStreams.add(
        Stream.fromIterable([
          _event(1, 'answer_part', {'turn_id': 'turn-1', 'text': 'duplicate'}),
          _event(2, 'answer_part', {'turn_id': 'turn-1', 'text': ' answer'}),
          _event(3, 'turn_end', {'turn_id': 'turn-1', 'status': 'done'}),
          _event(4, 'approval_answer', {
            'turn_id': 'turn-1',
            'approval_id': 'a',
          }),
          _event(5, 'artifact', {'turn_id': 'turn-1', 'name': 'old.txt'}),
          _event(6, 'progress', {'turn_id': 'turn-2', 'message': 'next'}),
          _event(7, 'answer_part', {'turn_id': 'turn-2', 'text': 'second'}),
        ]),
      );
      final controller = RemoteCliController(
        gateway: gateway,
        reconnectDelay: const Duration(milliseconds: 1),
      );
      await controller.openSession(_session());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(controller.answerText, 'second');
      expect(controller.turns.map((turn) => turn.answer), [
        'first answer',
        'second',
      ]);
      expect(controller.turnRunning, isTrue);
      gateway.stream.add(
        _event(8, 'turn_end', {'turn_id': 'turn-2', 'status': 'done'}),
      );
      await Future<void>.delayed(Duration.zero);
      gateway.stream.add(
        _event(9, 'approval_answer', {'turn_id': 'turn-2', 'approval_id': 'b'}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.turnRunning, isFalse);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test('closing the selected session cancels its event stream', () async {
    final gateway = _Gateway();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    await Future<void>.delayed(Duration.zero);

    await controller.closeSession();

    expect(gateway.streamCancelled, isTrue);
    controller.dispose();
    await gateway.dispose();
  });

  test(
    'late session refresh cannot restore cleared private device data',
    () async {
      final gateway = _Gateway();
      final pending = Completer<List<RemoteCliSession>>();
      gateway.pendingSessions = pending.future;
      final controller = RemoteCliController(gateway: gateway);
      final refresh = controller.refreshSessions();

      await controller.closeSession(clearSessions: true);
      pending.complete([_session()]);
      await refresh;

      expect(controller.sessions, isEmpty);
      expect(controller.loadingSessions, isFalse);
      controller.dispose();
      await gateway.dispose();
    },
  );

  test('old stream cancellation cannot clear a newly opened session', () async {
    final gateway = _Gateway()..cancelGate = Completer<void>();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    await Future<void>.delayed(Duration.zero);
    final closing = controller.closeSession();
    expect(controller.activeSession, isNull);

    await controller.openSession(_session(id: 'session-2'));
    gateway.cancelGate!.complete();
    await closing;

    expect(controller.activeSession?.id, 'session-2');
    controller.dispose();
    await gateway.dispose();
  });

  test(
    'uploads only selected image and sends its file id with prompt',
    () async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await controller.attachImage(
        name: 'phone.jpg',
        bytes: [1, 2, 3],
        contentType: 'image/jpeg',
      );
      await controller.sendPrompt('Describe this');

      expect(gateway.uploads, 1);
      expect(gateway.prompts.single.fileIds, ['file-1']);
      expect(controller.attachments, isEmpty);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test(
    'prompt is single-flight and removes only the submitted attachments',
    () async {
      final gateway = _Gateway()..promptGate = Completer<void>();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await controller.attachImage(
        name: 'before.jpg',
        bytes: [1],
        contentType: 'image/jpeg',
      );
      final first = controller.sendPrompt('one');
      expect(controller.sendingPrompt, isTrue);
      expect(await controller.sendPrompt('duplicate'), isFalse);

      await controller.attachImage(
        name: 'during.jpg',
        bytes: [2],
        contentType: 'image/jpeg',
      );
      gateway.promptGate!.complete();
      expect(await first, isTrue);
      expect(gateway.prompts, hasLength(1));
      expect(gateway.prompts.single.fileIds, ['file-1']);
      expect(controller.attachments.map((file) => file.name), ['during.jpg']);
      expect(controller.sendingPrompt, isFalse);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test('late prompt completion cannot update a newly opened session', () async {
    final gateway = _Gateway()..promptGate = Completer<void>();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    final first = controller.sendPrompt('old prompt');
    await controller.openSession(_session(id: 'session-2'));
    gateway.promptGate!.complete();

    expect(await first, isFalse);
    expect(controller.activeSession?.id, 'session-2');
    expect(controller.commandStatus, RemoteCliCommandStatus.none);
    expect(controller.sendingPrompt, isFalse);

    await controller.closeSession();
    controller.dispose();
    await gateway.dispose();
  });

  test(
    'a terminal cancel remains authoritative over a late command expiry',
    () async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      expect(await controller.sendPrompt('cancel this turn'), isTrue);
      await controller.cancel();
      expect(controller.cancelQueued, isTrue);
      expect(controller.commandStatus, RemoteCliCommandStatus.cancelPending);

      gateway.stream.add(_event(1, 'turn_end', {'status': 'cancelled'}));
      await Future<void>.delayed(Duration.zero);
      expect(controller.cancelQueued, isFalse);
      expect(controller.commandStatus, RemoteCliCommandStatus.cancelled);

      gateway.stream.add(
        _event(2, 'command_expired', {
          'command_id': 1,
          'status': 'not_delivered',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.commandStatus, RemoteCliCommandStatus.cancelled);
      expect(controller.turns.single.status, RemoteCliTurnStatus.cancelled);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test(
    'CLI9 payloads without turn ids stay in separate terminal turns',
    () async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await Future<void>.delayed(Duration.zero);

      gateway.stream.add(
        _event(1, 'progress', {
          'event': 'stage',
          'message': 'Reading files',
          'stage': 'gather',
          'status': 'running',
        }),
      );
      gateway.stream.add(_event(2, 'answer_part', {'text': 'first answer'}));
      await Future<void>.delayed(Duration.zero);
      gateway.stream.add(
        _event(3, 'turn_end', {
          'status': 'complete',
          'session_id': 'chat-1',
          'output_id': 'output-1',
          'total_ms': 15,
        }),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.turns, hasLength(1));
      expect(controller.turns.single.prompt, isEmpty);
      expect(controller.turns.single.answer, 'first answer');
      expect(controller.turns.single.status, RemoteCliTurnStatus.complete);
      expect(controller.turnRunning, isFalse);

      expect(await controller.sendPrompt('second prompt'), isTrue);
      expect(controller.promptAwaitingStart, isTrue);
      expect(await controller.sendPrompt('must not overlap'), isFalse);
      gateway.stream.add(_event(4, 'answer_part', {'text': 'second answer'}));
      gateway.stream.add(
        _event(5, 'turn_end', {'status': 'error', 'error_number': 82}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.turns, hasLength(2));
      expect(controller.turns.last.prompt, 'second prompt');
      expect(controller.turns.last.answer, 'second answer');
      expect(controller.turns.last.status, RemoteCliTurnStatus.failed);
      expect(controller.answerText, 'second answer');
      expect(controller.commandStatus, RemoteCliCommandStatus.turnFailed);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test(
    'accepted turn ids bind progress, answer, terminal, and cancel',
    () async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await Future<void>.delayed(Duration.zero);

      expect(await controller.sendPrompt('inspect files'), isTrue);
      expect(controller.turns.single.commandId, 1);
      gateway.stream.add(
        _event(1, 'progress', {'status': 'command_received', 'command_id': 1}),
      );
      gateway.stream.add(
        _event(2, 'progress', {
          'turn_id': 'turn-1',
          'event': 'stage',
          'stage': 'gather',
          'status': 'running',
          'message': 'Reading files',
        }),
      );
      gateway.stream.add(
        _event(3, 'answer_part', {'turn_id': 'turn-1', 'text': 'First result'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.turns, hasLength(1));
      expect(controller.turns.single.remoteTurnId, 'turn-1');
      expect(controller.turns.single.answer, 'First result');
      await controller.cancel();
      expect(gateway.cancelledTurnIds, ['turn-1']);
      expect(controller.turns.single.cancelPending, isTrue);
      gateway.stream.add(
        _event(4, 'progress', {
          'turn_id': 'turn-1',
          'status': 'cancel_failed',
          'command_id': 22,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.turns.single.cancelPending, isFalse);
      expect(controller.cancelQueued, isFalse);
      expect(controller.commandStatus, RemoteCliCommandStatus.none);

      gateway.stream.add(
        _event(5, 'progress', {
          'turn_id': 'turn-1',
          'status': 'cancelled',
          'command_id': 22,
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.turns.single.status, RemoteCliTurnStatus.running);

      gateway.stream.add(
        _event(6, 'turn_end', {'turn_id': 'turn-1', 'status': 'complete'}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.turns.single.status, RemoteCliTurnStatus.complete);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test('command expiry is correlated by the exact prompt command id', () async {
    final gateway = _Gateway();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    await Future<void>.delayed(Duration.zero);
    expect(await controller.sendPrompt('keep working'), isTrue);

    gateway.stream.add(
      _event(1, 'command_expired', {
        'command_id': 99,
        'status': 'not_delivered',
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.turns.single.status,
      RemoteCliTurnStatus.awaitingResponse,
    );
    expect(controller.commandStatus, RemoteCliCommandStatus.promptSent);

    gateway.stream.add(
      _event(2, 'command_expired', {
        'command_id': 1,
        'status': 'not_delivered',
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.turns.single.status, RemoteCliTurnStatus.failed);
    expect(controller.commandStatus, RemoteCliCommandStatus.commandExpired);
    expect(controller.promptAwaitingStart, isFalse);

    await controller.closeSession();
    controller.dispose();
    await gateway.dispose();
  });

  test(
    'early command expiry waits for the matching prompt response id',
    () async {
      final gateway = _Gateway()..promptGate = Completer<void>();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await Future<void>.delayed(Duration.zero);
      final send = controller.sendPrompt('queued prompt');
      expect(controller.sendingPrompt, isTrue);
      gateway.stream.add(
        _event(1, 'command_expired', {
          'command_id': 1,
          'status': 'not_delivered',
        }),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.commandStatus, RemoteCliCommandStatus.none);
      gateway.promptGate!.complete();

      expect(await send, isTrue);
      expect(controller.turns.single.commandId, 1);
      expect(controller.turns.single.status, RemoteCliTurnStatus.failed);
      expect(controller.commandStatus, RemoteCliCommandStatus.commandExpired);
      expect(controller.promptAwaitingStart, isFalse);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test(
    'a terminal event arriving before the prompt response stays terminal',
    () async {
      final gateway = _Gateway()..promptGate = Completer<void>();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await Future<void>.delayed(Duration.zero);
      final send = controller.sendPrompt('fast command');
      gateway.stream.add(
        _event(1, 'turn_end', {'turn_id': 'fast-turn', 'status': 'complete'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.turns.single.status, RemoteCliTurnStatus.complete);
      gateway.promptGate!.complete();
      expect(await send, isTrue);
      expect(controller.turns.single.status, RemoteCliTurnStatus.complete);
      expect(controller.turnRunning, isFalse);
      expect(controller.commandStatus, RemoteCliCommandStatus.none);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

  test('late cancel response cannot change the next turn state', () async {
    final gateway = _Gateway()..cancelRequestGate = Completer<void>();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    await Future<void>.delayed(Duration.zero);
    expect(await controller.sendPrompt('first'), isTrue);
    final cancel = controller.cancel();
    gateway.stream.add(_event(1, 'turn_end', {'status': 'cancelled'}));
    await Future<void>.delayed(Duration.zero);
    expect(controller.turns.single.status, RemoteCliTurnStatus.cancelled);

    expect(await controller.sendPrompt('second'), isTrue);
    gateway.cancelRequestGate!.complete();
    await cancel;

    expect(controller.turnRunning, isTrue);
    expect(controller.cancelQueued, isFalse);
    expect(controller.commandStatus, RemoteCliCommandStatus.promptSent);
    expect(controller.turns.last.prompt, 'second');

    await controller.closeSession();
    controller.dispose();
    await gateway.dispose();
  });

  test('approval is sent once and disappears from pending requests', () async {
    final gateway = _Gateway();
    final controller = RemoteCliController(gateway: gateway);
    await controller.openSession(_session());
    gateway.stream.add(
      _event(1, 'approval_request', {'approval_id': 'approval-1'}),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.approvalRequests, hasLength(1));
    await controller.answerApproval('approval-1', approved: false);
    await controller.answerApproval('approval-1', approved: true);

    expect(gateway.approvals, hasLength(1));
    expect(gateway.approvals.single.approved, isFalse);
    expect(controller.approvalRequests, isEmpty);

    await controller.closeSession();
    controller.dispose();
    await gateway.dispose();
  });
}
