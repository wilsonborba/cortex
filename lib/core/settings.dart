/// Static, non-secret application configuration.
///
/// Anything here is safe to ship in the client bundle. Real secrets never
/// belong in this file, they belong in a `.env` that is not committed.
class AppSettings {
  AppSettings._();

  /// Flips structured logging verbosity. See `lib/core/logs.dart`.
  static const bool isDevelopment = true;

  /// Base URL for the Cortex backend facade itself (cortex_api). The app
  /// never calls this directly for chat/execute traffic (see
  /// [apiForAppsBaseUrl] and [cortexProxyPrefix] below): every chat request
  /// must go through the `api_for_apps` public proxy, which force-locks
  /// model/tier to Tier 0 server-side (api_for_apps issue #19).
  ///
  /// This value is only used for [cortexLogsWebSocketUrl]: api_for_apps'
  /// proxy is a plain HTTP forwarder (`httpx.AsyncClient` request/response),
  /// it has no WebSocket upgrade support, so live log streaming cannot be
  /// carried through it. Connecting straight to cortex_api's websocket is a
  /// documented local-dev-only shortcut, gated by [enableLiveLogStreaming].
  static const String cortexApiBaseUrl = 'http://127.0.0.1:8003';

  /// Prefix `api_for_apps` mounts its public Cortex proxy under (see its
  /// `src/presentation/routes/cortex_route.py`, `cortex_proxy_v1 =
  /// APIRouter(prefix="/cortex/v1")`). Every path segment after this prefix
  /// is forwarded as-is to cortex_api, so `POST` to
  /// `$apiForAppsBaseUrl$cortexProxyPrefix/v1/chat/completions` reaches
  /// cortex_api's own `POST /v1/chat/completions` (the "double v1" is real,
  /// not a typo: one `/v1` is the proxy mount, the other is cortex_api's own
  /// OpenAI-facade router prefix), and `$cortexProxyPrefix/execute` reaches
  /// cortex_api's native `POST /execute`.
  static const String cortexProxyPrefix = '/cortex/v1';

  /// Virtual model name that is always forced Tier 0. The proxy rewrites
  /// `model` to this value server-side regardless of what is sent (see
  /// `sanitize_cortex_payload` in api_for_apps), so the client sends it only
  /// to be explicit and never offers any other model in its UI.
  static const String cortexTier0Model = 'cortex-t0';

  /// Local-dev-only flag: when true, [cortexLogsWebSocketUrl] is reachable
  /// and the debug telemetry panel may attempt to connect. api_for_apps'
  /// proxy cannot carry a WebSocket upgrade (see [cortexApiBaseUrl]'s doc),
  /// so this always points straight at cortex_api and must stay off (or the
  /// panel must stay hidden) outside local development.
  static const bool enableLiveLogStreaming = isDevelopment;

  /// Direct WebSocket URL for cortex_api's `/logs/stream` (see its
  /// `lib/presentation/api/routes/logs_stream.py`). Bypasses api_for_apps
  /// entirely: this is a local-dev-only shortcut, not a production path, see
  /// [enableLiveLogStreaming].
  static String get cortexLogsWebSocketUrl =>
      '${cortexApiBaseUrl.replaceFirst('http', 'ws')}/logs/stream';

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
