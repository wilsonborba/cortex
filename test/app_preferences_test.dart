// Verifies that AppPreferencesController persists the chosen theme mode and
// locale through the real LocalStorageAdapter (backed by shared_preferences'
// mocked in-memory values, so no platform channel is actually touched) and
// restores them on a fresh controller instance, simulating an app restart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cortex/presentation/frontend/handlers/app_preferences_scope.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system theme mode and platform locale', () async {
    final controller = AppPreferencesController();
    await _flushMicrotasks();

    expect(controller.themeMode, ThemeMode.system);
    expect(controller.locale, isNull);
  });

  test('persists a theme mode choice and restores it after "restart"', () async {
    final controller = AppPreferencesController();
    await _flushMicrotasks();

    await controller.setThemeMode(ThemeMode.dark);
    expect(controller.themeMode, ThemeMode.dark);

    // A fresh controller simulates the app restarting: it must read the
    // value back from persisted storage instead of defaulting again.
    final restarted = AppPreferencesController();
    await _flushMicrotasks();

    expect(restarted.themeMode, ThemeMode.dark);
  });

  test('persists a locale choice and restores it after "restart"', () async {
    final controller = AppPreferencesController();
    await _flushMicrotasks();

    await controller.setLocale(const Locale('pt'));
    expect(controller.locale, const Locale('pt'));

    final restarted = AppPreferencesController();
    await _flushMicrotasks();

    expect(restarted.locale, const Locale('pt'));
  });

  test('notifies listeners when the theme mode or locale changes', () async {
    final controller = AppPreferencesController();
    await _flushMicrotasks();

    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setThemeMode(ThemeMode.light);
    await controller.setLocale(const Locale('th'));

    expect(notifications, 2);
  });
}
