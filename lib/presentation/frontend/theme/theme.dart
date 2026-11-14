import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'tokens.dart';

/// Material theme from the Fluent 2 tokens (issue #59): neutral surfaces,
/// 1 px strokes, Fluent corners and Fluent shadows on cards, menus, toasts,
/// tooltips and dialogs. No gradients.
ThemeData cortexTheme(Brightness brightness) {
  final p = Palette.of(brightness);
  final b = brightness;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.text,
    onPrimary: p.background,
    secondary: p.text,
    onSecondary: p.background,
    error: p.dangerForeground,
    onError: p.onDanger,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.stroke,
    outlineVariant: p.divider,
    shadow: Shadows.key(b),
    scrim: p.overlay,
  );
  final text = TextTheme(
    displayLarge: TextStyles.display,
    headlineLarge: TextStyles.largeTitle,
    headlineMedium: TextStyles.title3,
    titleLarge: TextStyles.subtitle1,
    titleMedium: TextStyles.subtitle2,
    bodyLarge: TextStyles.body2,
    bodyMedium: TextStyles.body1,
    labelLarge: TextStyles.body1Strong,
    labelMedium: TextStyles.caption1,
    bodySmall: TextStyles.caption1,
  ).apply(bodyColor: p.text, displayColor: p.text);
  final input = FluentInputBorder(
    side: BorderSide(color: p.stroke),
    bottom: BorderSide(color: p.strokeAccessible),
    focus: p.brandStroke1,
  );
  final dark = b == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [p, const FoundationTokens()],
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.text,
      selectionColor: p.text.withValues(alpha: 0.25),
      selectionHandleColor: p.text,
    ),
    fontFamily: TextStyles.family,
    fontFamilyFallback: TextStyles.fallback,
    textTheme: text,
    iconTheme: IconThemeData(size: IconSizes.action, color: p.text),
    scaffoldBackgroundColor: p.background,
    shadowColor: Shadows.key(b),
    splashFactory: NoSplash.splashFactory,
    // Fluent shows hover and pressed fills; focus is the keyboard ring only.
    hoverColor: p.subtleHover,
    highlightColor: p.subtlePressed,
    focusColor: Colors.transparent,
    splashColor: Colors.transparent,
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: Strokes.thin,
      space: Strokes.thin,
    ),
    // Card: raised, radius 4, shadow4, no border (#61).
    cardTheme: CardThemeData(
      color: p.raised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        shadows: Shadows.shadow4(b),
      ),
    ),
    // Input: 1 px stroke on three sides, strokeAccessible at the bottom and a
    // 2 px brand bar at the bottom on focus (#61). Label above the field.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.background,
      isDense: true,
      border: input,
      enabledBorder: input,
      focusedBorder: input.copyWith(focused: true),
      errorBorder: input,
      focusedErrorBorder: input.copyWith(focused: true),
      disabledBorder: input.copyWith(
        side: BorderSide(color: p.disabledStroke),
        bottom: BorderSide(color: p.disabledStroke),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: TextStyles.body1.copyWith(color: p.text),
      floatingLabelStyle: TextStyles.body1.copyWith(color: p.text),
      hintStyle: TextStyles.body1.copyWith(color: p.muted),
      helperStyle: TextStyles.caption1.copyWith(color: p.muted),
      errorStyle: TextStyles.caption1.copyWith(color: p.dangerForeground),
      prefixIconColor: p.muted,
      suffixIconColor: p.muted,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s6,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: buttonStyle(p, ButtonAppearance.primary),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: buttonStyle(p, ButtonAppearance.secondary),
    ),
    textButtonTheme: TextButtonThemeData(
      style: buttonStyle(p, ButtonAppearance.subtle),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: buttonStyle(p, ButtonAppearance.subtle).copyWith(
        minimumSize: const WidgetStatePropertyAll(
          Size.square(IconSizes.buttonMedium),
        ),
        fixedSize: const WidgetStatePropertyAll(
          Size.square(IconSizes.buttonMedium),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      ),
    ),
    // Menu: raised, radius 4, padding 4, shadow16; a 1 px divider line in
    // the dark theme only. Width 138 to 300.
    menuTheme: MenuThemeData(style: menuStyle(p, b)),
    menuButtonTheme: MenuButtonThemeData(style: menuItemStyle(p)),
    popupMenuTheme: PopupMenuThemeData(
      color: p.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      menuPadding: const EdgeInsets.all(Space.s4),
      textStyle: TextStyles.body1.copyWith(color: p.text),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyles.body1.copyWith(color: p.text),
      ),
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        side: dark ? BorderSide(color: p.divider) : BorderSide.none,
        shadows: Shadows.shadow16(b),
      ),
    ),
    // Dialog: background, radius 8, shadow64, no border, overlay scrim.
    dialogTheme: DialogThemeData(
      backgroundColor: p.background,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      barrierColor: p.overlay,
      insetPadding: const EdgeInsets.all(Space.s16),
      constraints: const BoxConstraints(maxWidth: Space.dialogMaxWidth),
      titleTextStyle: TextStyles.subtitle1.copyWith(color: p.text),
      contentTextStyle: TextStyles.body1.copyWith(color: p.text),
      actionsPadding: const EdgeInsets.all(Space.s24),
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.dialog),
        shadows: Shadows.shadow64(b),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      modalBarrierColor: p.overlay,
      dragHandleColor: p.strokeAccessible,
      shape: ShadowedBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.sheet),
        ),
        side: BorderSide(color: p.stroke),
        shadows: Shadows.shadow64(b),
      ),
    ),
    // Modal drawer: no corner radius, shadow64.
    drawerTheme: DrawerThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrimColor: p.overlay,
      shape: ShadowedBorder(shadows: Shadows.shadow64(b)),
      endShape: ShadowedBorder(shadows: Shadows.shadow64(b)),
    ),
    // List row: 40 high (44 at compact width through the shell), radius 4.
    listTileTheme: ListTileThemeData(
      minTileHeight: Controls.height(SizeClass.compact),
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s12),
      horizontalTitleGap: Space.s8,
      iconColor: p.text2,
      textColor: p.text,
      selectedColor: p.text,
      selectedTileColor: p.selected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      titleTextStyle: TextStyles.body1.copyWith(color: p.text),
      subtitleTextStyle: TextStyles.caption1.copyWith(color: p.muted),
      leadingAndTrailingTextStyle: TextStyles.caption1.copyWith(color: p.muted),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: Space.s12),
      textColor: p.text,
      collapsedTextColor: p.text,
      iconColor: p.text2,
      collapsedIconColor: p.text2,
      expansionAnimationStyle: const AnimationStyle(
        duration: MotionDurations.normal,
        curve: MotionCurves.decelerateMid,
        reverseDuration: MotionDurations.faster,
        reverseCurve: MotionCurves.accelerateMid,
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.selected,
      selectedIconTheme: IconThemeData(
        color: p.text,
        size: IconSizes.navigation,
      ),
      unselectedIconTheme: IconThemeData(
        color: p.text2,
        size: IconSizes.navigation,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.selected,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.text : p.text2,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyles.caption1.copyWith(
          color: states.contains(WidgetState.selected) ? p.text : p.text2,
        ),
      ),
    ),
    // Checkbox: radius 2, strokeAccessible, brand fill when checked.
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled)
            ? p.disabledBackground
            : s.contains(WidgetState.selected)
            ? p.brandBackground
            : Colors.transparent,
      ),
      checkColor: WidgetStatePropertyAll(p.onBrand),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.small),
      ),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide.none
            : BorderSide(
                color: s.contains(WidgetState.disabled)
                    ? p.disabledStroke
                    : p.strokeAccessible,
              ),
      ),
    ),
    // Switch: off = strokeAccessible outline, muted thumb; on = brand track.
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? p.brandBackground
            : Colors.transparent,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? p.onBrand : p.muted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Colors.transparent
            : p.strokeAccessible,
      ),
      trackOutlineWidth: const WidgetStatePropertyAll(Strokes.thin),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    // Toggle group: subtle toggles in a 1 px stroke frame, radius 4.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(
          Size(0, Controls.height(SizeClass.medium)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: Space.s12),
        ),
        visualDensity: VisualDensity.standard,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? p.selected
              : s.contains(WidgetState.pressed)
              ? p.subtlePressed
              : s.contains(WidgetState.hovered)
              ? p.subtleHover
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? p.disabledText : p.text,
        ),
        iconColor: WidgetStatePropertyAll(p.text),
        iconSize: const WidgetStatePropertyAll(IconSizes.action),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? TextStyles.body1Strong
              : TextStyles.body1,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) => keyboardFocus(s)
              ? BorderSide(color: p.focusOuter, width: Controls.focusRing)
              : BorderSide(color: p.stroke),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
        ),
      ),
    ),
    // Tag (small): 24 high, radius 4, tagBackground, caption1.
    chipTheme: ChipThemeData(
      backgroundColor: p.tagBackground,
      selectedColor: p.selected,
      disabledColor: p.disabledBackground,
      checkmarkColor: p.text,
      showCheckmark: false,
      labelStyle: TextStyles.caption1.copyWith(color: p.text),
      secondaryLabelStyle: TextStyles.caption1.copyWith(color: p.text),
      padding: const EdgeInsets.symmetric(horizontal: Space.s8),
      labelPadding: EdgeInsets.zero,
      iconTheme: IconThemeData(color: p.text, size: IconSizes.chip),
      deleteIconColor: p.text2,
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      selectedShadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      side: WidgetStateBorderSide.resolveWith(
        (s) => keyboardFocus(s)
            ? BorderSide(color: p.focusOuter, width: Controls.focusRing)
            : BorderSide.none,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
    ),
    // Toast look: floating, radius 4, padding 12, raised, shadow8.
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.raised,
      contentTextStyle: TextStyles.body1.copyWith(color: p.text),
      actionTextColor: p.text,
      closeIconColor: p.text2,
      elevation: 0,
      insetPadding: const EdgeInsets.all(Space.s16),
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        shadows: Shadows.shadow8(b),
      ),
    ),
    // Tooltip: background (light) or raised (dark), caption1, padding 4 11 6,
    // radius 4, max width 240, shadow8. The offset is half of the 32 px
    // control height plus the 4 px gap.
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      verticalOffset: Controls.height(SizeClass.medium) / 2 + Space.s4,
      textStyle: TextStyles.caption1.copyWith(color: p.text),
      padding: const EdgeInsets.fromLTRB(
        Space.s10 + Strokes.thin,
        Space.s4,
        Space.s10 + Strokes.thin,
        Space.s6,
      ),
      constraints: const BoxConstraints(maxWidth: Space.tooltipMaxWidth),
      decoration: BoxDecoration(
        color: dark ? p.raised : p.background,
        borderRadius: BorderRadius.circular(Radii.control),
        boxShadow: Shadows.shadow8(b),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(p.strokeAccessible),
      radius: const Radius.circular(Radii.circular),
    ),
    // Progress bar: 2 px, round ends, divider track, brand fill. Spinners
    // (AppSpinner) use the text color on the divider track.
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.brandBackground,
      linearTrackColor: p.divider,
      circularTrackColor: p.divider,
      linearMinHeight: Strokes.thick,
      borderRadius: BorderRadius.circular(Radii.circular),
      strokeCap: Strokes.cap,
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadePageTransitionsBuilder(),
        TargetPlatform.linux: FadePageTransitionsBuilder(),
        TargetPlatform.macOS: FadePageTransitionsBuilder(),
        TargetPlatform.windows: FadePageTransitionsBuilder(),
        TargetPlatform.iOS: FadePageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadePageTransitionsBuilder(),
      },
    ),
  );
}

