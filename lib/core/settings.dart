class AppSettings {
  AppSettings._();
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT_MODE');
  static const String buildVersion = String.fromEnvironment(
    'BUILD_VERSION',
    defaultValue: '2.2.2',
  );
  static const String cortexApiBaseUrl =
      'https://api.asodya.com/apps/cortex/v1';
  static const String apiForAppsBaseUrl = 'https://api.asodya.com';
  static const String ssoAuthBaseUrl = 'https://auth.asodya.com';
  static const String ssoLoginRoute = '/login';
  static const String appContextQueryParam = 'app_context';
  static const String authExchangeTokenQueryParam = 'auth_exchange_token';
  static const String authSyncPath = '/sync';
  static const String appIdentifier = 'cortex';
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1000;
  static const String appContextFernetKey =
      'mEt5jdm9aTbUYnjhQM_tY_CTQL-JvXe0u9VdKEM2KmY=';
}
