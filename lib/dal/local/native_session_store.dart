import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

/// Secrets used by the Android installed-app login and gateway session.
/// flutter_secure_storage protects these values with the Android Keystore.
class NativeSessionStore {
  const NativeSessionStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  static const _sidKey = 'cortex.native.sid';
  static const _csrfKey = 'cortex.native.csrf';
  static const _pendingKey = 'cortex.native.pending_handoff';
  static const _platform = MethodChannel('com.asodya.cortex/native');

  Future<String> localizedCountryName(String countryCode) async {
    try {
      final name = await _platform.invokeMethod<String>(
        'localizedCountryName',
        {'countryCode': countryCode},
      );
      if (name != null && name.trim().isNotEmpty) return name;
    } on PlatformException {
      // Fall back to the ISO country code when localization is unavailable.
    } on MissingPluginException {
      // Non-Android targets keep the API-provided ISO code.
    }
    return countryCode;
  }

  Future<String?> readSessionId() async {
    final val = await _storage.read(key: _sidKey);
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  Future<String?> readCsrfToken() async {
    final val = await _storage.read(key: _csrfKey);
    return (val != null && val.trim().isNotEmpty) ? val.trim() : null;
  }

  Future<void> writeSession({required String sid, required String csrf}) async {
    final cleanSid = sid.trim();
    final cleanCsrf = csrf.trim();
    if (cleanSid.isEmpty || cleanCsrf.isEmpty) {
      throw const FormatException('Session ID and CSRF token must not be empty');
    }
    try {
      await clearSession();
    } catch (e) {
      throw e is Exception ? e : Exception(e.toString());
    }
    try {
      await _storage.write(key: _sidKey, value: cleanSid);
      await _storage.write(key: _csrfKey, value: cleanCsrf);
    } catch (_) {
      await clearSession().catchError((_) {});
      rethrow;
    }
  }

  Future<void> clearSession() async {
    Object? firstError;
    try {
      await _storage.delete(key: _sidKey);
    } catch (e) {
      firstError = e;
    }
    try {
      await _storage.delete(key: _csrfKey);
    } catch (e) {
      firstError ??= e;
    }
    if (firstError != null) {
      throw firstError;
    }
  }

  Future<String?> readPendingHandoff() => _storage.read(key: _pendingKey);
  Future<void> writePendingHandoff(String value) =>
      _storage.write(key: _pendingKey, value: value);
  Future<void> clearPendingHandoff() => _storage.delete(key: _pendingKey);
}
