/// Static, non-secret application configuration.
///
/// Anything here is safe to ship in the client bundle. Real secrets never
/// belong in this file, they belong in a `.env` that is not committed.
class AppSettings {
  AppSettings._();

  /// Flips structured logging verbosity and local LAN endpoint routing.
  /// Defaults to false (production / live Asodya cloud endpoints).
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT_MODE', defaultValue: false);

  /// Build / deployment timestamp displayed in footers and info views
  static const String buildVersion = String.fromEnvironment(
    'BUILD_TIMESTAMP',
    defaultValue: '2026-09-08 23:50 +07',
  );

  /// Prefix `api_for_apps` mounts its apps proxy under (/apps/cortex/v1).
  static const String cortexProxyPrefix = '/apps/cortex/v1';

  /// Virtual model name that is always forced Tier 0. The proxy rewrites
  /// `model` to this value server-side regardless of what is sent (see
  /// `sanitize_cortex_payload` in api_for_apps), so the client sends it only
  /// to be explicit and never offers any other model in its UI.
  static const String cortexTier0Model = 'cortex-t0';

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
  /// `sid` cookie).
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

  // --- X-Asodya-App-Proof attestation (api_for_apps issue #19, cortex
  // issue #8) ---

  /// Shared HMAC secret used to compute the `X-Asodya-App-Proof` header
  /// that lets the official Web App bypass api_for_apps' 5-requests/day
  /// guest quota (see `cortex_attestation_handler.py` in api_for_apps,
  /// read-only reference). Read from a compile-time `--dart-define`, never
  /// hardcoded: CI/CD must build with
  /// `flutter build web --dart-define=CORTEX_PROOF_SECRET=<value>`, where
  /// `<value>` matches `CORTEX_PROOF_SECRET` in the target deployment's
  /// api_for_apps `.env`. Left empty by default (local dev, or any build
  /// that omits the define), in which case the header is simply omitted and
  /// the request falls back to the unproven-traffic quota: nothing breaks.
  ///
  /// This is not meant to be cryptographically strong: any secret baked
  /// into a Flutter web bundle is extractable by a determined reader. Its
  /// only purpose is to distinguish the shipped official bundle from ad hoc
  /// scripts/curl/Postman traffic, matching api_for_apps#19's stated intent.
  static const String cortexProofSecret = String.fromEnvironment(
    'CORTEX_PROOF_SECRET',
    defaultValue: '',
  );



  /// App identifier included in the attestation HMAC message. Must match
  /// api_for_apps' `CORTEX_APP_ID` setting for this deployment, which
  /// defaults server-side to `cortex_web_app` (see api_for_apps'
  /// `src/core/settings.py`, read-only reference), so this default mirrors
  /// that. Overridable via `--dart-define` for deployments that register a
  /// different app id.
  static const String cortexAppId = String.fromEnvironment(
    'CORTEX_APP_ID',
    defaultValue: 'cortex_web_app',
  );
}
