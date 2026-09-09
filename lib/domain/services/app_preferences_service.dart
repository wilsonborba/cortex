import 'package:flutter/material.dart';

import '../../dal/local/local_storage_adapter.dart';

/// Persists and restores the user's chosen [ThemeMode] and locale.
///
/// Business logic only: no widget/BuildContext dependency here, so this can
/// be unit-tested with a bare [LocalStorageAdapter] (or a fake standing in
/// for it) and reused by [AppPreferencesController] without pulling in
/// Flutter's presentation layer.
class AppPreferencesService {
  const AppPreferencesService(this._storage);

  final LocalStorageAdapter _storage;

  static const String _themeModeKey = 'app_theme_mode';
  static const String _localeKey = 'app_locale';
  static const String _improveInputKey = 'app_improve_input';

  /// Locale codes this app ships translations for, in the order they should
  /// be offered in the settings UI. Kept here (rather than only in
  /// `AppLocalizations.supportedLocales`) so the domain layer does not need
  /// to depend on the generated localizations package.
  static const List<String> supportedLocaleCodes = ['en', 'pt', 'th'];

  Future<bool> readImproveInput() async {
    final raw = await _storage.readString(_improveInputKey);
    if (raw == null) return true; // default true matching backend schema
    return raw == 'true';
  }

  Future<void> writeImproveInput(bool value) async {
    await _storage.writeString(_improveInputKey, value.toString());
  }

  Future<ThemeMode> readThemeMode() async {
    final raw = await _storage.readString(_themeModeKey);
    return _themeModeFromString(raw);
  }

  Future<void> writeThemeMode(ThemeMode mode) async {
    await _storage.writeString(_themeModeKey, _themeModeToString(mode));
  }

  /// Returns the persisted locale code, or `null` if none was ever chosen
  /// (in which case the app should follow the platform/system locale).
  Future<String?> readLocaleCode() async {
    final raw = await _storage.readString(_localeKey);
    if (raw == null || !supportedLocaleCodes.contains(raw)) return null;
    return raw;
  }

  Future<void> writeLocaleCode(String? code) async {
    if (code == null) {
      await _storage.remove(_localeKey);
      return;
    }
    await _storage.writeString(_localeKey, code);
  }

  static ThemeMode _themeModeFromString(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
