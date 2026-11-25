import 'dart:async';

import 'package:cortex/domain/models/remote_cli.dart';
import 'package:cortex/domain/services/remote_cli_controller.dart';
import 'package:cortex/domain/services/remote_cli_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements RemoteCliGateway {
  bool streamCancelled = false;
  Completer<void>? cancelGate;
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
  Future<void> sendPrompt(
    String sessionId,
    String prompt, {
    List<String> fileIds = const [],
  }) async {
    prompts.add((sessionId: sessionId, prompt: prompt, fileIds: [...fileIds]));
    await promptGate?.future;
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

      expect(controller.answerText, 'first answer\n\nsecond');
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
    'reports expired command and waits for truthful cancel status',
    () async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      await controller.openSession(_session());
      await controller.cancel(turnId: 'turn-1');
      expect(controller.cancelQueued, isTrue);
      expect(controller.commandStatus, RemoteCliCommandStatus.cancelPending);

      gateway.stream.add(_event(1, 'turn_end', {'status': 'cancelled'}));
      await Future<void>.delayed(Duration.zero);
      expect(controller.cancelQueued, isFalse);
      expect(controller.commandStatus, RemoteCliCommandStatus.cancelled);

      gateway.stream.add(_event(2, 'command_expired'));
      await Future<void>.delayed(Duration.zero);
      expect(controller.commandStatus, RemoteCliCommandStatus.commandExpired);

      await controller.closeSession();
      controller.dispose();
      await gateway.dispose();
    },
  );

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
