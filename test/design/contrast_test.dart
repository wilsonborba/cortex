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

void main() {
  for (final (name, p) in [('dark', Palette.dark), ('light', Palette.light)]) {
    test('$name: issue 49 reference ratios are preserved', () {
      final expected = name == 'dark'
          ? [15.2, 6.6, 16.0, 6.1]
          : [16.7, 7.7, 5.7, 6.6];
      final actual = [
        contrast(p.text, p.background),
        contrast(p.muted, p.background),
        contrast(p.onAccent, p.accent),
        contrast(p.danger, p.background),
      ];
      for (var i = 0; i < expected.length; i++) {
        // The issue reports one decimal place, not exact real-number minima.
        expect(double.parse(actual[i].toStringAsFixed(1)), expected[i]);
      }
      if (name == 'dark') {
        expect(
          double.parse(contrast(p.muted, p.raised).toStringAsFixed(1)),
          5.4,
        );
      }
    });
    test('$name: every text token pair is at least 4.5:1', () {
      final pairs = {
        'text on background': (p.text, p.background),
        'text on surface': (p.text, p.surface),
        'text on raised': (p.text, p.raised),
        'muted on raised': (p.muted, p.raised),
        'muted on background': (p.muted, p.background),
        'muted on surface': (p.muted, p.surface),
        'on-accent on accent': (p.onAccent, p.accent),
        'on-danger on danger': (p.onDanger, p.danger),
        'background on text': (p.background, p.text),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: label);
      }
    });
    test('$name: icons and borders that carry meaning are at least 3:1', () {
      expect(contrast(p.danger, p.surface), greaterThanOrEqualTo(3));
      expect(contrast(p.accent, p.background), greaterThanOrEqualTo(3));
      expect(
        contrast(p.text, p.surface),
        greaterThanOrEqualTo(3),
      ); // focus ring
    });
  }
}
