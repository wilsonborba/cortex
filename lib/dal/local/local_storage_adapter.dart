import 'package:shared_preferences/shared_preferences.dart';

/// Generic local persistence adapter built on `shared_preferences`.
///
/// Domain services depend on this instead of talking to
/// `shared_preferences` directly, so the storage backend can be swapped
/// (IndexedDB on web today, something else tomorrow) without touching the
/// domain layer.
class LocalStorageAdapter {
  const LocalStorageAdapter();

  Future<String?> readString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> writeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
