import 'package:flutter/material.dart';

import '../../../dal/local/local_storage_adapter.dart';
import '../../../domain/services/app_preferences_service.dart';

/// Holds the app's persisted theme mode and locale, and loads them from
/// [AppPreferencesService] once at startup.
///
/// Starts with sane in-memory defaults (system theme, system/platform
/// locale) so the first frame never blocks on storage, then applies the
/// persisted values (if any) as soon as they resolve and notifies
/// listeners, which is enough for [AppPreferencesScope] to rebuild
/// `MaterialApp`.
class AppPreferencesController extends ChangeNotifier {
  AppPreferencesController({AppPreferencesService? service})
    : _service = service ?? const AppPreferencesService(LocalStorageAdapter()) {
    _load();
  }

  final AppPreferencesService _service;

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale;
  bool _improveInput = false;

  ThemeMode get themeMode => _themeMode;

  /// `null` means "follow the platform locale", resolved by
  /// `localeResolutionCallback`/`supportedLocales` in `MaterialApp`.
  Locale? get locale => _locale;

  bool get improveInput => _improveInput;

  Future<void> _load() async {
    final mode = await _service.readThemeMode();
    final localeCode = await _service.readLocaleCode();
    final improveInput = await _service.readImproveInput();
    _themeMode = mode;
    _locale = localeCode == null ? null : Locale(localeCode);
    _improveInput = improveInput;
    notifyListeners();
  }

  Future<void> setImproveInput(bool value) async {
    if (_improveInput == value) return;
    _improveInput = value;
    notifyListeners();
    await _service.writeImproveInput(value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _service.writeThemeMode(mode);
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _service.writeLocaleCode(locale?.languageCode);
  }
}

/// Exposes the current [AppPreferencesController] to the widget tree.
///
/// Read it with `AppPreferencesScope.of(context)` (rebuilds the caller on
/// every theme/locale change) or `AppPreferencesScope.controllerOf(context)`
/// when only the controller instance is needed (e.g. to call a setter from
/// an event handler without subscribing to rebuilds).
class AppPreferencesScope extends InheritedNotifier<AppPreferencesController> {
  const AppPreferencesScope({
    super.key,
    required AppPreferencesController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppPreferencesController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'No AppPreferencesScope found in context');
    return scope!.notifier!;
  }

  static AppPreferencesController controllerOf(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'No AppPreferencesScope found in context');
    return scope!.notifier!;
  }
}
