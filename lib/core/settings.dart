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
}
