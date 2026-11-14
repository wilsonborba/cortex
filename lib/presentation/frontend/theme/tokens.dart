import 'package:flutter/material.dart';

/// Cortex foundation tokens: Fluent 2 values (issue #59) with the Asodya brand
/// in the Fluent brand slots. Font family stays Ubuntu Sans.
///
/// Brand colors are only for: the one primary button of a view, the selected
/// nav indicator, switch on, checkbox checked, progress fill, input focus
/// underline, the selected graph node ring and the selected card tint.
/// Links stay neutral. Status colors always go with an icon and a text.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.background,
    required this.surface,
    required this.raised,
    required this.subtleHover,
    required this.subtlePressed,
    required this.selected,
    required this.tagBackground,
    required this.disabledBackground,
    required this.stroke,
    required this.strokeHover,
    required this.divider,
    required this.strokeAccessible,
    required this.disabledStroke,
    required this.text,
    required this.text2,
    required this.muted,
    required this.disabledText,
    required this.focusOuter,
    required this.focusInner,
    required this.overlay,
    required this.brandBackground,
    required this.brandBackgroundHover,
    required this.brandBackgroundPressed,
    required this.brandBackgroundSelected,
    required this.brandForeground1,
    required this.brandStroke1,
    required this.brandBackground2,
    required this.onBrand,
    required this.dangerBackground,
    required this.dangerForeground,
    required this.dangerBorder,
    required this.dangerSolid,
    required this.onDanger,
    required this.warningBackground,
    required this.warningForeground,
    required this.warningBorder,
    required this.successBackground,
    required this.successForeground,
    required this.successBorder,
  });
  final Color background;
  final Color surface;
  final Color raised;
  final Color subtleHover;
  final Color subtlePressed;
  final Color selected;
  final Color tagBackground;
  final Color disabledBackground;
  final Color stroke;
  final Color strokeHover;
  final Color divider;
  final Color strokeAccessible;
  final Color disabledStroke;
  final Color text;
  final Color text2;
  final Color muted;
  final Color disabledText;
  final Color focusOuter;
  final Color focusInner;
  final Color overlay;
  final Color brandBackground;
  final Color brandBackgroundHover;
  final Color brandBackgroundPressed;
  final Color brandBackgroundSelected;
  final Color brandForeground1;
  final Color brandStroke1;
  final Color brandBackground2;
  final Color onBrand;
  final Color dangerBackground;
  final Color dangerForeground;
  final Color dangerBorder;
  final Color dangerSolid;
  final Color onDanger;
  final Color warningBackground;
  final Color warningForeground;
  final Color warningBorder;
  final Color successBackground;
  final Color successForeground;
  final Color successBorder;

  static const light = Palette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    raised: Color(0xFFFFFFFF),
    subtleHover: Color(0xFFF5F5F5),
    subtlePressed: Color(0xFFE0E0E0),
    selected: Color(0xFFEBEBEB),
    tagBackground: Color(0xFFF5F5F5),
    disabledBackground: Color(0xFFF0F0F0),
    stroke: Color(0xFFD1D1D1),
    strokeHover: Color(0xFFC7C7C7),
    divider: Color(0xFFE0E0E0),
    strokeAccessible: Color(0xFF616161),
    disabledStroke: Color(0xFFE0E0E0),
    text: Color(0xFF242424),
    text2: Color(0xFF424242),
    muted: Color(0xFF616161),
    disabledText: Color(0xFFBDBDBD),
    focusOuter: Color(0xFF000000),
    focusInner: Color(0xFFFFFFFF),
    overlay: Color.fromRGBO(0, 0, 0, 0.4),
    brandBackground: Color(0xFF7C3AED),
    brandBackgroundHover: Color(0xFF6D33D1),
    brandBackgroundPressed: Color(0xFF5729A6),
    brandBackgroundSelected: Color(0xFF632EBE),
    brandForeground1: Color(0xFF7C3AED),
    brandStroke1: Color(0xFF7C3AED),
    brandBackground2: Color(0xFFF2EBFD),
    onBrand: Color(0xFFFFFFFF),
    dangerBackground: Color(0xFFFDF3F4),
    dangerForeground: Color(0xFFB10E1C),
    dangerBorder: Color(0xFFEEACB2),
    dangerSolid: Color(0xFFC50F1F),
    onDanger: Color(0xFFFFFFFF),
    warningBackground: Color(0xFFFFF9F5),
    warningForeground: Color(0xFFBC4B09),
    warningBorder: Color(0xFFFDCFB4),
    successBackground: Color(0xFFF1FAF1),
    successForeground: Color(0xFF0E700E),
    successBorder: Color(0xFF9FD89F),
  );
  static const dark = Palette(
    background: Color(0xFF292929),
    surface: Color(0xFF1F1F1F),
    raised: Color(0xFF292929),
    subtleHover: Color(0xFF383838),
    subtlePressed: Color(0xFF2E2E2E),
    selected: Color(0xFF333333),
    tagBackground: Color(0xFF141414),
    disabledBackground: Color(0xFF141414),
    stroke: Color(0xFF666666),
    strokeHover: Color(0xFF757575),
    divider: Color(0xFF525252),
    strokeAccessible: Color(0xFFADADAD),
    disabledStroke: Color(0xFF424242),
    text: Color(0xFFFFFFFF),
    text2: Color(0xFFD6D6D6),
    muted: Color(0xFFADADAD),
    disabledText: Color(0xFF5C5C5C),
    focusOuter: Color(0xFFFFFFFF),
    focusInner: Color(0xFF000000),
    overlay: Color.fromRGBO(0, 0, 0, 0.5),
    brandBackground: Color(0xFF6EFF00),
    brandBackgroundHover: Color(0xFF92FF40),
    brandBackgroundPressed: Color(0xFF52BF00),
    brandBackgroundSelected: Color(0xFF5ED900),
    brandForeground1: Color(0xFF6EFF00),
    brandStroke1: Color(0xFF6EFF00),
    brandBackground2: Color(0xFF2B411A),
    onBrand: Color(0xFF000000),
    dangerBackground: Color(0xFF3B0509),
    dangerForeground: Color(0xFFDC626D),
    dangerBorder: Color(0xFFC50F1F),
    dangerSolid: Color(0xFFC50F1F),
    onDanger: Color(0xFFFFFFFF),
    warningBackground: Color(0xFF4A1E04),
    warningForeground: Color(0xFFFAA06B),
    warningBorder: Color(0xFFF7630C),
    successBackground: Color(0xFF052505),
    successForeground: Color(0xFF54B054),
    successBorder: Color(0xFF107C10),
  );
  static Palette from(BuildContext context) =>
      Theme.of(context).extension<Palette>()!;
  static Palette of(Brightness b) => b == Brightness.dark ? dark : light;

  @override
  Palette copyWith({
    Color? background,
    Color? surface,
    Color? raised,
    Color? subtleHover,
    Color? subtlePressed,
    Color? selected,
    Color? tagBackground,
    Color? disabledBackground,
    Color? stroke,
    Color? strokeHover,
    Color? divider,
    Color? strokeAccessible,
    Color? disabledStroke,
    Color? text,
    Color? text2,
    Color? muted,
    Color? disabledText,
    Color? focusOuter,
    Color? focusInner,
    Color? overlay,
    Color? brandBackground,
    Color? brandBackgroundHover,
    Color? brandBackgroundPressed,
    Color? brandBackgroundSelected,
    Color? brandForeground1,
    Color? brandStroke1,
    Color? brandBackground2,
    Color? onBrand,
    Color? dangerBackground,
    Color? dangerForeground,
    Color? dangerBorder,
    Color? dangerSolid,
    Color? onDanger,
    Color? warningBackground,
    Color? warningForeground,
    Color? warningBorder,
    Color? successBackground,
    Color? successForeground,
    Color? successBorder,
  }) => Palette(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    raised: raised ?? this.raised,
    subtleHover: subtleHover ?? this.subtleHover,
    subtlePressed: subtlePressed ?? this.subtlePressed,
    selected: selected ?? this.selected,
    tagBackground: tagBackground ?? this.tagBackground,
    disabledBackground: disabledBackground ?? this.disabledBackground,
    stroke: stroke ?? this.stroke,
    strokeHover: strokeHover ?? this.strokeHover,
    divider: divider ?? this.divider,
    strokeAccessible: strokeAccessible ?? this.strokeAccessible,
    disabledStroke: disabledStroke ?? this.disabledStroke,
    text: text ?? this.text,
    text2: text2 ?? this.text2,
    muted: muted ?? this.muted,
    disabledText: disabledText ?? this.disabledText,
    focusOuter: focusOuter ?? this.focusOuter,
    focusInner: focusInner ?? this.focusInner,
    overlay: overlay ?? this.overlay,
    brandBackground: brandBackground ?? this.brandBackground,
    brandBackgroundHover: brandBackgroundHover ?? this.brandBackgroundHover,
    brandBackgroundPressed:
        brandBackgroundPressed ?? this.brandBackgroundPressed,
    brandBackgroundSelected:
        brandBackgroundSelected ?? this.brandBackgroundSelected,
    brandForeground1: brandForeground1 ?? this.brandForeground1,
    brandStroke1: brandStroke1 ?? this.brandStroke1,
    brandBackground2: brandBackground2 ?? this.brandBackground2,
    onBrand: onBrand ?? this.onBrand,
    dangerBackground: dangerBackground ?? this.dangerBackground,
    dangerForeground: dangerForeground ?? this.dangerForeground,
    dangerBorder: dangerBorder ?? this.dangerBorder,
    dangerSolid: dangerSolid ?? this.dangerSolid,
    onDanger: onDanger ?? this.onDanger,
    warningBackground: warningBackground ?? this.warningBackground,
    warningForeground: warningForeground ?? this.warningForeground,
    warningBorder: warningBorder ?? this.warningBorder,
    successBackground: successBackground ?? this.successBackground,
    successForeground: successForeground ?? this.successForeground,
    successBorder: successBorder ?? this.successBorder,
  );

  @override
  Palette lerp(covariant Palette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      subtleHover: mix(subtleHover, other.subtleHover),
      subtlePressed: mix(subtlePressed, other.subtlePressed),
      selected: mix(selected, other.selected),
      tagBackground: mix(tagBackground, other.tagBackground),
      disabledBackground: mix(disabledBackground, other.disabledBackground),
      stroke: mix(stroke, other.stroke),
      strokeHover: mix(strokeHover, other.strokeHover),
      divider: mix(divider, other.divider),
      strokeAccessible: mix(strokeAccessible, other.strokeAccessible),
      disabledStroke: mix(disabledStroke, other.disabledStroke),
      text: mix(text, other.text),
      text2: mix(text2, other.text2),
      muted: mix(muted, other.muted),
      disabledText: mix(disabledText, other.disabledText),
      focusOuter: mix(focusOuter, other.focusOuter),
      focusInner: mix(focusInner, other.focusInner),
      overlay: mix(overlay, other.overlay),
      brandBackground: mix(brandBackground, other.brandBackground),
      brandBackgroundHover: mix(
        brandBackgroundHover,
        other.brandBackgroundHover,
      ),
      brandBackgroundPressed: mix(
        brandBackgroundPressed,
        other.brandBackgroundPressed,
      ),
      brandBackgroundSelected: mix(
        brandBackgroundSelected,
        other.brandBackgroundSelected,
      ),
      brandForeground1: mix(brandForeground1, other.brandForeground1),
      brandStroke1: mix(brandStroke1, other.brandStroke1),
      brandBackground2: mix(brandBackground2, other.brandBackground2),
      onBrand: mix(onBrand, other.onBrand),
      dangerBackground: mix(dangerBackground, other.dangerBackground),
      dangerForeground: mix(dangerForeground, other.dangerForeground),
      dangerBorder: mix(dangerBorder, other.dangerBorder),
      dangerSolid: mix(dangerSolid, other.dangerSolid),
      onDanger: mix(onDanger, other.onDanger),
      warningBackground: mix(warningBackground, other.warningBackground),
      warningForeground: mix(warningForeground, other.warningForeground),
      warningBorder: mix(warningBorder, other.warningBorder),
      successBackground: mix(successBackground, other.successBackground),
      successForeground: mix(successForeground, other.successForeground),
      successBorder: mix(successBorder, other.successBorder),
    );
  }
}

