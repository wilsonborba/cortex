import 'package:url_launcher/url_launcher.dart';

import '../../core/logs.dart';
import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
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

  /// If [uri] is the `/sync` return route with an `auth_exchange_token`,
  /// redeems it. Returns `true` when a session was established, `false`
  /// when [uri] was not a return route or the exchange failed. Nothing is
  /// persisted locally here: a successful exchange already sets the real
  /// `sid`/`csrf` cookies via `Set-Cookie`, [SessionService.currentStatus]
  /// reads those directly rather than a locally-cached flag.
  Future<bool> tryConsumeReturnUri(Uri uri) async {
    if (uri.path != AppSettings.authSyncPath) return false;

    final token = uri.queryParameters[AppSettings.authExchangeTokenQueryParam];
    if (token == null || token.isEmpty) return false;

    final ok = await _adapter.exchangeToken(token);
    if (!ok) {
      AppLogger.warning('Auth exchange did not establish a session.');
    }
    return ok;
  }

  /// Signs out for real: revokes the session on the backend, clears the
  /// local cookie-based gate, then reloads the page so every piece of
  /// cached app state (conversations, chat handlers, etc.) is torn down
  /// and `SessionGate` re-evaluates from scratch, landing on the sign-in
  /// screen.
  Future<void> signOut() async {
    await _adapter.logout();
    await _sessionService.clear();
    reloadPage();
  }

  String _currentOrigin() {
    final base = Uri.base;
    return base.replace(path: '', query: '', fragment: '').toString();
  }
}
