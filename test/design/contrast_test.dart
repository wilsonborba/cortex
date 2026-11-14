import 'dart:math' as math;
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.04045
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final x = lum(a), y = lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

double _ratio(Color a, Color b) =>
    double.parse(contrast(a, b).toStringAsFixed(1));

void main() {
  test('issue 59 brand contrast pairs (section 2), both themes', () {
    const l = Palette.light, d = Palette.dark;
    expect(_ratio(l.onBrand, l.brandBackground), 5.7);
    expect(_ratio(l.brandForeground1, l.background), 5.7);
    expect(_ratio(d.onBrand, d.brandBackground), 16.0);
    expect(_ratio(d.brandForeground1, d.background), 11.1);
  });
  for (final (name, p) in [('dark', Palette.dark), ('light', Palette.light)]) {
    test('$name: every neutral text pair is at least 4.5:1', () {
      final pairs = {
        'text on background': (p.text, p.background),
        'text on surface': (p.text, p.surface),
        'text on raised': (p.text, p.raised),
        'text on selected': (p.text, p.selected),
        'text2 on background': (p.text2, p.background),
        'text2 on surface': (p.text2, p.surface),
        'muted on raised': (p.muted, p.raised),
        'muted on background': (p.muted, p.background),
        'muted on surface': (p.muted, p.surface),
        'muted on subtle hover': (p.muted, p.subtleHover),
        'on-brand on brand': (p.onBrand, p.brandBackground),
        'on-brand on brand hover': (p.onBrand, p.brandBackgroundHover),
        'on-brand on brand pressed': (p.onBrand, p.brandBackgroundPressed),
        'on-danger on danger solid': (p.onDanger, p.dangerSolid),
        'danger on danger background': (p.dangerForeground, p.dangerBackground),
        'background on text': (p.background, p.text),
        // Pairs added by #62 to #70.
        'text on tag background': (p.text, p.tagBackground),
        'text2 on tag background': (p.text2, p.tagBackground),
        'text2 on selected': (p.text2, p.selected),
        'muted on selected': (p.muted, p.selected),
        'text on subtle hover': (p.text, p.subtleHover),
        'text2 on raised': (p.text2, p.raised),
        'text on warning background': (p.text, p.warningBackground),
        'text on danger background': (p.text, p.dangerBackground),
        'text on success background': (p.text, p.successBackground),
        // Dark value #E37D80 is the owner decision in cortex #71.
        'danger on raised': (p.dangerForeground, p.raised),
        'danger on surface': (p.dangerForeground, p.surface),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: label);
      }
    });
    test('$name: icons and strokes that carry meaning are at least 3:1', () {
      expect(
        contrast(p.dangerForeground, p.background),
        greaterThanOrEqualTo(3),
      );
      expect(contrast(p.dangerForeground, p.surface), greaterThanOrEqualTo(3));
      expect(
        contrast(p.brandForeground1, p.background),
        greaterThanOrEqualTo(3),
      );
      expect(contrast(p.brandStroke1, p.surface), greaterThanOrEqualTo(3));
      expect(
        contrast(p.strokeAccessible, p.background),
        greaterThanOrEqualTo(3),
      );
      expect(contrast(p.focusOuter, p.background), greaterThanOrEqualTo(3));
      expect(contrast(p.focusOuter, p.focusInner), greaterThanOrEqualTo(3));
      // Message bar icons, control strokes and the selected indicators.
      expect(
        contrast(p.warningForeground, p.warningBackground),
        greaterThanOrEqualTo(3),
      );
      expect(
        contrast(p.successForeground, p.successBackground),
        greaterThanOrEqualTo(3),
      );
      expect(contrast(p.brandForeground1, p.surface), greaterThanOrEqualTo(3));
      expect(contrast(p.brandForeground1, p.selected), greaterThanOrEqualTo(3));
      expect(contrast(p.brandStroke1, p.raised), greaterThanOrEqualTo(3));
      expect(contrast(p.text2, p.surface), greaterThanOrEqualTo(3));
    });
  }
  test('engineering diagram canvas (#70): dark palette text on #1C1C1E', () {
    const d = Palette.dark;
    for (final fg in [d.text, d.text2, d.muted]) {
      expect(contrast(fg, DiagramPalette.canvas), greaterThanOrEqualTo(4.5));
    }
    expect(
      contrast(d.strokeAccessible, DiagramPalette.canvas),
      greaterThanOrEqualTo(3),
    );
  });
}