/// Fluent global spacing ramp (base 4 px). Allowed values: 0, 2, 4, 6, 8, 10,
/// 12, 16, 20, 24, 28, 32, 36, 40, 48, 52, 56.
abstract final class Space {
  static const s2 = 2.0, s4 = 4.0, s6 = 6.0, s8 = 8.0, s10 = 10.0;
  static const s12 = 12.0, s16 = 16.0, s20 = 20.0, s24 = 24.0, s28 = 28.0;
  static const s32 = 32.0, s36 = 36.0, s40 = 40.0, s48 = 48.0, s52 = 52.0;
  static const s56 = 56.0;
  static const section = s56;
  static const contentMaxWidth = 1200.0;
  static const sidebarWidth = 260.0;
  static const railWidth = 48.0;
  static const detailsWidth = 320.0;
  static const personaFormWidth = 640.0;
  static const chatColumnWidth = 768.0;
  static const userBubbleFraction = 0.8;
  static const menuMinWidth = 138.0;
  static const menuMaxWidth = 300.0;
  static const tooltipMaxWidth = 240.0;
  static const dialogMaxWidth = 600.0;
  static const topicInputWidth = 160.0;
  static const readingMaxChars = 68;
}

/// Fluent corner radius. No radius at a screen edge: full-width bars and the
/// sidebar have 0.
/// Engineering diagram canvas (#70): a neutral dark canvas in both themes;
/// the diagrams on it use the Fluent dark palette.
abstract final class DiagramPalette {
  static const canvas = Color(0xFF1C1C1E);
}

