import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/domain/services/chat_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../chat/chat_test.dart' as fixture;
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  final fixed = DateTime(2026, 11, 12, 12);
  for (final mode in Brightness.values) {
    for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
      for (final scenario in [
        'empty',
        'running',
        'finished',
        'long',
        'failed',
        'thinking',
      ]) {
        testWidgets('$scenario transcript ${mode.name} ${width.toInt()}', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final fake = fixture.Api();
          final api = CortexApi(
            baseUrl: 'https://api.test/apps/cortex/v1',
            client: fake.client,
          );
          final controller = ChatController(api: api)
            ..chat = {'title': 'Synthetic transcript example'};
          if (scenario != 'empty') {
            final output =
                OutputView(
                    status: ['running', 'thinking'].contains(scenario)
                        ? 'running'
                        : scenario == 'failed'
                        ? 'failed'
                        : 'done',
                  )
                  ..started = fixed.subtract(const Duration(seconds: 2))
                  ..step = 'memory.search'
                  ..expectedMs = 30000;
            if (scenario == 'finished' || scenario == 'long') {
              output.answer.write(
                '## A clear example\n\nThis synthetic response includes a code sample and one reference.\n\n```rust\nlet example = "readable";\nprintln!("{example}");\n```\n\nCheck important facts before using the result.',
              );
              if (scenario == 'long') {
                output.answer.write(
                  '\n\n${List.generate(24, (i) => '### Example section ${i + 1}\n\nThis is synthetic long-form reading content. It keeps a clear reading column and allows selection.\n\n').join()}\n```text\n${List.filled(20, 'a long synthetic code token').join('_')}\n```\n',
                );
              }
              output.sources.add((
                'Example reference',
                'https://example.com/reference',
              ));
              output.memories.add(('synthetic-memory', 'Example note'));
              output.totalMs = 4200;
              output.inputTokens = 120;
              output.outputTokens = 80;
            } else if (scenario == 'thinking') {
              output.step = 'thinking.step';
              output.stepParams = {'role': 'plan', 'model': 'synthetic-model'};
              output.stages.add(StageState('think', 'started', 0));
              output.thinking.add(
                ThinkingPart(
                  'plan',
                  1,
                  'Synthetic thinking text, closed by default.',
                ),
              );
            } else {
              output.answer.write('Synthetic partial answer.');
            }
            if (scenario == 'failed') output.errorNumber = 1012;
            controller.exchanges.add(
              Exchange(
                text: 'Explain this synthetic example.',
                inputId: 'synthetic-input',
                createdAt: fixed,
                output: output,
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
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              'goldens/transcript_${scenario}_${mode.name}_${width.toInt()}.png',
            ),
          );
          await tester.pumpWidget(const SizedBox());
          controller.dispose();
        });
      }
    }
  }
}
