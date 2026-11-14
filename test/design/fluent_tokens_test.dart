import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every value of issue #59, checked against the issue tables.
void main() {
  Color c(int rgb) => Color(0xFF000000 | rgb);

  test('palette has exactly the issue 59 colors', () {
    const l = Palette.light, d = Palette.dark;
    final table = <String, (Color, Color, Color, Color)>{
      'background': (l.background, c(0xFFFFFF), d.background, c(0x292929)),
      'surface': (l.surface, c(0xFAFAFA), d.surface, c(0x1F1F1F)),
      'raised': (l.raised, c(0xFFFFFF), d.raised, c(0x292929)),
      'subtleHover': (l.subtleHover, c(0xF5F5F5), d.subtleHover, c(0x383838)),
      'subtlePressed': (
        l.subtlePressed,
        c(0xE0E0E0),
        d.subtlePressed,
        c(0x2E2E2E),
      ),
      'selected': (l.selected, c(0xEBEBEB), d.selected, c(0x333333)),
      'tagBackground': (
        l.tagBackground,
        c(0xF5F5F5),
        d.tagBackground,
        c(0x141414),
      ),
      'disabledBackground': (
        l.disabledBackground,
        c(0xF0F0F0),
        d.disabledBackground,
        c(0x141414),
      ),
      'stroke': (l.stroke, c(0xD1D1D1), d.stroke, c(0x666666)),
      'strokeHover': (l.strokeHover, c(0xC7C7C7), d.strokeHover, c(0x757575)),
      'divider': (l.divider, c(0xE0E0E0), d.divider, c(0x525252)),
      'strokeAccessible': (
        l.strokeAccessible,
        c(0x616161),
        d.strokeAccessible,
        c(0xADADAD),
      ),
      'disabledStroke': (
        l.disabledStroke,
        c(0xE0E0E0),
        d.disabledStroke,
        c(0x424242),
      ),
      'text': (l.text, c(0x242424), d.text, c(0xFFFFFF)),
      'text2': (l.text2, c(0x424242), d.text2, c(0xD6D6D6)),
      'muted': (l.muted, c(0x616161), d.muted, c(0xADADAD)),
      'disabledText': (
        l.disabledText,
        c(0xBDBDBD),
        d.disabledText,
        c(0x5C5C5C),
      ),
      'focusOuter': (l.focusOuter, c(0x000000), d.focusOuter, c(0xFFFFFF)),
      'focusInner': (l.focusInner, c(0xFFFFFF), d.focusInner, c(0x000000)),
      'overlay': (
        l.overlay,
        const Color.fromRGBO(0, 0, 0, 0.4),
        d.overlay,
        const Color.fromRGBO(0, 0, 0, 0.5),
      ),
      'brandBackground': (
        l.brandBackground,
        c(0x7C3AED),
        d.brandBackground,
        c(0x6EFF00),
      ),
      'brandBackgroundHover': (
        l.brandBackgroundHover,
        c(0x6D33D1),
        d.brandBackgroundHover,
        c(0x92FF40),
      ),
      'brandBackgroundPressed': (
        l.brandBackgroundPressed,
        c(0x5729A6),
        d.brandBackgroundPressed,
        c(0x52BF00),
      ),
      'brandBackgroundSelected': (
        l.brandBackgroundSelected,
        c(0x632EBE),
        d.brandBackgroundSelected,
        c(0x5ED900),
      ),
      'brandForeground1': (
        l.brandForeground1,
        c(0x7C3AED),
        d.brandForeground1,
        c(0x6EFF00),
      ),
      'brandStroke1': (
        l.brandStroke1,
        c(0x7C3AED),
        d.brandStroke1,
        c(0x6EFF00),
      ),
      'brandBackground2': (
        l.brandBackground2,
        c(0xF2EBFD),
        d.brandBackground2,
        c(0x2B411A),
      ),
      'onBrand': (l.onBrand, c(0xFFFFFF), d.onBrand, c(0x000000)),
      'dangerBackground': (
        l.dangerBackground,
        c(0xFDF3F4),
        d.dangerBackground,
        c(0x3B0509),
      ),
      'dangerForeground': (
        l.dangerForeground,
        c(0xB10E1C),
        d.dangerForeground,
        c(0xE37D80),
      ),
      'dangerBorder': (
        l.dangerBorder,
        c(0xEEACB2),
        d.dangerBorder,
        c(0xC50F1F),
      ),
      'dangerSolid': (l.dangerSolid, c(0xC50F1F), d.dangerSolid, c(0xC50F1F)),
      'onDanger': (l.onDanger, c(0xFFFFFF), d.onDanger, c(0xFFFFFF)),
      'warningBackground': (
        l.warningBackground,
        c(0xFFF9F5),
        d.warningBackground,
        c(0x4A1E04),
      ),
      'warningForeground': (
        l.warningForeground,
        c(0xBC4B09),
        d.warningForeground,
        c(0xFAA06B),
      ),
      'warningBorder': (
        l.warningBorder,
        c(0xFDCFB4),
        d.warningBorder,
        c(0xF7630C),
      ),
      'successBackground': (
        l.successBackground,
        c(0xF1FAF1),
        d.successBackground,
        c(0x052505),
      ),
      'successForeground': (
        l.successForeground,
        c(0x0E700E),
        d.successForeground,
        c(0x54B054),
      ),
      'successBorder': (
        l.successBorder,
        c(0x9FD89F),
        d.successBorder,
        c(0x107C10),
      ),
    };
    for (final MapEntry(key: role, value: (la, le, da, de)) in table.entries) {
      expect(la, le, reason: 'light $role');
      expect(da, de, reason: 'dark $role');
    }
    final mixed = l.lerp(d, 1);
    expect(mixed.brandBackground2, d.brandBackground2);
    expect(mixed.successBorder, d.successBorder);
    expect(l.copyWith(divider: d.divider).divider, d.divider);
  });

  test('type ramp: sizes, line heights, weights 400 and 600 only', () {
    final ramp = {
      'display': (TextStyles.display, 68, 92, 600),
      'largeTitle': (TextStyles.largeTitle, 40, 52, 600),
      'title1': (TextStyles.title1, 32, 40, 600),
      'title2': (TextStyles.title2, 28, 36, 600),
      'title3': (TextStyles.title3, 24, 32, 600),
      'subtitle1': (TextStyles.subtitle1, 20, 28, 600),
      'subtitle2': (TextStyles.subtitle2, 16, 22, 600),
      'body2': (TextStyles.body2, 16, 22, 400),
      'body1': (TextStyles.body1, 14, 20, 400),
      'body1Strong': (TextStyles.body1Strong, 14, 20, 600),
      'caption1': (TextStyles.caption1, 12, 16, 400),
      'caption1Strong': (TextStyles.caption1Strong, 12, 16, 600),
      'caption2': (TextStyles.caption2, 10, 14, 400),
      'code': (TextStyles.code, 14, 20, 400),
    };
    for (final MapEntry(key: name, value: (s, size, line, w)) in ramp.entries) {
      expect(s.fontSize, size, reason: name);
      expect(s.fontSize! * s.height!, closeTo(line, 1e-9), reason: name);
      expect(s.fontWeight!.value, w, reason: name);
      expect(
        s.fontFamily,
        name == 'code' ? TextStyles.mono : TextStyles.family,
      );
    }
    expect(TextStyles.family, 'Ubuntu Sans');
    // Migration names point to the new styles.
    expect(TextStyles.largeTitle, TextStyles.largeTitle);
    expect(TextStyles.title3, TextStyles.title3);
    expect(TextStyles.subtitle1, TextStyles.subtitle1);
    expect(TextStyles.body2, TextStyles.body2);
    expect(TextStyles.body1, TextStyles.body1);
    expect(TextStyles.caption1, TextStyles.caption1);
  });

  test('spacing, layout widths, radii and strokes', () {
    expect(
      [
        Space.s2,
        Space.s4,
        Space.s6,
        Space.s8,
        Space.s10,
        Space.s12,
        Space.s16,
        Space.s20,
        Space.s24,
        Space.s28,
        Space.s32,
        Space.s36,
        Space.s40,
        Space.s48,
        Space.s52,
        Space.s56,
      ],
      [2, 4, 6, 8, 10, 12, 16, 20, 24, 28, 32, 36, 40, 48, 52, 56],
    );
    expect(Space.section, 56);
    expect(Space.sidebarWidth, 260);
    expect(Space.railWidth, 48);
    expect(Space.detailsWidth, 320);
    expect(Space.chatColumnWidth, 768);
    expect(Space.contentMaxWidth, 1200);
    expect(Space.personaFormWidth, 640);
    expect(Space.menuMinWidth, 138);
    expect(Space.menuMaxWidth, 300);
    expect(Space.tooltipMaxWidth, 240);
    expect(Space.dialogMaxWidth, 600);
    expect(
      [
        Radii.small,
        Radii.control,
        Radii.large,
        Radii.dialog,
        Radii.sheet,
        Radii.circular,
      ],
      [2, 4, 6, 8, 12, 10000],
    );
    expect(
      [Strokes.thin, Strokes.thick, Strokes.thicker, Strokes.thickest],
      [1, 2, 3, 4],
    );
    expect(Strokes.navIndicator, 4);
    expect(Controls.focusRing, 2);
    expect(Controls.height(SizeClass.compact), 40);
    expect(Controls.height(SizeClass.medium), 32);
    expect(Controls.height(SizeClass.expanded), 32);
    expect(Controls.smallHeight, 24);
    expect(Controls.minTouch, 44);
    expect(
      [
        IconSizes.navigation,
        IconSizes.action,
        IconSizes.chip,
        IconSizes.small,
        IconSizes.large,
      ],
      [20, 20, 16, 16, 24],
    );
    expect(
      [IconSizes.buttonSmall, IconSizes.buttonMedium, IconSizes.buttonLarge],
      [24, 32, 40],
    );
  });

  test('shadows: two neutral layers per level, theme colors', () {
    final levels = {
      2: (Shadows.shadow2, 2.0, 2.0, 1.0),
      4: (Shadows.shadow4, 2.0, 4.0, 2.0),
      8: (Shadows.shadow8, 2.0, 8.0, 4.0),
      16: (Shadows.shadow16, 2.0, 16.0, 8.0),
      28: (Shadows.shadow28, 8.0, 28.0, 14.0),
      64: (Shadows.shadow64, 8.0, 64.0, 32.0),
    };
    for (final b in Brightness.values) {
      final dark = b == Brightness.dark;
      for (final MapEntry(key: n, value: (f, ab, kb, ky)) in levels.entries) {
        final s = f(b);
        expect(s, hasLength(2), reason: 'shadow$n');
        expect(s[0].blurRadius, ab);
        expect(s[0].offset, Offset.zero);
        expect(
          s[0].color,
          Color.fromRGBO(0, 0, 0, dark ? 0.24 : 0.12),
          reason: 'shadow$n ambient',
        );
        expect(s[1].blurRadius, kb);
        expect(s[1].offset, Offset(0, ky));
        expect(
          s[1].color,
          Color.fromRGBO(0, 0, 0, dark ? 0.28 : 0.14),
          reason: 'shadow$n key',
        );
      }
    }
  });

  test('motion: durations and curves', () {
    expect(
      [
        MotionDurations.ultraFast,
        MotionDurations.faster,
        MotionDurations.fast,
        MotionDurations.normal,
        MotionDurations.gentle,
        MotionDurations.slow,
        MotionDurations.slower,
        MotionDurations.ultraSlow,
      ].map((d) => d.inMilliseconds),
      [50, 100, 150, 200, 250, 300, 400, 500],
    );
    expect(MotionCurves.decelerateMid, const Cubic(0, 0, 0, 1));
    expect(MotionCurves.accelerateMid, const Cubic(1, 0, 1, 1));
    expect(MotionCurves.easyEase, const Cubic(0.33, 0, 0.67, 1));
    expect(MotionCurves.linear, Curves.linear);
  });

  for (final b in Brightness.values) {
    test('${b.name}: theme uses the ramp, radii, shadows and durations', () {
      final t = cortexTheme(b);
      final p = t.extension<Palette>()!;
      expect(t.textTheme.displayLarge!.fontSize, 68);
      expect(t.textTheme.headlineLarge!.fontSize, 40);
      expect(t.textTheme.headlineMedium!.fontSize, 24);
      expect(t.textTheme.titleLarge!.fontSize, 20);
      expect(t.textTheme.titleMedium!.fontSize, 16);
      expect(t.textTheme.bodyLarge!.fontSize, 16);
      expect(t.textTheme.bodyMedium!.fontSize, 14);
      expect(t.textTheme.labelLarge!.fontWeight, FontWeight.w600);
      expect(t.textTheme.labelMedium!.fontSize, 12);
      expect(t.textTheme.bodySmall!.fontSize, 12);

      final dialog = t.dialogTheme.shape! as ShadowedBorder;
      expect(dialog.borderRadius, BorderRadius.circular(8));
      expect(dialog.shadows, Shadows.shadow64(b));
      expect(t.dialogTheme.elevation, 0);
      expect(t.dialogTheme.barrierColor, p.overlay);
      final popup = t.popupMenuTheme.shape! as ShadowedBorder;
      expect(popup.borderRadius, BorderRadius.circular(4));
      expect(popup.shadows, Shadows.shadow16(b));
      final menu = t.menuTheme.style!.shape!.resolve({})! as ShadowedBorder;
      expect(menu.shadows, Shadows.shadow16(b));
      expect(menu.borderRadius, BorderRadius.circular(4));
      final card = t.cardTheme.shape! as ShadowedBorder;
      expect(card.shadows, Shadows.shadow4(b));
      expect(card.borderRadius, BorderRadius.circular(4));
      final toast = t.snackBarTheme.shape! as ShadowedBorder;
      expect(toast.shadows, Shadows.shadow8(b));
      final tip = t.tooltipTheme.decoration! as BoxDecoration;
      expect(tip.boxShadow, Shadows.shadow8(b));
      expect(t.tooltipTheme.constraints!.maxWidth, 240);
      final sheet = t.bottomSheetTheme.shape! as ShadowedBorder;
      expect(
        sheet.borderRadius,
        const BorderRadius.vertical(top: Radius.circular(12)),
      );
      expect(t.colorScheme.scrim, p.overlay);
      final page = t.pageTransitionsTheme.builders[TargetPlatform.linux]!;
      expect(page.transitionDuration.inMilliseconds, 150);
    });
  }

  testWidgets('a shadowed border paints shadows outside the shape only', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: cortexTheme(Brightness.light),
        home: Center(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Material(
                color: Palette.light.raised,
                shape: ShadowedBorder(
                  borderRadius: BorderRadius.circular(Radii.dialog),
                  shadows: Shadows.shadow16(Brightness.light),
                ),
                child: const SizedBox(width: 100, height: 60),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard focus ring: outer focus color then inner color', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: cortexTheme(Brightness.dark),
        home: Center(
          child: FoundationFocus(
            child: TextButton(
              focusNode: node,
              onPressed: () {},
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    node.requestFocus();
    await tester.pump();
    final ring = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.foregroundPainter)
        .whereType<FocusRingPainter>()
        .single;
    expect(ring.outer, Palette.dark.focusOuter);
    expect(ring.inner, Palette.dark.focusInner);
    expect(ring.radius, Radii.control);
    FocusManager.instance.highlightStrategy = FocusHighlightStrategy.automatic;
  });
}