abstract final class Radii {
  /// Checkbox, small badges.
  static const small = 2.0;

  /// Buttons (small, medium), inputs, menu items, menus, tooltips, toasts,
  /// tags, cards, message bars, nav items.
  static const control = 4.0;

  /// Large buttons (40 px).
  static const large = 6.0;

  /// Dialogs, the composer, the user message bubble.
  static const dialog = 8.0;

  /// Top corners of bottom sheets.
  static const sheet = 12.0;

  /// Avatars, switch track, progress bar ends, pulsing dot.
  static const circular = 10000.0;
}

/// Fluent stroke widths. Borders 1, focus ring 2, selected nav indicator 4.
abstract final class Strokes {
  static const thin = 1.0, thick = 2.0, thicker = 3.0, thickest = 4.0;
  static const navIndicator = thickest;
  static const cap = StrokeCap.round;
}

/// Fluent elevation. Each level is an ambient and a key shadow, neutral only.
/// Cards [shadow4]; menus, popovers, account menu [shadow16]; tooltips and
/// toasts [shadow8]; composer [shadow4]; dialogs and modal drawers
/// [shadow64]. Sidebar, rail, top bar and inline panels: no shadow, a 1 px
/// divider line.
abstract final class Shadows {
  static const _lightAmbient = Color.fromRGBO(0, 0, 0, 0.12);
  static const _lightKey = Color.fromRGBO(0, 0, 0, 0.14);
  static const _darkAmbient = Color.fromRGBO(0, 0, 0, 0.24);
  static const _darkKey = Color.fromRGBO(0, 0, 0, 0.28);

