import 'package:flutter/widgets.dart';

/// Asodya Design System tokens (Hippo rule 1aceb7d9, area 24, issue #27).
/// Monochrome UI; the brand accent is used only on the primary button and the
/// selected item.
@immutable
class Palette {
  const Palette({
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
    required this.grid,
  });
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color onDanger;
  final Color grid;

  static const dark = Palette(
    background: Color(0xFF090A0C),
    surface: Color(0xFF111318),
    border: Color(0xFF232730),
    text: Color(0xFFECEFF4),
    muted: Color(0xFF8892B0),
    accent: Color(0xFF6EFF00),
    onAccent: Color(0xFF000000),
    danger: Color(0xFFFF6B6B),
    onDanger: Color(0xFF000000),
    grid: Color(0xFF14161C),
  );
  static const light = Palette(
    background: Color(0xFFF7F7F5),
    surface: Color(0xFFFFFFFF),
    border: Color(0xFFC8C8CC),
    text: Color(0xFF181818),
    muted: Color(0xFF5B5B57),
    accent: Color(0xFF7C3AED),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB42318),
    onDanger: Color(0xFFFFFFFF),
    grid: Color(0xFFEAEAE6),
  );
  static Palette of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Spacing scale (px). Sections are 64 apart.
abstract final class Space {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0, s64 = 64.0;
  static const section = s64;
  static const contentMaxWidth = 1200.0;
  static const readingMaxChars = 68;
}

abstract final class Radii {
  static const control = 8.0;
  static const card = 12.0;
}

/// Size classes by width: compact < 600, medium 600 to 1000, expanded > 1000.
enum SizeClass {
  compact(4),
  medium(6),
  expanded(12);

  const SizeClass(this.columns);
  final int columns;
  static SizeClass of(double width) => width < 600
      ? compact
      : width <= 1000
      ? medium
      : expanded;
}

abstract final class Controls {
  static double height(SizeClass size) => size == SizeClass.compact ? 44 : 36;
  static const minTouch = 44.0;
  static const border = 1.0;
  static const focusRing = 2.0;
}

abstract final class Motion {
  static const transition = Duration(milliseconds: 150);

  /// Still by default; Reduce Motion turns transitions off.
  static Duration of(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
      ? Duration.zero
      : transition;
}

/// Type scale (size / line height px). Weights 400, 500, 600 only.
abstract final class TextStyles {
  static const family = 'Ubuntu Sans';
  static const mono = 'Ubuntu Sans Mono';
  static const fallback = ['IBM Plex Sans Thai'];
  static TextStyle _t(double size, double line, FontWeight weight) => TextStyle(
    fontFamily: family,
    fontFamilyFallback: fallback,
    fontSize: size,
    height: line / size,
    fontWeight: weight,
  );
  static final display = _t(48, 56, FontWeight.w600);
  static final pageTitle = _t(40, 48, FontWeight.w600);
  static final section = _t(24, 32, FontWeight.w600);
  static final subsection = _t(20, 26, FontWeight.w500);
  static final body = _t(16, 24, FontWeight.w400);
  static final compact = _t(14, 20, FontWeight.w400);
  static final label = _t(13, 18, FontWeight.w500);
}
