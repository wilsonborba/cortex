import 'package:flutter/material.dart';
import 'tokens.dart';

/// Material theme from the tokens: no shadows, no gradients, 1 px borders.
ThemeData cortexTheme(Brightness brightness) {
  final p = Palette.of(brightness);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    secondary: p.text,
    onSecondary: p.background,
    error: p.danger,
    onError: p.onDanger,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.border,
    outlineVariant: p.border,
    shadow: Colors.transparent,
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
    fontFamily: TextStyles.family,
    fontFamilyFallback: TextStyles.fallback,
    textTheme: text,
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
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
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
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accent,
      labelStyle: TextStyles.label.copyWith(color: p.text),
      side: BorderSide(color: p.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.control),
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
