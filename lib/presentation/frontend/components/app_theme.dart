import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Monochrome, high-contrast, Apple-style design system.
///
/// Both themes share the same shape language (14px radius for controls,
/// 20-24px for cards) and typography (Inter), they only swap the palette.
class AppTheme {
  AppTheme._();

  static const Color _lightInk = Color(0xFF0D0D0D);
  static const Color _lightSurface = Color(0xFFF7F7F7);
  static const Color _lightBackground = Color(0xFFE2E2E2);

  static const Color _darkInk = Color(0xFFF5F5F5);
  static const Color _darkSurfaceHigh = Color(0xFF242424);
  static const Color _darkSurface = Color(0xFF111111);

  /// Radius used by buttons, text fields and the prompt dock.
  static const double controlRadius = 14;

  /// Radius used by cards and larger containers.
  static const double cardRadius = 22;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightInk,
      brightness: Brightness.light,
      primary: _lightInk,
      onPrimary: _lightSurface,
      surface: _lightSurface,
      onSurface: _lightInk,
      surfaceContainerHighest: Colors.white.withValues(alpha: 0.6),
    );
    return _base(colorScheme, _lightBackground);
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkInk,
      brightness: Brightness.dark,
      primary: _darkInk,
      onPrimary: _darkSurface,
      surface: _darkSurfaceHigh,
      onSurface: _darkInk,
      surfaceContainerHighest: Colors.white.withValues(alpha: 0.06),
    );
    return _base(colorScheme, _darkSurface);
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
