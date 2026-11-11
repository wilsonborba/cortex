import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../shell/account_settings_test.dart' as account;
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final width in [390.0, 800.0, 1300.0]) {
      testWidgets('account ${mode.name} ${width.toInt()}', (tester) async {
        debugDisableShadows = false;
        try {
          final (_, prefs) = await account.show(
            tester,
            width,
            email: 'synthetic.reader@example.test',
          );
          prefs.theme = mode;
          await tester.pumpAndSettle();
          if (width < 600) {
            await tester.tap(find.byKey(const Key('drawer-button')));
            await tester.pumpAndSettle();
          }
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/account_shell_${mode.name}_${width.toInt()}.png',
            ),
          );
          await tester.tap(find.byKey(const Key('account-button')));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/account_menu_${mode.name}_${width.toInt()}.png',
            ),
          );
          await tester.tap(find.widgetWithText(MenuItemButton, 'Settings'));
          await tester.pumpAndSettle();
          expect(
            find.text('These choices are saved in this browser.'),
            findsOneWidget,
          );
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'goldens/settings_${mode.name}_${width.toInt()}.png',
            ),
          );
          expect(tester.takeException(), isNull);
        } finally {
          debugDisableShadows = true;
        }
      });
    }
  }
}
