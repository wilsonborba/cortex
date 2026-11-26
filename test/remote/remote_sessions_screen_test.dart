import 'dart:async';
import 'dart:convert';

import 'package:cortex/domain/models/remote_cli.dart';
import 'package:cortex/domain/models/api.dart';
import 'package:cortex/domain/services/remote_cli_controller.dart';
import 'package:cortex/domain/services/remote_cli_gateway.dart';
import 'package:cortex/core/utils/file_picker.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/remote/remote_sessions_screen.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _validTestPng = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
);

class _Gateway implements RemoteCliGateway {
  final incoming = StreamController<RemoteCliEvent>.broadcast();
  final uploads = <({String name, List<int> bytes, String contentType})>[];
  final prompts = <({String sessionId, String prompt, List<String> fileIds})>[];
  final approvals = <({String id, bool approved})>[];
  Completer<void>? promptGate;
  Object? sessionsError;
  int sessionCalls = 0;
  int cancelCount = 0;
  final cancelledTurnIds = <String?>[];
  final artifactRequests = <String>[];
  final artifactErrors = <String, Object>{};

  @override
  Future<List<RemoteCliSession>> sessions() async {
    sessionCalls++;
    if (sessionsError != null && sessionCalls > 1) throw sessionsError!;
    return [
      _session('linux-session', 'Linux laptop', online: true),
      _session('offline-session', 'Office workstation', online: false),
    ];
  }

  @override
  Stream<RemoteCliEvent> events(String sessionId, {required int after}) =>
      incoming.stream;

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
    approvals.add((id: approvalId, approved: approved));
  }

  @override
  Future<void> cancel(String sessionId, {String? turnId}) async {
    cancelCount++;
    cancelledTurnIds.add(turnId);
  }

  @override
  Future<String> uploadImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  }) async {
    uploads.add((name: name, bytes: bytes, contentType: contentType));
    return 'selected-file-1';
  }

  @override
  Future<DownloadedFileContent> artifactImage(String fileId) async {
    artifactRequests.add(fileId);
    final error = artifactErrors[fileId];
    if (error != null) throw error;
    return DownloadedFileContent(
      contentType: 'image/png',
      bytes: _validTestPng,
    );
  }

  Future<void> dispose() => incoming.close();
}

