import '../../dal/local/ui_preferences.dart';
import 'package:flutter/material.dart';

/// Language and theme switches of the header (24.A.7).
class Preferences extends ChangeNotifier {
  Preferences({UiPreferenceStore? store})
    : _store = store ?? const UiPreferenceStore() {
    final theme = _read('cortex.ui.theme');
    _theme = switch (theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _locale = switch (_read('cortex.ui.locale')) {
      'en' => const Locale('en'),
      'pt_BR' => const Locale('pt', 'BR'),
      'th' => const Locale('th'),
      _ => null,
    };
    _collapsed = _read('cortex.ui.sidebarCollapsed') == 'true';
  }
  final UiPreferenceStore _store;
  String? _read(String key) {
    try {
      return _store.read(key);
    } catch (_) {
      return null;
    }
  }

  void _save(String key, String value) {
    try {
      _store.write(key, value);
    } catch (_) {}
  }

  bool _collapsed = false;
  bool get collapsed => _collapsed;
  set collapsed(bool value) {
    if (_collapsed == value) return;
    _collapsed = value;
    _save('cortex.ui.sidebarCollapsed', '$value');
    notifyListeners();
  }

  Locale? _locale;
  ThemeMode _theme = ThemeMode.system;
  Locale? get locale => _locale;
  ThemeMode get theme => _theme;
  set locale(Locale? value) {
    _locale = value?.languageCode == 'pt' ? const Locale('pt', 'BR') : value;
    _save(
      'cortex.ui.locale',
      value == null
          ? 'system'
          : value.languageCode == 'pt'
          ? 'pt_BR'
          : value.languageCode,
    );
    notifyListeners();
  }

  set theme(ThemeMode value) {
    _theme = value;
    _save('cortex.ui.theme', value.name);
    notifyListeners();
  }
}

class PreferencesScope extends InheritedNotifier<Preferences> {
  const PreferencesScope({
    super.key,
    required Preferences preferences,
    required super.child,
  }) : super(notifier: preferences);
  static Preferences of(BuildContext context) => maybeOf(context)!;
  static Preferences? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()?.notifier;
}
