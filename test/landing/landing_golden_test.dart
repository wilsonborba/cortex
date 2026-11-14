import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/preferences.dart';
import 'package:cortex/presentation/frontend/screens/landing/landing_page.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;

/// Landing page with the 11 bundled images (#70): light and dark, 390 and
/// 1300 px, the whole page height.
void main() {
  setUpAll(loadFonts);
  test('every landing image is a bundled asset path, no network URL', () {
    for (final path in [
      LandingImages.backdrop,
      LandingImages.badge,
      LandingImages.previewFrame,
      LandingImages.cardSurface,
      LandingImages.mobile,
      LandingImages.play,
      LandingImages.ctaTexture,
      LandingImages.workflows,
      LandingImages.ideation,
      LandingImages.multimodal,
      LandingImages.performance,
    ]) {
      expect(path, startsWith('assets/images/'));
    }
  });
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      testWidgets('landing ${brightness.name} $width', (tester) async {
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
              theme: cortexTheme(brightness),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LandingPage(onSignIn: () {}),
            ),
          ),
        );
        // Asset images decode outside the fake clock.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('hero-badge')), findsOneWidget);
        expect(find.byKey(const Key('hero-visual')), findsOneWidget);
        expect(find.byKey(const Key('landing-final-action')), findsOneWidget);
        final scroll = tester.state<ScrollableState>(
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
        );
        tester.view.physicalSize = Size(
          width,
          1000 + scroll.position.maxScrollExtent.ceilToDouble(),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile(
            '../design/goldens/landing_${brightness.name}_${width.toInt()}.png',
          ),
        );
      });
    }
  }
}
