import '../../core/settings.dart';
import '../../dal/local/local_storage_adapter.dart';
import '../models/session_status.dart';

/// Reads and writes the two client-side flags that decide whether
/// [SessionGate] shows the landing page or the chat screen.
///
/// Neither flag is a real credential: `sessionActive` only means "the
/// `auth_apps` exchange succeeded and the browser should now be holding the
/// `sid` cookie issued by `api_for_apps`", it carries no token itself
/// (the cookie is `httpOnly`, this app cannot read it). `guestMode` is a
/// purely local shortcut with no backend session at all.
class SessionService {
  const SessionService(this._storage);

  final LocalStorageAdapter _storage;

  Future<SessionStatus> currentStatus() async {
    final isAuthenticated = await _storage.readBool(
      AppSettings.sessionActiveStorageKey,
    );
    if (isAuthenticated) return SessionStatus.authenticated;

    final isGuest = await _storage.readBool(AppSettings.guestModeStorageKey);
    if (isGuest) return SessionStatus.guest;

    return SessionStatus.none;
  }

  Future<void> markAuthenticated() async {
    await _storage.writeBool(AppSettings.sessionActiveStorageKey, true);
    await _storage.writeBool(AppSettings.guestModeStorageKey, false);
  }

  Future<void> markGuest() async {
    await _storage.writeBool(AppSettings.guestModeStorageKey, true);
  }

  Future<void> clear() async {
    await _storage.writeBool(AppSettings.sessionActiveStorageKey, false);
    await _storage.writeBool(AppSettings.guestModeStorageKey, false);
  }
}
