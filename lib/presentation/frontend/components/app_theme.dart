import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome, high-contrast, Apple-style design system.
///
/// Both themes share the same shape language (14px radius for controls,
/// 20-24px for cards) and typography (Inter), they only swap the palette.
class AppTheme {
  AppTheme._();

  static const Color _lightInk = Color(0xFF000000);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightSurfaceSubtle = Color(0xFFF4F4F6);
  static const Color _lightBackground = Color(0xFFECECEC);
  static const Color _lightBorder = Color(0xFFC8C8CC);

  static const Color _darkInk = Color(0xFFECEFF4);
  static const Color _darkSurface = Color(0xFF111318);
  static const Color _darkSurfaceSubtle = Color(0xFF16181F);
  static const Color _darkBackground = Color(0xFF090A0C);
  static const Color _darkBorder = Color(0xFF232730);

  /// Radius used by buttons, text fields and the prompt dock.
  static const double controlRadius = 8;

  /// Radius used by cards and larger containers.
  static const double cardRadius = 12;

  static ThemeData light() {
    final colorScheme = ColorScheme.light(
      primary: _lightInk,
      onPrimary: _lightSurface,
      secondary: const Color(0xFF3A3A3C),
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
      secondary: const Color(0xFF8892B0),
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
      dividerColor: colorScheme.onSurface.withValues(alpha: 0.08),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
      ),
    );
  }

  /// Translucent glass surface used by cards, docks and sheets.
  static BoxDecoration glassDecoration(
    BuildContext context, {
    double radius = cardRadius,
    double borderOpacity = 0.10,
    double fillOpacity = 0.55,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: scheme.surface.withValues(alpha: fillOpacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: scheme.onSurface.withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.10),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
