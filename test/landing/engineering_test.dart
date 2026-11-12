import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/screens/landing/landing_page.dart';
import 'package:cortex/presentation/frontend/screens/landing/engineering_sources.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  test('public excerpts are bounded and contain no deployment addresses', () {
    expect(engineeringExcerpts.length, 4);
    for (final source in engineeringExcerpts) {
      expect(source.code.split('\n').length, lessThanOrEqualTo(25));
      expect(source.path.startsWith('src/'), isTrue);
      expect(
        RegExp(
          r'\b(?:\d{1,3}\.){3}\d{1,3}\b|MSI|Pong|192\.',
        ).hasMatch(source.code),
        isFalse,
      );
    }
  });
  for (final locale in [
    const Locale('en'),
    const Locale('pt', 'BR'),
    const Locale('th'),
  ]) {
    for (final brightness in Brightness.values) {
      for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
        testWidgets(
          'engineering ${locale.toLanguageTag()} ${brightness.name} $width',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final prefs = Preferences();
            addTearDown(prefs.dispose);
            await tester.pumpWidget(
              PreferencesScope(
                preferences: prefs,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: locale,
                  theme: cortexTheme(brightness),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: LandingPage(section: 'engineering', onSignIn: () {}),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final context = tester.element(
                  find.byKey(const Key('engineering-intro')),
                ),
                l = AppLocalizations.of(context);
            for (final key in [
              'engineering-intro',
              'engineering-context',
              'engineering-containers',
              'engineering-pipeline',
              'engineering-decisions',
            ]) {
              expect(find.byKey(Key(key)), findsOneWidget);
            }
            for (final text in [
              l.researchTitle,
              l.securityTitle,
              l.engResearchContext,
              l.engResearchPrompts,
              l.engResearchReasoning,
            ]) {
              expect(find.text(text), findsOneWidget);
            }
            final text = tester
                .widgetList<Text>(find.byType(Text))
                .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
                .join('\n');
            expect(
              RegExp(
                r'\b(?:\d{1,3}\.){3}\d{1,3}\b|\bMSI\b|\bPong\b|\bFSM\b|localhost|127\.0',
              ).hasMatch(text),
              isFalse,
            );
            expect(tester.takeException(), isNull);
            if (locale.languageCode == 'en' &&
                [390.0, 1300.0].contains(width)) {
              final scroll = tester.state<ScrollableState>(
                find
                    .byWidgetPredicate(
                      (w) =>
                          w is Scrollable &&
                          (w.axisDirection == AxisDirection.down ||
                              w.axisDirection == AxisDirection.up),
                    )
                    .first,
              );
              tester.view.physicalSize = Size(
                width,
                1000 + scroll.position.maxScrollExtent.ceilToDouble(),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await expectLater(
                find.byType(Scaffold),
                matchesGoldenFile(
                  '../design/goldens/engineering_${brightness.name}_${width.toInt()}.png',
                ),
              );
            }
          },
        );
      }
    }
  }
}
