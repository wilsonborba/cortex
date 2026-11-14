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
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.control),
    borderSide: BorderSide(color: p.stroke, width: Controls.border),
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
    dividerTheme: DividerThemeData(
      color: p.divider,
      thickness: Strokes.thin,
      space: Strokes.thin,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        side: BorderSide(color: p.stroke),
        shadows: Shadows.shadow4(b),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: p.text, width: Controls.focusRing),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: p.dangerForeground),
      ),
      hintStyle: TextStyles.body1.copyWith(color: p.muted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s8,
      ),
    ),
    // Fluent shadows replace the Material elevation (issue #59, section 7).
    popupMenuTheme: PopupMenuThemeData(
      color: p.raised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        shadows: Shadows.shadow16(b),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.raised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          ShadowedBorder(
            borderRadius: BorderRadius.circular(Radii.control),
            shadows: Shadows.shadow16(b),
          ),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.raised,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      barrierColor: p.overlay,
      constraints: const BoxConstraints(maxWidth: Space.dialogMaxWidth),
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.dialog),
        side: BorderSide(color: p.stroke),
        shadows: Shadows.shadow64(b),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      modalBarrierColor: p.overlay,
      shape: ShadowedBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.sheet),
        ),
        side: BorderSide(color: p.stroke),
        shadows: Shadows.shadow64(b),
      ),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: Controls.minTouch,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s12),
      iconColor: p.muted,
      selectedTileColor: p.raised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      titleTextStyle: TextStyles.body1.copyWith(color: p.text),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.text.withValues(alpha: 0.05),
      selectedIconTheme: IconThemeData(
        color: p.text,
        size: IconSizes.navigation,
      ),
      unselectedIconTheme: IconThemeData(
        color: p.muted,
        size: IconSizes.navigation,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.text.withValues(alpha: 0.05),
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.text : p.muted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyles.caption1.copyWith(
          color: states.contains(WidgetState.selected) ? p.text : p.muted,
        ),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.text : p.surface,
      ),
      checkColor: WidgetStatePropertyAll(p.background),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) ? p.text : p.stroke,
          width: states.contains(WidgetState.focused)
              ? Controls.focusRing
              : Controls.border,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? p.text : p.surface,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? p.background : p.muted,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused) ? p.text : p.stroke,
      ),
      trackOutlineWidth: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? Controls.focusRing
            : Controls.border,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.text : p.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.background : p.text,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.focused) ? p.text : p.stroke,
            width: states.contains(WidgetState.focused)
                ? Controls.focusRing
                : Controls.border,
          ),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.text,
      secondaryLabelStyle: TextStyles.caption1.copyWith(color: p.background),
      checkmarkColor: p.background,
      labelStyle: TextStyles.caption1.copyWith(color: p.text),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) ? p.text : p.stroke,
          width: states.contains(WidgetState.focused)
              ? Controls.focusRing
              : Controls.border,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
      ),
    ),
    // Text buttons and icon buttons are neutral: the accent is only for the
    // primary button and the selected item (C2).
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: p.text,
            textStyle: TextStyles.body1Strong,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.control),
            ),
          ).copyWith(
            side: WidgetStateProperty.resolveWith(
              (states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? p.text
                    : Colors.transparent,
                width: Controls.focusRing,
              ),
            ),
          ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: p.raised,
      contentTextStyle: TextStyles.body1.copyWith(color: p.text),
      actionTextColor: p.text,
      elevation: 0,
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        shadows: Shadows.shadow8(b),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      textStyle: TextStyles.caption1.copyWith(color: p.text),
      constraints: const BoxConstraints(maxWidth: Space.tooltipMaxWidth),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(Radii.control),
        boxShadow: Shadows.shadow8(b),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(p.muted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.muted),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.text).copyWith(
        side: WidgetStateProperty.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.focused)
                ? p.text
                : Colors.transparent,
            width: Controls.focusRing,
          ),
        ),
      ),
    ),
    focusColor: p.text.withValues(alpha: 0.12),
    hoverColor: p.text.withValues(alpha: 0.06),
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
/// surface stays clean.
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
        ..clipPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect.inflate(reach)),
            outer,
          ),
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
