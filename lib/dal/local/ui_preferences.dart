import 'ui_preferences_stub.dart'
    if (dart.library.js_interop) 'ui_preferences_web.dart'
    as platform;

/// Stores non-secret display preferences only.
class UiPreferenceStore {
  const UiPreferenceStore();
  String? read(String key) {
    try {
      return platform.read(key);
    } catch (_) {
      return null;
    }
  }

  void write(String key, String value) {
    try {
      platform.write(key, value);
    } catch (_) {}
  }
}
