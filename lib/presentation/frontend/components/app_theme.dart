import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome, high-contrast, Apple-style design system.
///
/// Both themes share the same shape language (14px radius for controls,
/// 20-24px for cards) and typography (Inter), they only swap the palette.
class AppTheme {
  AppTheme._();

  static const Color _lightInk = Color(0xFF0D0D0D);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceSubtle = Color(0xFFF3F3F5);
  static const Color _lightBackground = Color(0xFFF8F8FA);
  static const Color _lightBorder = Color(0xFFE2E2E7);

  static const Color _darkInk = Color(0xFFF5F5F7);
  static const Color _darkSurface = Color(0xFF141416);
  static const Color _darkSurfaceSubtle = Color(0xFF1C1C1F);
  static const Color _darkBackground = Color(0xFF0A0A0C);
  static const Color _darkBorder = Color(0xFF26262A);

  /// Radius used by buttons, text fields, pills and chips (Apple 12-14px control radius).
  static const double controlRadius = 12;

  /// Radius used by cards, modals, sheets and docks.
  static const double cardRadius = 18;

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _lightInk,
      onPrimary: _lightSurface,
      secondary: const Color(0xFF48484A),
      onSecondary: _lightSurface,
      surface: _lightSurface,
      onSurface: _lightInk,
      surfaceContainerHighest: _lightSurfaceSubtle,
      outline: _lightBorder,
    );
    return _base(colorScheme, _lightBackground);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.dark(
      primary: _darkInk,
      onPrimary: _darkBackground,
      secondary: const Color(0xFFA1A1A6),
      onSecondary: _darkInk,
      surface: _darkSurface,
      onSurface: _darkInk,
      surfaceContainerHighest: _darkSurfaceSubtle,
      outline: _darkBorder,
    );
    return _base(colorScheme, _darkBackground);
  }

  static ThemeData _base(ColorScheme colorScheme, Color scaffoldBackground) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      dividerColor: colorScheme.outline.withValues(alpha: 0.5),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
        ),
      ),
    );
  }

  /// Translucent glass surface with subtle blur and Apple-style outer stroke.
  static BoxDecoration glassDecoration(
    BuildContext context, {
    double radius = cardRadius,
    double borderOpacity = 0.6,
    double fillOpacity = 0.85,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: scheme.surface.withValues(alpha: fillOpacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: scheme.outline.withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