  static Color ambient(Brightness b) =>
      b == Brightness.dark ? _darkAmbient : _lightAmbient;
  static Color key(Brightness b) => b == Brightness.dark ? _darkKey : _lightKey;

  static List<BoxShadow> _level(
    Brightness b,
    double ambientBlur,
    double keyBlur,
    double keyY,
  ) => [
    BoxShadow(color: ambient(b), blurRadius: ambientBlur),
    BoxShadow(color: key(b), blurRadius: keyBlur, offset: Offset(0, keyY)),
  ];

  static List<BoxShadow> shadow2(Brightness b) => _level(b, 2, 2, 1);
  static List<BoxShadow> shadow4(Brightness b) => _level(b, 2, 4, 2);
  static List<BoxShadow> shadow8(Brightness b) => _level(b, 2, 8, 4);
  static List<BoxShadow> shadow16(Brightness b) => _level(b, 2, 16, 8);
  static List<BoxShadow> shadow28(Brightness b) => _level(b, 8, 28, 14);
  static List<BoxShadow> shadow64(Brightness b) => _level(b, 8, 64, 32);
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
  static const navigation = 20.0;
  static const action = 20.0;
  static const chip = 16.0;
  static const small = 16.0;

  /// Actions at compact width.
  static const large = 24.0;

  /// Square size of icon only buttons.
  static const buttonSmall = 24.0, buttonMedium = 32.0, buttonLarge = 40.0;
}

