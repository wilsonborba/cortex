import 'dart:developer' as developer;

import 'settings.dart';

/// Minimal structured logger with four levels: debug, info, warning, error.
///
/// When `AppSettings.isDevelopment` is true every level is emitted. When it
/// is false, `debug` is suppressed and only info/warning/error are emitted,
/// so noisy diagnostics never reach a production build.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String name = 'cortex'}) {
    if (!AppSettings.isDevelopment) return;
    developer.log(message, name: name, level: 500);
  }

  static void info(String message, {String name = 'cortex'}) {
    developer.log(message, name: name, level: 800);
  }

  static void warning(String message, {String name = 'cortex'}) {
    developer.log(message, name: name, level: 900);
  }

  static void error(
    String message, {
    String name = 'cortex',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
