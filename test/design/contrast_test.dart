import 'dart:math' as math;
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast ratio.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final x = lum(a), y = lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  for (final (name, p) in [('dark', Palette.dark), ('light', Palette.light)]) {
    test('$name: every text token pair is at least 4.5:1', () {
      final pairs = {
        'text on background': (p.text, p.background),
        'text on surface': (p.text, p.surface),
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
