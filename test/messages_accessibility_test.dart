import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/handlers/process_messages.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'package:cortex/presentation/frontend/screens/chat/step_text.dart';
import 'package:cortex/presentation/frontend/widgets/common/connection_banner.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'shell/router_test.dart' as shell;

void main() {
  test(
    'every API registry number has EN, PT and TH text and a map entry',
    () async {
      final snapshot =
          jsonDecode(
                File(
                  'test/fixtures/cortex_process_registry.json',
                ).readAsStringSync(),
              )
              as Map;
      final entries = snapshot['entries'] as List;
      final api = File('../cortex_api_dev/src/core/process_numbers.rs');
      if (api.existsSync()) {
        final numbers = RegExp(r'number: (\d+),')
            .allMatches(api.readAsStringSync())
            .map((m) => int.parse(m[1]!))
            .toSet();
        expect(
          entries.map((e) => e['number']).toSet(),
          numbers,
          reason: 'Refresh the copied registry when the API changes.',
        );
      }
      for (final code in ['en', 'pt', 'th']) {
        final arb =
            jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
                as Map;
        final l = await AppLocalizations.delegate.load(Locale(code));
        for (final entry in entries) {
          final number = entry['number'] as int;
          expect(arb['process$number'], isA<String>());
          expect((arb['process$number'] as String).trim(), isNotEmpty);
          expect(processMessage(l, number), arb['process$number']);
        }
        expect(processMessage(l, 9876), l.processUnknown(9876));
        expect(processMessage(l, null), l.processGeneric);
      }
    },
  );
  testWidgets(
    'output translates notices, errors and steps without backend text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final locale in [
        const Locale('en'),
        const Locale('pt', 'BR'),
        const Locale('th'),
      ]) {
        final l = await AppLocalizations.delegate.load(locale);
        final output = OutputView()
          ..step = 'thinking.step'
          ..stepParams = {'role': 'plan', 'model': 'fixture-model'}
          ..expectedMs = 40000;
        output.stages.add(StageState('think', 'started', 100));
        output.thinking.add(ThinkingPart('plan', 1, 'model output data'));
        output.notices.add((1026, 'RAW BACKEND NOTICE'));
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: cortexTheme(Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: OutputBlock(output: output, onStopThinking: () {}),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(l.process1026), findsOneWidget);
        expect(find.text('RAW BACKEND NOTICE'), findsNothing);
        expect(find.textContaining('fixture-model'), findsOneWidget);
        expect(find.textContaining(l.rolePlan), findsAtLeastNWidgets(1));
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await tester.tap(find.byKey(const Key('status-line')));
        await tester.pump();
        expect(find.textContaining(l.stageThink), findsWidgets);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale running output at 200 percent',
        );
        output
          ..status = 'failed'
          ..errorNumber = 9876
          ..errorMessage = 'RAW BACKEND ERROR';
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: OutputBlock(output: output)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l.processUnknown(9876)), findsOneWidget);
        expect(find.text('RAW BACKEND ERROR'), findsNothing);
      }
    },
  );
  testWidgets(
    'browser offline signal shows translated banner and then clears',
    (tester) async {
      final changes = StreamController<bool>.broadcast();
      for (final locale in [
        const Locale('en'),
        const Locale('pt', 'BR'),
        const Locale('th'),
      ]) {
        await tester.pumpWidget(const SizedBox());
        final l = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ConnectionBanner(
              initialOnline: false,
              changes: changes.stream,
              child: const Scaffold(body: Text('route content')),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(l.networkOffline), findsOneWidget);
        changes.add(true);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('network-offline')), findsNothing);
      }
      await tester.pumpWidget(const SizedBox());
      await changes.close();
    },
  );
  testWidgets('Escape closes details on expanded, medium and compact widths', (
    tester,
  ) async {
    shell.signedIn = true;
    for (final width in [1200.0, 800.0, 390.0]) {
      await tester.pumpWidget(const SizedBox());
      final (_, _, details) = await shell.pump(
        tester,
        '/v1/memory',
        size: Size(width, 844),
      );
      details.show(const Text('panel content'));
      await tester.pumpAndSettle();
      expect(find.text('panel content'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('panel content'), findsNothing);
      expect(details.value, isNull);
    }
  });
  testWidgets(
    'compact chat shows offline Retry and recovers at 200 percent in all locales',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final locale in [
        const Locale('en'),
        const Locale('pt', 'BR'),
        const Locale('th'),
      ]) {
        await tester.pumpWidget(const SizedBox());
        var disconnected = true;
        final l = await AppLocalizations.delegate.load(locale);
        final client = MockClient((request) async {
          Object data = [];
          if (request.url.path == '/models') {
            data = {
              'max_input_tokens': 5120,
              'estimate_rule': {'bytes_per_token': 3, 'copies': 2},
            };
          } else if (request.url.path == '/chats/saved') {
            if (disconnected) throw http.ClientException('transport detail');
            data = {
              'chat': {'title': 'Saved'},
              'inputs': [],
              'outputs': [],
            };
          }
          return http.Response(jsonEncode({'message': '', 'data': data}), 200);
        });
        final api = CortexApi(baseUrl: 'https://fixture.test', client: client);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: cortexTheme(Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: ChatScreen(
                key: UniqueKey(),
                api: api,
                details: DetailsController(),
                sessionId: 'saved',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(l.networkOffline), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale offline at 200 percent',
        );
        disconnected = false;
        await tester.ensureVisible(find.text(l.retry));
        await tester.tap(find.text(l.retry));
        await tester.pumpAndSettle();
        expect(find.text(l.networkOffline), findsNothing);
        expect(find.text(l.chatGreeting), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale chat at 200 percent',
        );
        for (final button in tester.widgetList<IconButton>(
          find.byType(IconButton),
        )) {
          expect(
            button.tooltip,
            isNotNull,
            reason: 'Every icon action needs a reader label.',
          );
        }
      }
    },
  );
  test(
    'all API steps translate and keep file names and URLs as data',
    () async {
      final source = File('../cortex_api_dev/src/domain/models/events.rs');
      final steps = source.existsSync()
          ? RegExp(
              r'#\[serde\(rename = "([^\"]+)"\)\]',
            ).allMatches(source.readAsStringSync()).map((m) => m[1]!).toList()
          : [
              'web.queries',
              'queue.wait',
              'model.load',
              'model.ready',
              'security.ok',
              'file.read.page',
              'file.ocr.page',
              'file.transcribe',
              'memory.search',
              'memory.found',
              'web.search',
              'web.page.read',
              'chunks.selected',
              'thinking.step',
              'thinking.stopped',
            ];
      for (final code in ['en', 'pt', 'th']) {
        final l = await AppLocalizations.delegate.load(Locale(code));
        for (final step in steps) {
          final text = stepText(
            l,
            step,
            {'file': 'report.pdf', 'url': 'https://fixture.test'},
            [2, 3],
          );
          expect(text, isNot(startsWith(step)));
          expect(text, contains('report.pdf'));
          expect(text, contains('https://fixture.test'));
          expect(text, contains('2 / 3'));
        }
        expect(stepText(l, 'future.step', {}, null), l.stepUnknown);
      }
    },
  );
}
