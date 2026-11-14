import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('${brightness.name}: neutral Material roles and selection', () {
      final theme = cortexTheme(brightness);
      final p = theme.extension<Palette>()!;
      expect(theme.colorScheme.primary, p.text);
      expect(theme.colorScheme.primary, isNot(p.brandBackground));
      expect(theme.colorScheme.onPrimary, p.background);
      expect(theme.textSelectionTheme.cursorColor, p.text);
      expect(
        theme.textSelectionTheme.selectionColor,
        p.text.withValues(alpha: .25),
      );
      expect(theme.textSelectionTheme.selectionHandleColor, p.text);
      const selected = {WidgetState.selected};
      expect(theme.switchTheme.trackColor!.resolve(selected), p.text);
      expect(theme.switchTheme.thumbColor!.resolve(selected), p.background);
      expect(
        theme.segmentedButtonTheme.style!.backgroundColor!.resolve(selected),
        p.text,
      );
      expect(
        theme.segmentedButtonTheme.style!.foregroundColor!.resolve(selected),
        p.background,
      );
      expect(theme.chipTheme.selectedColor, p.text);
      expect(theme.chipTheme.secondaryLabelStyle!.color, p.background);
      final border =
          theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      expect(border.borderSide.color, p.text);
      expect(border.borderSide.width, 2);
    });
  }

  test('extensions copy and interpolate all palette and foundation roles', () {
    final p = Palette.dark.copyWith(raised: Palette.light.raised);
    expect(p.raised, Palette.light.raised);
    expect(p.text, Palette.dark.text);
    expect(
      Palette.dark.lerp(Palette.light, 1).background,
      Palette.light.background,
    );
    expect(
      Palette.dark.lerp(Palette.light, .5).raised,
      Color.lerp(Palette.dark.raised, Palette.light.raised, .5),
    );
    const tokens = FoundationTokens();
    expect(tokens.controlRadius, 4);
    expect(tokens.groupRadius, 4);
    expect(tokens.composerRadius, 8);
    expect(tokens.dialogRadius, 8);
    expect(tokens.hover.inMilliseconds, 100);
    expect(tokens.menu.inMilliseconds, 200);
    expect(tokens.menuExit.inMilliseconds, 100);
    expect(tokens.panel.inMilliseconds, 300);
    expect(tokens.dialog.inMilliseconds, 250);
    expect(tokens.page.inMilliseconds, 150);
    expect(FoundationTokens.hoverCurve, MotionCurves.easyEase);
    expect(FoundationTokens.enterCurve, MotionCurves.decelerateMid);
    expect(FoundationTokens.exitCurve, MotionCurves.accelerateMid);
    final other = tokens.copyWith(hover: Duration.zero, groupRadius: 8);
    expect(tokens.lerp(other, .5).hover.inMilliseconds, 50);
    expect(tokens.lerp(other, .5).groupRadius, 6);
  });

  testWidgets('Reduce Motion disables every foundation duration', (
    tester,
  ) async {
    for (final reduce in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: cortexTheme(Brightness.dark),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Builder(
              builder: (context) {
                expect(Motion.of(context).inMilliseconds, reduce ? 0 : 100);
                expect(Motion.menuOf(context).inMilliseconds, reduce ? 0 : 200);
                expect(
                  Motion.panelOf(context).inMilliseconds,
                  reduce ? 0 : 300,
                );
                for (final d in [
                  Motion.menuExitOf(context),
                  Motion.dialogOf(context),
                  Motion.pageOf(context),
                ]) {
                  expect(d.inMilliseconds, reduce ? 0 : isPositive);
                }
                expect(Palette.from(context), Palette.dark);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
    }
  });
}
