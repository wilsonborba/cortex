import 'dart:async';

import 'package:cortex/domain/models/remote_cli.dart';
import 'package:cortex/domain/services/remote_cli_controller.dart';
import 'package:cortex/domain/services/remote_cli_gateway.dart';
import 'package:cortex/core/utils/file_picker.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/remote/remote_sessions_screen.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Gateway implements RemoteCliGateway {
  final incoming = StreamController<RemoteCliEvent>.broadcast();
  final uploads = <({String name, List<int> bytes, String contentType})>[];
  final prompts = <({String sessionId, String prompt, List<String> fileIds})>[];
  final approvals = <({String id, bool approved})>[];
  Completer<void>? promptGate;
  int cancelCount = 0;

  @override
  Future<List<RemoteCliSession>> sessions() async => [
    _session('linux-session', 'Linux laptop', online: true),
    _session('offline-session', 'Office workstation', online: false),
  ];

  @override
  Stream<RemoteCliEvent> events(String sessionId, {required int after}) =>
      incoming.stream;

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
    approvals.add((id: approvalId, approved: approved));
  }

  @override
  Future<void> cancel(String sessionId, {String? turnId}) async {
    cancelCount++;
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

      await tester.tap(find.text('Cancel turn'));
      await tester.pump();
      await tester.pump();
      expect(gateway.cancelCount, 1);
      expect(
        find.text('Cancellation requested; waiting for CLI status.'),
        findsOneWidget,
      );
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
