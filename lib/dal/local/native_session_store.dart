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

  Future<String?> readSessionId() => _storage.read(key: _sidKey);
  Future<String?> readCsrfToken() => _storage.read(key: _csrfKey);

  Future<void> writeSession({required String sid, required String csrf}) async {
    await _storage.write(key: _sidKey, value: sid);
    await _storage.write(key: _csrfKey, value: csrf);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sidKey);
    await _storage.delete(key: _csrfKey);
  }

  Future<String?> readPendingHandoff() => _storage.read(key: _pendingKey);
  Future<void> writePendingHandoff(String value) =>
      _storage.write(key: _pendingKey, value: value);
  Future<void> clearPendingHandoff() => _storage.delete(key: _pendingKey);
}
