import '../../core/settings.dart';
import '../../dal/local/local_storage_adapter.dart';
import '../models/session_status.dart';

/// Reads and writes the authenticated session flag for [SessionGate].
class SessionService {
  const SessionService(this._storage);

  final LocalStorageAdapter _storage;

  Future<SessionStatus> currentStatus() async {
    final isAuthenticated = await _storage.readBool(
      AppSettings.sessionActiveStorageKey,
    );
    if (isAuthenticated) return SessionStatus.authenticated;

    return SessionStatus.none;
  }

  Future<void> markAuthenticated() async {
    await _storage.writeBool(AppSettings.sessionActiveStorageKey, true);
  }

  Future<void> clear() async {
    await _storage.writeBool(AppSettings.sessionActiveStorageKey, false);
  }
}