/// Page change: fade, Fluent fast (150 ms). Reduce Motion skips the fade.
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Duration get transitionDuration => MotionDurations.fast;

  @override
  Duration get reverseTransitionDuration => MotionDurations.fast;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.maybeDisableAnimationsOf(context) == true
      ? child
      : FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: MotionCurves.decelerateMid,
            reverseCurve: MotionCurves.accelerateMid,
          ),
          child: child,
        );
}

/// A rounded rectangle border that paints Fluent shadows outside its shape.
/// Material widgets take one elevation value; Fluent uses two shadows
/// (ambient and key), so the theme sets elevation 0 and uses this border.
/// The shadows are clipped to the outside of the shape, so the content of the
/// surface stays clean. Material paints the border inside its clip, so the
/// widget that uses this border must have `clipBehavior: Clip.none`.
class ShadowedBorder extends OutlinedBorder {
  const ShadowedBorder({
    super.side,
    this.borderRadius = BorderRadius.zero,
    this.shadows = const [],
  });
  final BorderRadiusGeometry borderRadius;
  final List<BoxShadow> shadows;

  RoundedRectangleBorder get _shape =>
      RoundedRectangleBorder(side: side, borderRadius: borderRadius);

  @override
  EdgeInsetsGeometry get dimensions => _shape.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (shadows.isNotEmpty) {
      final outer = getOuterPath(rect, textDirection: textDirection);
      var reach = 0.0;
      for (final s in shadows) {
        reach = [
          reach,
          s.blurRadius * 2 + s.offset.distance,
        ].reduce((a, b) => a > b ? a : b);
      }
      canvas
        ..save()
        // Even-odd fill cuts the shape out of the clip. Path.combine is not
        // reliable on the web renderers and let the shadow cover the
        // content (#72).
        ..clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(rect.inflate(reach))
            ..addPath(outer, Offset.zero),
        );
      for (final s in shadows) {
        canvas.drawPath(outer.shift(s.offset), s.toPaint());
      }
      canvas.restore();
    }
    _shape.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  ShadowedBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
    List<BoxShadow>? shadows,
  }) => ShadowedBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    shadows: shadows ?? this.shadows,
  );

  @override
  ShapeBorder scale(double t) => ShadowedBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    shadows: BoxShadow.lerpList(null, shadows, t) ?? const [],
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ShadowedBorder
      ? ShadowedBorder(
          side: BorderSide.lerp(a.side, side, t),
          borderRadius: BorderRadiusGeometry.lerp(
            a.borderRadius,
            borderRadius,
            t,
          )!,
          shadows: BoxShadow.lerpList(a.shadows, shadows, t) ?? const [],
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is ShadowedBorder
      ? ShadowedBorder(
          side: BorderSide.lerp(side, b.side, t),
          borderRadius: BorderRadiusGeometry.lerp(
            borderRadius,
            b.borderRadius,
            t,
          )!,
          shadows: BoxShadow.lerpList(shadows, b.shadows, t) ?? const [],
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      other is ShadowedBorder &&
      other.side == side &&
      other.borderRadius == borderRadius &&
      listEquals(other.shadows, shadows);

  @override
  int get hashCode => Object.hash(side, borderRadius, Object.hashAll(shadows));
}

/// Fluent button appearances (#61). FilledButton is primary, OutlinedButton
/// secondary, TextButton and IconButton subtle.
enum ButtonAppearance { primary, secondary, subtle, transparent, destructive }

/// Fluent button sizes (#61): height, padding, minimum width, icon size.
enum ButtonSize {
  small(24, EdgeInsets.symmetric(horizontal: 8, vertical: 3), 64, 16),
  medium(32, EdgeInsets.symmetric(horizontal: 12, vertical: 5), 96, 20),
  large(40, EdgeInsets.symmetric(horizontal: 16, vertical: 8), 96, 24);

  const ButtonSize(this.height, this.padding, this.minWidth, this.icon);
  final double height, minWidth, icon;
  final EdgeInsets padding;

  /// Large at compact width, medium at other widths (#59 section 9).
  static ButtonSize of(SizeClass size) =>
      size == SizeClass.compact ? large : medium;
  double get radius => this == large ? Radii.large : Radii.control;
  double get gap => Space.s6;
}

/// True when the control has focus from the keyboard (not pointer or touch).
bool keyboardFocus(Set<WidgetState> states) =>
    states.contains(WidgetState.focused) &&
    FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

/// The Fluent focus ring colors when [states] has keyboard focus, else null.
(Color, Color)? keyboardRing(Palette p, Set<WidgetState> states) =>
    keyboardFocus(states) ? (p.focusOuter, p.focusInner) : null;

/// Fluent button style for an [appearance] and [size]. Transition 100 ms
/// easyEase. No splash. Disabled uses the disabled roles.
ButtonStyle buttonStyle(
  Palette p,
  ButtonAppearance appearance, {
  ButtonSize size = ButtonSize.medium,
}) {
  final primary = appearance == ButtonAppearance.primary;
  final destructive = appearance == ButtonAppearance.destructive;
  Color background(Set<WidgetState> s) {
    final disabled = s.contains(WidgetState.disabled);
    final pressed = s.contains(WidgetState.pressed);
    final hovered = s.contains(WidgetState.hovered);
    return switch (appearance) {
      _
          when disabled &&
              appearance != ButtonAppearance.subtle &&
              appearance != ButtonAppearance.transparent =>
        p.disabledBackground,
      ButtonAppearance.primary =>
        pressed
            ? p.brandBackgroundPressed
            : hovered
            ? p.brandBackgroundHover
            : p.brandBackground,
      ButtonAppearance.destructive => p.dangerSolid,
      ButtonAppearance.secondary =>
        pressed
            ? p.subtlePressed
            : hovered
            ? p.subtleHover
            : p.background,
      ButtonAppearance.subtle =>
        disabled
            ? Colors.transparent
            : pressed
            ? p.subtlePressed
            : hovered
            ? p.subtleHover
            : Colors.transparent,
      ButtonAppearance.transparent => Colors.transparent,
    };
  }

  Color foreground(Set<WidgetState> s) {
    if (s.contains(WidgetState.disabled)) return p.disabledText;
    if (primary) return p.onBrand;
    if (destructive) return p.onDanger;
    if (appearance == ButtonAppearance.transparent) {
      return s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)
          ? p.text
          : p.text2;
    }
    return p.text;
  }

  BorderSide side(Set<WidgetState> s) {
    if (appearance != ButtonAppearance.secondary) return BorderSide.none;
    if (s.contains(WidgetState.disabled)) {
      return BorderSide(color: p.disabledStroke);
    }
    return BorderSide(
      color: s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)
          ? p.strokeHover
          : p.stroke,
    );
  }

  return ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(size.minWidth, size.height)),
    padding: WidgetStatePropertyAll(size.padding),
    iconSize: WidgetStatePropertyAll(size.icon),
    textStyle: WidgetStatePropertyAll(
      size == ButtonSize.small
          ? TextStyles.caption1Strong
          : TextStyles.body1Strong,
    ),
    elevation: const WidgetStatePropertyAll(0),
    shadowColor: const WidgetStatePropertyAll(Colors.transparent),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    splashFactory: NoSplash.splashFactory,
    animationDuration: MotionDurations.faster,
    visualDensity: VisualDensity.standard,
    // Small buttons sit inside message bars and toasts: no extra tap area.
    tapTargetSize: size == ButtonSize.small
        ? MaterialTapTargetSize.shrinkWrap
        : null,
    backgroundColor: WidgetStateProperty.resolveWith(background),
    foregroundColor: WidgetStateProperty.resolveWith(foreground),
    iconColor: WidgetStateProperty.resolveWith(foreground),
    side: WidgetStateProperty.resolveWith(side),
    shape: WidgetStateProperty.resolveWith(
      (s) => ControlBorder(
        side: side(s),
        radius: size.radius,
        ring: keyboardRing(p, s),
      ),
    ),
  );
}

