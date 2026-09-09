import '../../core/utils/csrf.dart';
import '../models/session_status.dart';

/// Reads the authenticated session state for [SessionGate].
///
/// Previously this trusted a `session_active` flag written to
/// `localStorage` once at login and never re-checked, so a session that
/// expired or was revoked server-side (Redis TTL, logout elsewhere) was
/// invisible: the app kept showing the chat screen while every real request
/// to `api_for_apps` 403'd with "Missing session cookie". Fixed to match
/// `certifications`' pattern exactly: the real session cookie (`sid`) is
/// httpOnly and unreadable from Dart, but `api_for_apps` also sets a
/// readable, non-httpOnly `csrf` cookie alongside it whenever a session is
/// established. Checking that cookie's presence (via [readCsrfToken],
/// already used for the CSRF header fix) is a live check against the actual
/// browser cookie jar, not a cached local flag, so it correctly reflects
/// logout/expiry instead of a memory of the last successful login.
class SessionService {
  /// [cookieReader] is injectable for tests only (VM widget tests have no
  /// real browser cookie jar to read, `readCsrfToken` always returns null
  /// there): defaults to the real `csrf` cookie check used in production.
  const SessionService({String? Function()? cookieReader})
    : _readSessionCookie = cookieReader ?? readCsrfToken;

  final String? Function() _readSessionCookie;

  Future<SessionStatus> currentStatus() async {
    final csrfToken = _readSessionCookie();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      return SessionStatus.authenticated;
    }
    return SessionStatus.none;
  }

  /// Best-effort local sign-out signal (see `deleteCookie`'s doc comment):
  /// clears the readable cookie so [currentStatus] stops reporting this
  /// browser as authenticated. Not currently wired to any UI (no sign-out
  /// button exists yet, tracked separately), kept for when one is added.
  Future<void> clear() async {
    deleteCookie('csrf');
  }
}
