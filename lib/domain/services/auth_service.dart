import 'package:url_launcher/url_launcher.dart';

import '../../core/logs.dart';
import '../../core/settings.dart';
import '../../dal/remote/auth_api_adapter.dart';
import 'session_service.dart';

/// Orchestrates the Asodya unified authentication (`auth_apps`) flow.
///
/// The widgets never talk to [AuthApiAdapter] or [SessionService] directly:
/// they call into this service, which owns the sequencing:
/// 1. [signInWithSso] builds the redirect URL and opens `auth_apps`.
/// 2. `auth_apps` redirects back to `<origin>/sync?auth_exchange_token=...`.
/// 3. [tryConsumeReturnUri] (called once at startup) recognizes that route,
///    redeems the token via `/v1/exchange`, and persists the resulting
///    session flag locally.
///
/// [continueAsGuest] is the other, much simpler path: a purely client-side
/// flag with no server round trip at all (see [SessionService] doc comment).
class AuthService {
  AuthService(this._adapter, this._sessionService);

  final AuthApiAdapter _adapter;
  final SessionService _sessionService;

  /// Builds the SSO redirect URL and opens it in the same browser
  /// tab/window, so the eventual `auth_apps` -> `/sync` redirect lands back
  /// in the same session storage this app reads from.
  Future<void> signInWithSso() async {
    final returnOrigin = _currentOrigin();
    final redirectUri = _adapter.buildSsoRedirectUri(
      returnOrigin: returnOrigin,
    );
    AppLogger.info('Redirecting to auth_apps SSO at $redirectUri');
    await launchUrl(
      redirectUri,
      webOnlyWindowName: '_self',
      mode: LaunchMode.platformDefault,
    );
  }

  /// Client-side-only guest mode: no `auth_apps`/`api_for_apps` call is made.
  /// Neither service has a concept of an anonymous session, so this only
  /// sets a local flag that [SessionGate] treats as "may enter chat". Any
  /// backend request made afterward relies on the `api_for_apps` public,
  /// login-free `/cortex/v1/*` proxy (issue #3), not on a real session.
  Future<void> continueAsGuest() async {
    await _sessionService.markGuest();
  }

  /// If [uri] is the `/sync` return route with an `auth_exchange_token`,
  /// redeems it and persists the session. Returns `true` when a session was
  /// established, `false` when [uri] was not a return route or the exchange
  /// failed (nothing is persisted in that case).
  Future<bool> tryConsumeReturnUri(Uri uri) async {
    if (uri.path != AppSettings.authSyncPath) return false;

    final token = uri.queryParameters[AppSettings.authExchangeTokenQueryParam];
    if (token == null || token.isEmpty) return false;

    final ok = await _adapter.exchangeToken(token);
    if (ok) {
      await _sessionService.markAuthenticated();
    } else {
      AppLogger.warning('Auth exchange did not establish a session.');
    }
    return ok;
  }

  Future<void> signOut() => _sessionService.clear();

  String _currentOrigin() {
    final base = Uri.base;
    return base.replace(path: '', query: '', fragment: '').toString();
  }
}
