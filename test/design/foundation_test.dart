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
      expect(theme.colorScheme.primary, isNot(p.accent));
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
    expect(tokens.controlRadius, 8);
    expect(tokens.groupRadius, 12);
    expect(tokens.composerRadius, 16);
    expect(tokens.dialogRadius, 16);
    expect(tokens.hover.inMilliseconds, 120);
    expect(tokens.menu.inMilliseconds, 160);
    expect(tokens.panel.inMilliseconds, 200);
    expect(FoundationTokens.curve, Curves.easeOutCubic);
    final other = tokens.copyWith(hover: Duration.zero, groupRadius: 8);
    expect(tokens.lerp(other, .5).hover.inMilliseconds, 60);
    expect(tokens.lerp(other, .5).groupRadius, 10);
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
                expect(Motion.of(context).inMilliseconds, reduce ? 0 : 120);
                expect(Motion.menuOf(context).inMilliseconds, reduce ? 0 : 160);
                expect(
                  Motion.panelOf(context).inMilliseconds,
                  reduce ? 0 : 200,
                );
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