abstract final class Controls {
  static const composerMaxLines = 8;
  static const budgetWarningFraction = 0.8;

  /// Fluent large (40) at compact width, Fluent medium (32) at other widths.
  static double height(SizeClass size) => size == SizeClass.compact ? 40 : 32;

  /// Small controls inside dense rows.
  static const smallHeight = 24.0;

  /// Tap area at compact width, not the visual size.
  static const minTouch = 44.0;
  static const border = Strokes.thin;

  /// Fluent small tags are 24 px high. Flutter chips have a 32 px minimum
  /// that the chip theme cannot change. The chip applies half of the
  /// density size change, so -4 (16 px) removes 8 px.
  static const tagDensity = VisualDensity(
    vertical: VisualDensity.minimumDensity,
  );
  static const focusRing = Strokes.thick;
}

/// Fluent durations (ms).
abstract final class MotionDurations {
  static const ultraFast = Duration(milliseconds: 50);
  static const faster = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 200);
  static const gentle = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 300);
  static const slower = Duration(milliseconds: 400);
  static const ultraSlow = Duration(milliseconds: 500);
}

/// Fluent curves.
/// Named times outside the Fluent motion ramp (#69): the wait thresholds
/// of the Fluent wait rules (#63), the thinking pulse, the copy feedback and
/// the pace of the landing demos.
abstract final class WaitTimes {
  /// No wait indicator before this time.
  static const indicator = Duration(seconds: 1);

  /// A spinner is for short waits; longer waits with a total get a bar.
  static const spinner = Duration(seconds: 3);

  /// One loop of the thinking pulse.
  static const pulse = Duration(seconds: 1);

  /// How long "Copied" stays before the copy icon comes back.
  static const copied = Duration(seconds: 2);

  /// Landing demos: one pipeline stage and one demo step.
  static const demoStage = Duration(milliseconds: 1200);
  static const demoStep = Duration(milliseconds: 450);
}

abstract final class MotionCurves {
  /// Elements that enter (menus, dialogs, toasts, panels open).
  static const decelerateMid = Cubic(0, 0, 0, 1);

  /// Elements that exit.
  static const accelerateMid = Cubic(1, 0, 1, 1);

  /// State changes in place (hover, switch, selection).
  static const easyEase = Cubic(0.33, 0, 0.67, 1);

  /// Rotation of spinners only.
  static const linear = Curves.linear;
}

/// Foundation geometry and motion, available through the active theme.
@immutable
class FoundationTokens extends ThemeExtension<FoundationTokens> {
  const FoundationTokens({
    this.controlRadius = Radii.control,
    this.groupRadius = Radii.control,
    this.composerRadius = Radii.dialog,
    this.dialogRadius = Radii.dialog,
    this.hover = MotionDurations.faster,
    this.menu = MotionDurations.normal,
    this.menuExit = MotionDurations.faster,
    this.panel = MotionDurations.slow,
    this.dialog = MotionDurations.gentle,
    this.page = MotionDurations.fast,
  });

  /// [groupRadius] is the card radius; [composerRadius] follows dialogs.
  final double controlRadius, groupRadius, composerRadius, dialogRadius;

  /// [menu] is the menu enter time.
  final Duration hover, menu, menuExit, panel, dialog, page;

  static const hoverCurve = MotionCurves.easyEase;
  static const enterCurve = MotionCurves.decelerateMid;
  static const exitCurve = MotionCurves.accelerateMid;
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
    Duration? menuExit,
    Duration? panel,
    Duration? dialog,
    Duration? page,
  }) => FoundationTokens(
    controlRadius: controlRadius ?? this.controlRadius,
    groupRadius: groupRadius ?? this.groupRadius,
    composerRadius: composerRadius ?? this.composerRadius,
    dialogRadius: dialogRadius ?? this.dialogRadius,
    hover: hover ?? this.hover,
    menu: menu ?? this.menu,
    menuExit: menuExit ?? this.menuExit,
    panel: panel ?? this.panel,
    dialog: dialog ?? this.dialog,
    page: page ?? this.page,
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
      menuExit: time(menuExit, other.menuExit),
      panel: time(panel, other.panel),
      dialog: time(dialog, other.dialog),
      page: time(page, other.page),
    );
  }
}

