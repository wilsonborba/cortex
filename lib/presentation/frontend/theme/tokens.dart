import 'package:flutter/material.dart';

/// Asodya Design System tokens (Hippo rule 1aceb7d9, area 24, issue #27).
/// Monochrome UI; the brand accent is used only on the primary button and the
/// selected item.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.raised,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
  });
  final Color background;
  final Color surface;
  final Color raised;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color onDanger;

  static const dark = Palette(
    background: Color(0xFF1C1C1E),
    surface: Color(0xFF242426),
    raised: Color(0xFF2C2C2E),
    border: Color(0xFF3A3A3C),
    text: Color(0xFFF2F2F2),
    muted: Color(0xFFA1A1A6),
    accent: Color(0xFF6EFF00),
    onAccent: Color(0xFF000000),
    danger: Color(0xFFFF6B6B),
    onDanger: Color(0xFF000000),
  );
  static const light = Palette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F5),
    raised: Color(0xFFFFFFFF),
    border: Color(0xFFE4E4E7),
    text: Color(0xFF1E1E1E),
    muted: Color(0xFF52525B),
    accent: Color(0xFF7C3AED),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB42318),
    onDanger: Color(0xFFFFFFFF),
  );
  static Palette from(BuildContext context) =>
      Theme.of(context).extension<Palette>()!;

  @override
  Palette copyWith({
    Color? background,
    Color? surface,
    Color? raised,
    Color? border,
    Color? text,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? onDanger,
  }) => Palette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    border: border ?? this.border,
    text: text ?? this.text,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
  );

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }

  static Palette of(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Spacing scale (px). Sections are 64 apart.
abstract final class Space {
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0;
  static const s24 = 24.0, s32 = 32.0, s40 = 40.0, s48 = 48.0, s64 = 64.0;
  static const section = s64;
  static const contentMaxWidth = 1200.0;
  static const sidebarWidth = 280.0;
  static const railWidth = 56.0;
  static const detailsWidth = 320.0;
  static const readingMaxChars = 68;
}

abstract final class Radii {
  static const control = 8.0;
  static const card = 12.0;
  static const composer = 16.0;
  static const dialog = 16.0;
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

abstract final class IconSizes {
  static const navigation = 18.0;
  static const action = 16.0;
  static const chip = 14.0;
}

abstract final class Controls {
  static double height(SizeClass size) => size == SizeClass.compact ? 44 : 36;
  static const minTouch = 44.0;
  static const border = 1.0;
  static const focusRing = 2.0;
}

/// Foundation geometry and motion, available through the active theme.
@immutable
class FoundationTokens extends ThemeExtension<FoundationTokens> {
  const FoundationTokens({
    this.controlRadius = Radii.control,
    this.groupRadius = Radii.card,
    this.composerRadius = Radii.composer,
    this.dialogRadius = Radii.dialog,
    this.hover = const Duration(milliseconds: 120),
    this.menu = const Duration(milliseconds: 160),
    this.panel = const Duration(milliseconds: 200),
  });
  final double controlRadius, groupRadius, composerRadius, dialogRadius;
  final Duration hover, menu, panel;
  static const curve = Curves.easeOutCubic;
  static FoundationTokens of(BuildContext context) =>
      Theme.of(context).extension<FoundationTokens>()!;
  Duration duration(BuildContext context, Duration value) =>
      MediaQuery.maybeDisableAnimationsOf(context) == true
      ? Duration.zero
      : value;

  @override
  FoundationTokens copyWith({
    double? controlRadius,
    double? groupRadius,
    double? composerRadius,
    double? dialogRadius,
    Duration? hover,
    Duration? menu,
    Duration? panel,
  }) => FoundationTokens(
    controlRadius: controlRadius ?? this.controlRadius,
    groupRadius: groupRadius ?? this.groupRadius,
    composerRadius: composerRadius ?? this.composerRadius,
    dialogRadius: dialogRadius ?? this.dialogRadius,
    hover: hover ?? this.hover,
    menu: menu ?? this.menu,
    panel: panel ?? this.panel,
  );
  @override
  FoundationTokens lerp(covariant FoundationTokens? other, double t) {
    if (other == null) return this;
    double mix(double a, double b) => a + (b - a) * t;
    Duration time(Duration a, Duration b) => Duration(
      microseconds: mix(
        a.inMicroseconds.toDouble(),
        b.inMicroseconds.toDouble(),
      ).round(),
    );
    return FoundationTokens(
      controlRadius: mix(controlRadius, other.controlRadius),
      groupRadius: mix(groupRadius, other.groupRadius),
      composerRadius: mix(composerRadius, other.composerRadius),
      dialogRadius: mix(dialogRadius, other.dialogRadius),
      hover: time(hover, other.hover),
      menu: time(menu, other.menu),
      panel: time(panel, other.panel),
    );
  }
}

abstract final class Motion {
  static Duration of(BuildContext context) {
    final tokens = FoundationTokens.of(context);
    return tokens.duration(context, tokens.hover);
  }

  static Duration menuOf(BuildContext context) {
    final tokens = FoundationTokens.of(context);
    return tokens.duration(context, tokens.menu);
  }

  static Duration panelOf(BuildContext context) {
    final tokens = FoundationTokens.of(context);
    return tokens.duration(context, tokens.panel);
  }
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

/// A layout-neutral keyboard focus ring for controls without a border theme.
/// The child keeps its existing Material keyboard actions and semantics.
class FoundationFocus extends StatefulWidget {
  const FoundationFocus({super.key, required this.child});
  final Widget child;
  @override
  State<FoundationFocus> createState() => _FoundationFocusState();
}

class _FoundationFocusState extends State<FoundationFocus> {
  bool focused = false;
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  void _modeChanged(FocusHighlightMode mode) {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    skipTraversal: true,
    canRequestFocus: false,
    onFocusChange: (value) => setState(() => focused = value),
    child: DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          FoundationTokens.of(context).controlRadius,
        ),
        border: Border.all(
          color:
              focused &&
                  FocusManager.instance.highlightMode ==
                      FocusHighlightMode.traditional
              ? Palette.from(context).text
              : Colors.transparent,
          width: Controls.focusRing,
        ),
      ),
      child: widget.child,
    ),
  );
}