/// Fluent menu popover: raised, radius 4, padding 4, shadow16, width 138 to
/// 300, a 1 px divider line in the dark theme only.
MenuStyle menuStyle(Palette p, Brightness b) => MenuStyle(
  backgroundColor: WidgetStatePropertyAll(p.raised),
  surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
  elevation: const WidgetStatePropertyAll(0),
  shadowColor: const WidgetStatePropertyAll(Colors.transparent),
  padding: const WidgetStatePropertyAll(EdgeInsets.all(Space.s4)),
  minimumSize: const WidgetStatePropertyAll(Size(Space.menuMinWidth, 0)),
  maximumSize: const WidgetStatePropertyAll(
    Size(Space.menuMaxWidth, double.infinity),
  ),
  shape: WidgetStatePropertyAll(
    ShadowedBorder(
      borderRadius: BorderRadius.circular(Radii.control),
      side: b == Brightness.dark
          ? BorderSide(color: p.divider)
          : BorderSide.none,
      shadows: Shadows.shadow16(b),
    ),
  ),
);

/// Fluent menu item: 32 high, padding 6 x 8, radius 4, body1, icon 20.
ButtonStyle menuItemStyle(Palette p) => ButtonStyle(
  minimumSize: WidgetStatePropertyAll(
    Size(0, Controls.height(SizeClass.medium)),
  ),
  maximumSize: const WidgetStatePropertyAll(
    Size(Space.menuMaxWidth - 2 * Space.s4, double.infinity),
  ),
  padding: const WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: Space.s8, vertical: Space.s6),
  ),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  textStyle: WidgetStatePropertyAll(TextStyles.body1),
  iconSize: const WidgetStatePropertyAll(IconSizes.action),
  foregroundColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.disabled) ? p.disabledText : p.text,
  ),
  iconColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.disabled) ? p.disabledText : p.text,
  ),
  backgroundColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.pressed)
        ? p.subtlePressed
        : s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
        ? p.subtleHover
        : Colors.transparent,
  ),
  overlayColor: const WidgetStatePropertyAll(Colors.transparent),
  splashFactory: NoSplash.splashFactory,
  shape: WidgetStateProperty.resolveWith(
    (s) => ControlBorder(ring: keyboardRing(p, s)),
  ),
);

