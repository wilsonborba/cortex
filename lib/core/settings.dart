/// Static, non-secret application configuration.
///
/// Anything here is safe to ship in the client bundle. Real secrets never
/// belong in this file, they belong in a `.env` that is not committed.
class AppSettings {
  AppSettings._();

  /// Flips structured logging verbosity. See `lib/core/logs.dart`.
  static const bool isDevelopment = true;

  /// Base URL for the Cortex backend facade. Not wired to any network call
  /// yet, this is only the configuration point that issue #3 (backend
  /// integration) will consume.
  static const String cortexApiBaseUrl = 'http://127.0.0.1:8003';

  /// Default access tier for a freshly opened session. Tier 0 is the only
  /// tier implemented so far: free and fast models, no premium features.
  static const int defaultTier = 0;

  /// Breakpoint, in logical pixels, below which the app is considered a
  /// mobile / touch layout instead of a desktop split-view layout.
  static const double mobileBreakpoint = 720;

  // --- Asodya unified authentication (auth_apps SSO), issue #4 ---

  /// Base URL of the `auth_apps` login portal Cortex redirects to for SSO.
  /// Mirrors the dev/prod split `auth_apps`/`api_for_apps` already use for
  /// the same LAN host (see their `core/settings`).
  static const String ssoAuthBaseUrl = isDevelopment
      ? 'http://192.168.1.103:8100'
      : 'https://auth.asodya.com';

  /// Route on the `auth_apps` portal that starts a login/signup session.
  static const String ssoLoginRoute = '/login';

  /// Base URL of `api_for_apps`, the gateway that exchanges a short-lived
  /// `auth_exchange_token` for a real session (`POST /v1/exchange`, sets the
  /// `sid` cookie). Distinct from [cortexApiBaseUrl]: that one is the direct
  /// Cortex model-serving facade, this one is Asodya's shared auth/session
  /// gateway.
  static const String apiForAppsBaseUrl = isDevelopment
      ? 'http://192.168.1.103:8101'
      : 'https://api.asodya.com';

  /// Path this app is redirected back to once `auth_apps` finishes login,
  /// with `?auth_exchange_token=<token>` appended. Must match what
  /// `auth_apps` builds in `AppContextService.buildReturnUri` (always
  /// `<origin>/sync`).
  static const String authSyncPath = '/sync';

  /// Query params, shared by contract with `auth_apps` / `api_for_apps`.
  static const String appContextQueryParam = 'app_context';
  static const String authExchangeTokenQueryParam = 'auth_exchange_token';

  /// Identifier this client sends as `app` in the app context and the
  /// `/v1/exchange` call, so the backend can tell which app is authenticating.
  static const String appIdentifier = 'cortex';

  /// Fernet key used to encrypt the `app_context` query param that `auth_apps`
  /// decrypts on the other end. This is the same symmetric key `auth_apps`
  /// ships in its own client bundle (see its `core/settings.dart`): a Flutter
  /// web build cannot hide a client-side value from the browser anyway, so it
  /// lives here as shared non-secret app config rather than in `.env`, exactly
  /// like the base URLs above.
  static const String appContextFernetKey =
      'mEt5jdm9aTbUYnjhQM_tY_CTQL-JvXe0u9VdKEM2KmY=';

  /// Local storage keys used by the session/guest flags (see
  /// `SessionService` and `AuthService`).
  static const String sessionActiveStorageKey = 'session_active';
  static const String guestModeStorageKey = 'guest_mode';
}
