import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:http/http.dart' as http;

import '../../core/logs.dart';
import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../domain/services/client_telemetry_service.dart';
import 'credentials_client.dart';

/// Remote adapter for Asodya's unified authentication:
/// - builds the SSO redirect URL that hands `auth_apps` an encrypted
///   `app_context` (same Fernet scheme `auth_apps` decrypts with
///   `FernetService.decryptPayload`, see its
///   `lib/domain/services/fernet_service.dart`);
/// - exchanges the `auth_exchange_token` that `auth_apps` sends back with
///   `api_for_apps`' `POST /v1/exchange` (see its
///   `src/presentation/routes/exchange_auth_app_route.py`), which sets the
///   `sid` session cookie.
///
/// No token is ever returned to the domain layer: the exchange response
/// carries the session as an `httpOnly` cookie the browser manages on its
/// own, this adapter only reports whether the exchange succeeded.
class AuthApiAdapter {
  AuthApiAdapter({
    this.ssoAuthBaseUrl = AppSettings.ssoAuthBaseUrl,
    this.apiForAppsBaseUrl = AppSettings.apiForAppsBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? createCredentialsClient();

  final String ssoAuthBaseUrl;
  final String apiForAppsBaseUrl;
  final http.Client _httpClient;

  /// Builds the URL Cortex should redirect the browser to in order to start
  /// an `auth_apps` login/signup, carrying an encrypted `app_context` that
  /// tells `auth_apps` which app is asking and where to send the user back.
  ///
  /// [returnOrigin] must be this app's own origin (e.g. `Uri.base.origin`):
  /// `auth_apps` will redirect to `<returnOrigin>/sync?auth_exchange_token=`
  /// once login completes.
  Uri buildSsoRedirectUri({required String returnOrigin}) {
    final appContext = <String, dynamic>{
      'name': 'Cortex',
      'description':
          'Intelligent neural workspace with autonomous multi-agent reasoning, deep research, and high-performance workflow execution.',
      'logo_image_url':
          'https://res.cloudinary.com/dhncdmb2t/image/upload/v1761907623/temp_logo_tw3grt.png',
      'url_app': returnOrigin,
      'two_fa_auth': false,
      'primary_color': '#0D0D0D',
      'secondary_color': '#1A1A1A',
      'tertiary_color': '#FFFFFF',
      'quartary_color': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    final encryptedAppContext = _encryptAppContext(appContext);

    final base = Uri.parse(ssoAuthBaseUrl);
    return base.replace(
      path: AppSettings.ssoLoginRoute,
      queryParameters: {AppSettings.appContextQueryParam: encryptedAppContext},
    );
  }

  String _encryptAppContext(Map<String, dynamic> appContext) {
    final key = encrypt.Key.fromBase64(AppSettings.appContextFernetKey);
    final fernet = encrypt.Fernet(key);
    final encrypter = encrypt.Encrypter(fernet);
    final payload = jsonEncode(appContext);
    return encrypter.encrypt(payload).base64;
  }

  /// Redeems a short-lived `auth_exchange_token` (received on the `/sync`
  /// return route) for a real session. On success `api_for_apps` sets the
  /// `sid` cookie via `Set-Cookie`; this method reports only success/failure.
  Future<bool> exchangeToken(String authExchangeToken) async {
    final uri = Uri.parse('$apiForAppsBaseUrl/apps/api/v1/exchange');
    try {
      final response = await _httpClient.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_exchange_token': authExchangeToken,
          'app': AppSettings.appIdentifier,
        }),
      );
      if (response.statusCode == 200) {
        // Diagnostic only (issue #21): confirm whether sid/csrf actually
        // landed in the browser's cookie jar right after a successful
        // exchange, without needing anyone to open DevTools manually.
        ClientTelemetryService.instance.reportHandledError(
          title: 'Auth Exchange Cookie Diagnostic',
          error: 'diagnostic, not an error',
          errorCode: 'AUTH_EXCHANGE_COOKIE_DIAGNOSTIC',
          route: AppSettings.authSyncPath,
          details: {
            'cookie_names_present': cookieNamesPresent(),
            'response_headers': response.headers.keys.toList(),
            'has_set_cookie_header': response.headers.containsKey('set-cookie'),
          },
        );
        return true;
      }
      AppLogger.warning(
        'Auth exchange failed with status ${response.statusCode}: '
        '${response.body}',
      );
      ClientTelemetryService.instance.reportHandledError(
        title: 'Auth Exchange Failed',
        error: 'HTTP ${response.statusCode}',
        errorCode: 'AUTH_EXCHANGE_${response.statusCode}',
        route: AppSettings.authSyncPath,
        details: {
          'status_code': response.statusCode,
          'response_body': response.body,
          'exchange_uri': uri.toString(),
        },
      );
      return false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Auth exchange request failed',
        error: e,
        stackTrace: stackTrace,
      );
      ClientTelemetryService.instance.reportHandledError(
        title: 'Auth Exchange Request Failed',
        error: e,
        stackTrace: stackTrace,
        errorCode: 'AUTH_EXCHANGE_EXCEPTION',
        route: AppSettings.authSyncPath,
        details: {'exchange_uri': uri.toString()},
      );
      return false;
    }
  }

  /// Fetches the logged-in user's info from `api_for_apps` (`GET
  /// /user/info/v1/`), authenticated by the `sid` session cookie same as
  /// every other call. Returns `null` on any failure (no session, network
  /// error, unexpected shape): callers should fall back to not showing a
  /// name/email rather than blocking on this.
  Future<Map<String, dynamic>?> fetchUserInfo() async {
    final uri = Uri.parse('$apiForAppsBaseUrl/user/info/v1/');
    try {
      final response = await _httpClient.get(uri);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      return null;
    } catch (e) {
      AppLogger.warning('Failed to fetch user info: $e');
      return null;
    }
  }

  /// Revokes the session on the backend (`POST /user/sync/v1/log-out`):
  /// deletes the Redis-side session and clears the `sid`/`csrf` cookies via
  /// `Set-Cookie`. Best-effort: even on failure, the caller still clears
  /// what it can locally (see `SessionService.clear`).
  Future<void> logout() async {
    final uri = Uri.parse('$apiForAppsBaseUrl/user/sync/v1/log-out');
    final csrfToken = readCsrfToken();
    try {
      await _httpClient.post(
        uri,
        headers: {
          if (csrfToken != null && csrfToken.isNotEmpty) 'X-CSRF-Token': csrfToken,
          if (csrfToken != null && csrfToken.isNotEmpty) 'X-CSRFToken': csrfToken,
        },
      );
    } catch (e) {
      AppLogger.warning('Logout request failed: $e');
    }
  }
}