/// A rounded control border with an optional Fluent keyboard focus ring:
/// 2 px outer and 1 px inner color, inside the bounds, same radius.
class ControlBorder extends OutlinedBorder {
  const ControlBorder({super.side, this.radius = Radii.control, this.ring});
  final double radius;

  /// Outer and inner ring colors, or null without keyboard focus.
  final (Color, Color)? ring;

  RoundedRectangleBorder get _shape => RoundedRectangleBorder(
    side: side,
    borderRadius: BorderRadius.circular(radius),
  );

  @override
  EdgeInsetsGeometry get dimensions => _shape.dimensions;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    _shape.paint(canvas, rect, textDirection: textDirection);
    final colors = ring;
    if (colors == null) return;
    FocusRingPainter(
      outer: colors.$1,
      inner: colors.$2,
      radius: radius,
    ).paint(canvas.._save(rect), rect.size);
    canvas.restore();
  }

  @override
  ControlBorder copyWith({BorderSide? side}) =>
      ControlBorder(side: side ?? this.side, radius: radius, ring: ring);

  @override
  ShapeBorder scale(double t) =>
      ControlBorder(side: side.scale(t), radius: radius * t, ring: ring);

  @override
  bool operator ==(Object other) =>
      other is ControlBorder &&
      other.side == side &&
      other.radius == radius &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(side, radius, ring);
}