RemoteCliSession _session(String id, String name, {required bool online}) =>
    RemoteCliSession(
      id: id,
      deviceName: name,
      platform: 'linux',
      lastSeen: DateTime.utc(2026, 11, 25, 12),
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

Future<void> _pump(
  WidgetTester tester,
  RemoteCliController controller, {
  required Size size,
  RemoteImagePicker? picker,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: cortexTheme(Brightness.dark),
      home: Scaffold(
        body: RemoteSessionsScreen(controller: controller, imagePicker: picker),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'phone flow streams progress, approval, cancel, and explicit image',
    (tester) async {
      final gateway = _Gateway();
      final controller = RemoteCliController(
        gateway: gateway,
        reconnectDelay: const Duration(hours: 1),
      );
      addTearDown(gateway.dispose);
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        size: const Size(390, 844),
        picker: () async => [
          (name: 'photo.jpg', contentType: 'image/jpeg', bytes: [1, 2, 3]),
        ],
      );

      expect(find.text('Linux laptop'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Office workstation'), findsOneWidget);
      await tester.tap(find.byKey(const Key('remote-session-linux-session')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 10));
      expect(controller.activeSession?.id, 'linux-session');

      gateway.incoming.add(
        _event(1, 'progress', {'message': 'Reading the request'}),
      );
      await tester.pump();
      await tester.pump();
      expect(controller.events, hasLength(1));
      expect(find.byKey(const Key('remote-event-list')), findsOneWidget);
      expect(find.text('Reading the request'), findsOneWidget);
      expect(find.text('Cancel turn'), findsOneWidget);

      gateway.incoming.add(
        _event(2, 'approval_request', {
          'approval_id': 'approval-1',
          'description': 'Run this command?',
        }),
      );
      await tester.pump();
      expect(find.text('Run this command?'), findsOneWidget);
      await tester.tap(find.text('Deny'));
      await tester.pump();
      expect(gateway.approvals, [(id: 'approval-1', approved: false)]);
      gateway.incoming.add(_event(3, 'turn_end', {'status': 'complete'}));
      await tester.pump();

      await tester.tap(find.byTooltip('Attach image'));
      await tester.pumpAndSettle();
      expect(gateway.uploads.single.name, 'photo.jpg');
      expect(find.text('photo.jpg'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('remote-prompt')),
        'Summarize this image',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('remote-send')));
      await tester.pump();
      await tester.pump();
      expect(gateway.prompts.single.prompt, 'Summarize this image');
      expect(gateway.prompts.single.fileIds, ['selected-file-1']);

      gateway.incoming.add(
        _event(4, 'artifact', {
          'turn_id': 'turn-photo',
          'file_id': 'artifact-1',
          'name': 'result.png',
          'content_type': 'image/png',
        }),
      );
      await tester.pump();
      expect(gateway.artifactRequests, isEmpty);
      await tester.tap(
        find.byKey(const Key('remote-artifact-preview-artifact-1')),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(gateway.artifactRequests, ['artifact-1']);
      final artifactImage = find.byKey(
        const Key('remote-artifact-image-artifact-1'),
      );
      expect(artifactImage, findsOneWidget);
      final decodedRawImage = find.descendant(
        of: artifactImage,
        matching: find.byType(RawImage),
      );
      expect(decodedRawImage, findsOneWidget);
      expect(tester.widget<RawImage>(decodedRawImage).image, isNotNull);
      await tester.tap(find.byTooltip('View image larger'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel turn'));
      await tester.pump();
      await tester.pump();
      expect(gateway.cancelCount, 1);
      expect(gateway.cancelledTurnIds, ['turn-photo']);
      expect(
        find.text('Cancellation requested; waiting for CLI status.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('artifact preview distinguishes expiry from request failure', (
    tester,
  ) async {
    final gateway = _Gateway()
      ..artifactErrors['expired-file'] = const ApiError(404, null, 'expired')
      ..artifactErrors['offline-file'] = const ApiError(503, null, 'offline');
    final controller = RemoteCliController(
      gateway: gateway,
      reconnectDelay: const Duration(hours: 1),
    );
    addTearDown(gateway.dispose);
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('remote-session-linux-session')));
    await tester.pumpAndSettle();

    gateway.incoming.add(
      _event(1, 'progress', {
        'turn_id': 'turn-1',
        'message': 'Preparing the image',
      }),
    );
    gateway.incoming.add(
      _event(2, 'turn_end', {'turn_id': 'turn-1', 'status': 'complete'}),
    );
    gateway.incoming.add(
      _event(3, 'artifact', {
        'turn_id': 'turn-1',
        'file_id': 'expired-file',
        'name': 'expired.png',
      }),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('remote-artifact-preview-expired-file')),
    );
    await tester.tap(
      find.byKey(const Key('remote-artifact-preview-expired-file')),
    );
    await tester.pumpAndSettle();
    expect(find.text('This file is no longer available.'), findsOneWidget);

    gateway.incoming.add(
      _event(4, 'artifact', {
        'turn_id': 'turn-1',
        'file_id': 'offline-file',
        'name': 'offline.png',
      }),
    );
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('remote-artifact-preview-offline-file')),
    );
    await tester.tap(
      find.byKey(const Key('remote-artifact-preview-offline-file')),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('The request failed. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(gateway.artifactRequests, ['expired-file', 'offline-file']);
  });

  testWidgets(
    'phone composer remains visible with answer, approval, error, and cancel',
    (tester) async {
      final gateway = _Gateway()
        ..sessionsError = const RemoteCliFailure(503, 'fixture failure');
      final controller = RemoteCliController(
        gateway: gateway,
        reconnectDelay: const Duration(hours: 1),
      );
      addTearDown(gateway.dispose);
      addTearDown(controller.dispose);
      await _pump(tester, controller, size: const Size(390, 844));
      await tester.tap(find.byKey(const Key('remote-session-linux-session')));
      await tester.pumpAndSettle();
      gateway.incoming.add(
        _event(1, 'progress', {'turn_id': 'turn-1', 'message': 'Working'}),
      );
      gateway.incoming.add(
        _event(2, 'answer_part', {
          'turn_id': 'turn-1',
          'text': 'Reviewing files',
        }),
      );
      gateway.incoming.add(
        _event(3, 'approval_request', {
          'turn_id': 'turn-1',
          'approval_id': 'approval-1',
          'action': 'Run this command?',
        }),
      );
      await tester.pump();
      await tester.pump();
      controller.commandStatus = RemoteCliCommandStatus.commandExpired;
      controller.attachments.add(
        const RemoteCliAttachment(name: 'photo.jpg', fileId: 'file-1'),
      );
      await controller.refreshSessions();
      await tester.pump();

      final prompt = find.byKey(const Key('remote-prompt'));
      expect(prompt, findsOneWidget);
      expect(find.text('photo.jpg'), findsOneWidget);
      expect(find.text('Reviewing files'), findsOneWidget);
      expect(find.text('Run this command?'), findsOneWidget);
      expect(find.text('Cancel turn'), findsOneWidget);
      expect(
        find.text('The command expired before the CLI received it.'),
        findsOneWidget,
      );
      final promptRect = tester.getRect(prompt);
      expect(promptRect.top, greaterThanOrEqualTo(0));
      expect(promptRect.bottom, lessThanOrEqualTo(844));
    },
  );

  testWidgets('tablet keeps the session list beside the selected session', (
    tester,
  ) async {
    final gateway = _Gateway();
    final controller = RemoteCliController(
      gateway: gateway,
      reconnectDelay: const Duration(hours: 1),
    );
    addTearDown(gateway.dispose);
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(1024, 768));
    await tester.tap(find.byKey(const Key('remote-session-offline-session')));
    await tester.pumpAndSettle();

    expect(find.text('Office workstation'), findsWidgets);
    expect(find.text('Offline'), findsWidgets);
    expect(find.byKey(const Key('remote-prompt')), findsOneWidget);
    expect(
      find.byKey(const Key('remote-session-linux-session')),
      findsOneWidget,
    );
  });

  testWidgets('desktop detail asks for a session when the list is populated', (
    tester,
  ) async {
    final gateway = _Gateway();
    final controller = RemoteCliController(gateway: gateway);
    addTearDown(gateway.dispose);
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(1024, 768));

    expect(find.text('Linux laptop'), findsOneWidget);
    expect(find.text('Select a CLI session'), findsOneWidget);
  });

  testWidgets(
    'a completed picker cannot upload into a newly selected session',
    (tester) async {
      final gateway = _Gateway();
      final controller = RemoteCliController(gateway: gateway);
      final selected = Completer<List<PickedFile>>();
      addTearDown(gateway.dispose);
      addTearDown(controller.dispose);
      await _pump(
        tester,
        controller,
        size: const Size(390, 844),
        picker: () => selected.future,
      );
      await tester.tap(find.byKey(const Key('remote-session-linux-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Attach image'));
      await tester.pump();

      await controller.openSession(
        _session('other-session', 'Other device', online: true),
      );
      await tester.pump();
      selected.complete([
        (name: 'private.jpg', contentType: 'image/jpeg', bytes: [1]),
      ]);
      await tester.pump();
      await tester.pump();

      expect(controller.activeSession?.id, 'other-session');
      expect(gateway.uploads, isEmpty);
    },
  );

  testWidgets('old prompt completion preserves the new session draft', (
    tester,
  ) async {
    final gateway = _Gateway()..promptGate = Completer<void>();
    final controller = RemoteCliController(
      gateway: gateway,
      reconnectDelay: const Duration(hours: 1),
    );
    addTearDown(gateway.dispose);
    addTearDown(controller.dispose);
    await _pump(tester, controller, size: const Size(390, 844));
    await tester.tap(find.byKey(const Key('remote-session-linux-session')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('remote-prompt')), 'old draft');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('remote-send')));
    await tester.tap(find.byKey(const Key('remote-send')));
    await tester.pump();
    expect(gateway.prompts.single.prompt, 'old draft');
    expect(controller.sendingPrompt, isTrue);

    await controller.openSession(
      _session('other-session', 'Other device', online: true),
    );
    await tester.pump();
    await tester.enterText(find.byKey(const Key('remote-prompt')), 'new draft');
    gateway.promptGate!.complete();
    await tester.pump();

    expect(controller.activeSession?.id, 'other-session');
    expect(find.byKey(const Key('remote-prompt')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('remote-prompt')))
          .controller!
          .text,
      'new draft',
    );
  });
}
