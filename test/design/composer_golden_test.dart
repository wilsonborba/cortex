import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/domain/services/chat_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/screens/chat/composer.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../chat/chat_test.dart' as fixture;
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  for (final mode in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final scenario in [
        'empty',
        'text',
        'files',
        'running',
        'over_limit',
      ]) {
        testWidgets('$scenario composer ${mode.name} ${width.toInt()}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final fake = fixture.Api()
            ..maxTokens = scenario == 'over_limit' ? 10 : 5120
            ..personas = [
              {
                'persona_id': 'synthetic-bot',
                'name': 'Example assistant',
                'type': 'bot',
              },
            ];
          final api = CortexApi(
            baseUrl: 'https://api.test/apps/cortex/v1',
            client: fake.client,
          );
          final controller = ChatController(api: api);
          if (scenario == 'files') {
            controller.files.addAll([
              for (var i = 0; i < 3; i++)
                AttachedFile(
                  'example-$i.pdf',
                  1024,
                  'application/pdf',
                  List.filled(1024, 0),
                )..fileId = 'synthetic-$i',
            ]);
            controller.options
              ..memory = true
              ..web = WebChoice.fast;
          }
          final fixed = DateTime(2026, 11, 12, 12);
          if (scenario == 'running') {
            controller.exchanges.add(
              Exchange(
                text: 'Explain this synthetic example.',
                output: OutputView()
                  ..started = fixed
                  ..step = 'memory.search'
                  ..expectedMs = 30000,
              ),
            );
          }
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: cortexTheme(mode),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ChatScreen(
                  api: api,
                  controller: controller,
                  details: DetailsController(),
                  now: () => fixed,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          if (['text', 'files', 'over_limit'].contains(scenario)) {
            await tester.enterText(
              find.byKey(const Key('composer-text')),
              scenario == 'over_limit'
                  ? 'This synthetic message exceeds the test limit.'
                  : 'Write a short summary of this synthetic example.',
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
          }
          expect(find.byType(Composer), findsOneWidget);
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              'goldens/composer_${scenario}_${mode.name}_${width.toInt()}.png',
            ),
          );
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        });
      }
    }
  }
}