extension on Canvas {
  /// Saves the canvas and moves the origin to the top left of [rect].
  void _save(Rect rect) {
    save();
    translate(rect.left, rect.top);
  }
}

/// Fluent input frame for Material text fields: 1 px [side] on top, left and
/// right, 1 px [bottom], and a 2 px [focus] bar at the bottom inside the
/// border when [focused]. Between two states the bar grows from the center.
class FluentInputBorder extends InputBorder {
  const FluentInputBorder({
    required this.side,
    required this.bottom,
    required this.focus,
    this.focused = false,
    this.progress,
    this.radius = Radii.control,
  }) : super(borderSide: side);
  final BorderSide side, bottom;
  final Color focus;
  final bool focused;
  final double radius;

  /// Width of the focus bar from 0 to 1 while the border animates.
  final double? progress;
  double get _bar => progress ?? (focused ? 1 : 0);

  @override
  bool get isOutline => true;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  FluentInputBorder copyWith({
    BorderSide? borderSide,
    BorderSide? side,
    BorderSide? bottom,
    Color? focus,
    bool? focused,
  }) => FluentInputBorder(
    side: side ?? borderSide ?? this.side,
    bottom: bottom ?? this.bottom,
    focus: focus ?? this.focus,
    focused: focused ?? this.focused,
    radius: radius,
  );

