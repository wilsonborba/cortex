import 'package:flutter/material.dart';
import 'tokens.dart';

/// Material theme from the tokens: no shadows, no gradients, 1 px borders.
ThemeData cortexTheme(Brightness brightness) {
  final p = Palette.of(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.text,
    onPrimary: p.background,
    secondary: p.text,
    onSecondary: p.background,
    error: p.danger,
    onError: p.onDanger,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.border,
    outlineVariant: p.border,
    shadow: Colors.black,
    scrim: p.background.withValues(alpha: 0.6),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.control),
    borderSide: BorderSide(color: p.border, width: Controls.border),
  );
  final text = TextTheme(
    displayLarge: TextStyles.display,
    headlineLarge: TextStyles.pageTitle,
    headlineMedium: TextStyles.section,
    titleLarge: TextStyles.subsection,
    bodyLarge: TextStyles.body,
    bodyMedium: TextStyles.compact,
    labelLarge: TextStyles.label,
    labelMedium: TextStyles.label,
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
    shadowColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: p.border),
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
      errorBorder: border.copyWith(borderSide: BorderSide(color: p.danger)),
      hintStyle: TextStyles.body.copyWith(color: p.muted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Space.s12,
        vertical: Space.s8,
      ),
    ),
    // Owner approved Flutter's default menu/dialog elevation on 2026-11-12.
    popupMenuTheme: PopupMenuThemeData(
      color: p.raised,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.raised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.black),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.card),
          ),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.raised,
      shadowColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.dialog),
        side: BorderSide(color: p.border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Radii.card),
        ),
        side: BorderSide(color: p.border),
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
      titleTextStyle: TextStyles.compact.copyWith(color: p.text),
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
        (states) => TextStyles.label.copyWith(
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
          color: states.contains(WidgetState.focused) ? p.text : p.border,
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
        (states) => states.contains(WidgetState.focused) ? p.text : p.border,
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
            color: states.contains(WidgetState.focused) ? p.text : p.border,
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
      secondaryLabelStyle: TextStyles.label.copyWith(color: p.background),
      checkmarkColor: p.background,
      labelStyle: TextStyles.label.copyWith(color: p.text),
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) ? p.text : p.border,
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
            textStyle: TextStyles.compact,
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
      contentTextStyle: TextStyles.compact.copyWith(color: p.text),
      actionTextColor: p.text,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      textStyle: TextStyles.label.copyWith(color: p.text),
      decoration: BoxDecoration(
        color: p.raised,
        borderRadius: BorderRadius.circular(Radii.control),
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
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