/// Durations of the active theme. Every value is zero with Reduce Motion.
abstract final class Motion {
  static Duration _pick(
    BuildContext context,
    Duration Function(FoundationTokens) value,
  ) {
    final tokens = FoundationTokens.of(context);
    return tokens.duration(context, value(tokens));
  }

  /// Hover and other state changes in place.
  static Duration of(BuildContext context) => _pick(context, (t) => t.hover);
  static Duration menuOf(BuildContext context) => _pick(context, (t) => t.menu);
  static Duration menuExitOf(BuildContext context) =>
      _pick(context, (t) => t.menuExit);
  static Duration panelOf(BuildContext context) =>
      _pick(context, (t) => t.panel);
  static Duration dialogOf(BuildContext context) =>
      _pick(context, (t) => t.dialog);
  static Duration pageOf(BuildContext context) => _pick(context, (t) => t.page);
}

/// Fluent web type ramp in Ubuntu Sans (size / line height px). Weights 400
/// and 600 only.
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
  static const _regular = FontWeight.w400, _strong = FontWeight.w600;

  /// Landing hero title at expanded width only.
  static final display = _t(68, 92, _strong);

  /// Landing hero title at compact and medium width; public page titles.
  static final largeTitle = _t(40, 52, _strong);

  /// Landing section titles at expanded width.
  static final title1 = _t(32, 40, _strong);

  /// Landing section titles at compact and medium width.
  static final title2 = _t(28, 36, _strong);

  /// Screen titles inside the app.
  static final title3 = _t(24, 32, _strong);

  /// Dialog titles, card group titles, empty state titles.
  static final subtitle1 = _t(20, 28, _strong);

  /// Small headings inside cards and panels.
  static final subtitle2 = _t(16, 22, _strong);

  /// Long reading text: chat answers, user messages, landing paragraphs.
  static final body2 = _t(16, 22, _regular);

  /// Default UI text: nav items, menu items, inputs, table cells, labels.
  static final body1 = _t(14, 20, _regular);

  /// Button labels, tab labels, emphasized UI text.
  static final body1Strong = _t(14, 20, _strong);

  /// Metadata, timestamps, helper text, tags, tooltips.
  static final caption1 = _t(12, 16, _regular);

  /// Sidebar group headers, badges.
  static final caption1Strong = _t(12, 16, _strong);

  /// Graph labels and very small counters only.
  static final caption2 = _t(10, 14, _regular);

  /// Code blocks and inline code. Inline code uses the size of the text
  /// around it.
  static final code = _t(
    14,
    20,
    _regular,
  ).copyWith(fontFamily: mono, fontFamilyFallback: const []);
}

/// A layout-neutral keyboard focus ring for controls without a border theme:
/// Fluent style, 2 px [Palette.focusOuter] outside and 1 px
/// [Palette.focusInner] inside, with the corner radius of the control. Only
/// for keyboard focus. The child keeps its Material keyboard actions and
/// semantics.
class FoundationFocus extends StatefulWidget {
  const FoundationFocus({super.key, required this.child, this.radius});
  final Widget child;

  /// Corner radius of the control. Defaults to [FoundationTokens.controlRadius].
  final double? radius;
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
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final visible =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (value) => setState(() => focused = value),
      child: CustomPaint(
        foregroundPainter: visible
            ? FocusRingPainter(
                outer: p.focusOuter,
                inner: p.focusInner,
                radius:
                    widget.radius ?? FoundationTokens.of(context).controlRadius,
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

/// Paints the Fluent keyboard focus ring inside the given bounds.
class FocusRingPainter extends CustomPainter {
  const FocusRingPainter({
    required this.outer,
    required this.inner,
    required this.radius,
  });
  final Color outer, inner;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const o = Controls.focusRing, i = Strokes.thin;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(o / 2), Radius.circular(radius)),
      Paint()
        ..color = outer
        ..style = PaintingStyle.stroke
        ..strokeWidth = o,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(o + i / 2),
        Radius.circular((radius - o).clamp(0, radius)),
      ),
      Paint()
        ..color = inner
        ..style = PaintingStyle.stroke
        ..strokeWidth = i,
    );
  }

  @override
  bool shouldRepaint(FocusRingPainter old) =>
      old.outer != outer || old.inner != inner || old.radius != radius;
}