  RRect _rrect(Rect rect) =>
      RRect.fromRectAndRadius(rect, Radius.circular(radius));

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect).deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(_rrect(rect));

  @override
  void paintInterior(
    Canvas canvas,
    Rect rect,
    Paint paint, {
    TextDirection? textDirection,
  }) => canvas.drawRRect(_rrect(rect), paint);

  @override
  bool get preferPaintInterior => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) => paintFluentFrame(canvas, rect, side, bottom, focus, _bar, radius);

  @override
  ShapeBorder scale(double t) => FluentInputBorder(
    side: side.scale(t),
    bottom: bottom.scale(t),
    focus: focus,
    focused: focused,
    progress: progress,
    radius: radius * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is FluentInputBorder
      ? _lerp(a, this, MotionCurves.decelerateMid.transform(t))
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is FluentInputBorder
      ? _lerp(this, b, MotionCurves.decelerateMid.transform(t))
      : super.lerpTo(b, t);

  static FluentInputBorder _lerp(
    FluentInputBorder a,
    FluentInputBorder b,
    double t,
  ) => FluentInputBorder(
    side: BorderSide.lerp(a.side, b.side, t),
    bottom: BorderSide.lerp(a.bottom, b.bottom, t),
    focus: Color.lerp(a.focus, b.focus, t)!,
    focused: t < 0.5 ? a.focused : b.focused,
    progress: a._bar + (b._bar - a._bar) * t,
    radius: a.radius + (b.radius - a.radius) * t,
  );

  @override
  bool operator ==(Object other) =>
      other is FluentInputBorder &&
      other.side == side &&
      other.bottom == bottom &&
      other.focus == focus &&
      other._bar == _bar &&
      other.radius == radius;

  @override
  int get hashCode => Object.hash(side, bottom, focus, _bar, radius);
}

/// Paints the Fluent input frame: [side] on top, left and right, [bottom] at
/// the bottom, and a 2 px [focus] bar of width [bar] (0 to 1) from the center.
void paintFluentFrame(
  Canvas canvas,
  Rect rect,
  BorderSide side,
  BorderSide bottom,
  Color focus,
  double bar,
  double radius,
) {
  final outer = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  final inner = outer.deflate(side.width);
  canvas
    ..save()
    ..clipRect(
      Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - radius),
    )
    ..drawDRRect(outer, inner, Paint()..color = side.color)
    ..restore()
    ..save()
    ..clipRect(
      Rect.fromLTRB(rect.left, rect.bottom - radius, rect.right, rect.bottom),
    )
    ..drawDRRect(outer, inner, Paint()..color = bottom.color)
    ..restore();
  if (bar <= 0) return;
  final width = (rect.width - 2 * radius) * bar.clamp(0, 1);
  canvas.drawRRect(
    RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(rect.center.dx, rect.bottom - Strokes.thick / 2),
        width: width,
        height: Strokes.thick,
      ),
    ),
    Paint()..color = focus,
  );
}
