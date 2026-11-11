import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('busy buttons preserve idle width', (tester) async {
    for (final width in [390.0, 1300.0]) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> show(bool busy) => tester.pumpWidget(
        MaterialApp(
          theme: cortexTheme(Brightness.dark),
          home: Scaffold(
            body: Center(
              child: AppButton.primary(
                label: 'Save example changes',
                busy: busy,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await show(false);
      final idle = tester.getSize(find.byType(FilledButton));
      await show(true);
      expect(tester.getSize(find.byType(FilledButton)), idle);
    }
  });
  testWidgets('select menu opens with Enter and Escape restores focus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: cortexTheme(Brightness.dark),
        home: Scaffold(
          body: AppSelect<String>(
            value: 'one',
            items: const [
              DropdownMenuItem(value: 'one', child: Text('First')),
              DropdownMenuItem(value: 'two', child: Text('Second')),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNWidgets(2));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsNothing);
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.focusNode!.hasFocus, isTrue);
  });
}
