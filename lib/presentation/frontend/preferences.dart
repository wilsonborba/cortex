import 'package:flutter/material.dart';

/// Language and theme switches of the header (24.A.7).
class Preferences extends ChangeNotifier {
  Locale? _locale;
  ThemeMode _theme = ThemeMode.system;
  Locale? get locale => _locale;
  ThemeMode get theme => _theme;
  set locale(Locale? value) {
    _locale = value;
    notifyListeners();
  }

  set theme(ThemeMode value) {
    _theme = value;
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
