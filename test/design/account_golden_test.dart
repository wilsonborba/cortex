import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../shell/account_settings_test.dart' as account;
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      for (final width in [390.0, 768.0, 800.0, 1024.0, 1300.0, 1440.0]) {
        testWidgets(
          'account ${locale.toLanguageTag()} ${mode.name} ${width.toInt()}',
          (tester) async {
            debugDisableShadows = false;
            try {
              final (_, prefs) = await account.show(
                tester,
                width,
                email:
                    'synthetic.reader.with.a.long.account.label@example.test',
              );
              prefs.theme = mode;
              prefs.locale = locale;
              await tester.pumpAndSettle();
              if (width < 600) {
                await tester.tap(find.byKey(const Key('drawer-button')));
                await tester.pumpAndSettle();
              }
              final suffix = locale.languageCode == 'en'
                  ? ''
                  : '_${locale.languageCode}';
              Future<void> shot(String name) => expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile(
                  'goldens/${name}_${mode.name}_${width.toInt()}$suffix.png',
                ),
              );
              await shot('account_shell');
              await tester.tap(find.byKey(const Key('account-button')));
              await tester.pumpAndSettle();
              await shot('account_menu');
              final l = AppLocalizations.of(
                tester.element(find.byKey(const Key('account-button'))),
              );
              await tester.tap(find.widgetWithText(MenuItemButton, l.settings));
              await tester.pumpAndSettle();
              expect(find.text(l.browserPreferenceNote), findsOneWidget);
              await shot('settings');
              expect(tester.takeException(), isNull);
            } finally {
              debugDisableShadows = true;
            }
          },
        );
      }
    }
  }
}
