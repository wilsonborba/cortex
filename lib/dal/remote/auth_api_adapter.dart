import 'dart:convert';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../core/logs.dart';
import '../../core/settings.dart';
import '../local/native_session_store.dart';
import 'credentials_client.dart';
import '../../core/utils/csrf.dart';

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

  /// Read only the signed-in email. Other profile fields are discarded.
  Future<String?> currentEmail() async {
    try {
      final response = await _httpClient.get(
        Uri.parse('$apiForAppsBaseUrl/user/info/v1/'),
      );
      if (response.statusCode != 200) return null;
      final data = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['data'];
      final email = data is Map ? data['email'] : null;
      return email is String && email.trim().isNotEmpty ? email.trim() : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> exchangeToken(String token) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$apiForAppsBaseUrl/apps/api/v1/exchange'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'auth_exchange_token': token,
          'app': AppSettings.appIdentifier,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      AppLogger.warning('Auth exchange failed');
      return false;
    }
  }

  /// Starts the FINAL native handoff without contacting the gateway. The
  /// secret and pending handoff remain in OS secure storage while the user
  /// signs in through the system browser.
  Future<NativeLoginAttempt> prepareNativeLogin() async {
    final random = Random.secure();
    final handoffId = _base64Url(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final secretBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final secret = _base64Url(secretBytes);
    final challenge = _base64Url(sha256.convert(secretBytes).bytes);
    final code = _matchCode(base64Url.decode(base64Url.normalize(challenge)));
    final pending = NativeLoginAttempt(
      handoffId: handoffId,
      secret: secret,
      challenge: challenge,
      matchCode: code,
    );
    await const NativeSessionStore().writePendingHandoff(
      jsonEncode({
        'handoff_id': handoffId,
        'secret': secret,
        'challenge': challenge,
      }),
    );
    return pending.copyWith(launchUri: _nativeSsoUri(pending));
  }

  Uri _nativeSsoUri(NativeLoginAttempt attempt) {
    final context = <String, dynamic>{
      'name': 'cortex',
      'platform': 'android',
      'handoff_id': attempt.handoffId,
      'challenge': attempt.challenge,
    };
    final encoded = _encryptAppContext(context);
    return Uri.parse(ssoAuthBaseUrl).replace(
      path: AppSettings.ssoLoginRoute,
      queryParameters: {AppSettings.appContextQueryParam: encoded},
    );
  }

  Future<String> nativeHandoffStatus() async {
    final pending = await _pendingHandoff();
    final response = await _httpClient.post(
      Uri.parse('$apiForAppsBaseUrl/apps/api/v1/exchange'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'app': AppSettings.appIdentifier,
        'handoff_id': pending.handoffId,
        'challenge': pending.challenge,
        'status': true,
      }),
    );
    final body = _handoffBody(response);
    final status = (body['data'] as Map?)?['status'];
    return status is String ? status : 'unknown';
  }

  Future<NativeLoginAttempt?> restoreNativeLogin() async {
    final raw = await const NativeSessionStore().readPendingHandoff();
    if (raw == null) return null;
    final value = (jsonDecode(raw) as Map).cast<String, dynamic>();
    final challenge = value['challenge'] as String;
    return NativeLoginAttempt(
      handoffId: value['handoff_id'] as String,
      secret: value['secret'] as String,
      challenge: challenge,
      matchCode: _matchCode(base64Url.decode(base64Url.normalize(challenge))),
    );
  }

  Future<String?> finishNativeLogin() async {
    final pending = await _pendingHandoff();
    final response = await _httpClient.post(
      Uri.parse('$apiForAppsBaseUrl/apps/api/v1/exchange'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'app': AppSettings.appIdentifier,
        'handoff_id': pending.handoffId,
        'secret': pending.secret,
      }),
    );
    final data = (_handoffBody(response)['data'] as Map)
        .cast<String, dynamic>();
    final sid = data['session_id'];
    final csrf = data['csrf_token'];
    if (sid is! String || csrf is! String) {
      throw const NativeHandoffException('INVALID_RESPONSE', 502);
    }
    await const NativeSessionStore().writeSession(sid: sid, csrf: csrf);
    await const NativeSessionStore().clearPendingHandoff();
    final location = data['location'];
    if (location is Map) {
      final city = location['city'];
      final country = location['country'];
      final countryName = country is String && country.trim().isNotEmpty
          ? await const NativeSessionStore().localizedCountryName(
              country.trim(),
            )
          : null;
      final values = [
        if (city is String && city.trim().isNotEmpty) city.trim(),
        if (countryName != null) countryName,
      ];
      return values.isEmpty ? null : values.join(', ');
    }
    return null;
  }

  Future<void> cancelNativeLogin() async {
    final pending = await _pendingHandoff();
    final response = await _httpClient.post(
      Uri.parse('$apiForAppsBaseUrl/apps/api/v1/exchange'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'app': AppSettings.appIdentifier,
        'handoff_id': pending.handoffId,
        'secret': pending.secret,
        'cancel': true,
      }),
    );
    _handoffBody(response);
    await const NativeSessionStore().clearPendingHandoff();
  }

  Future<void> discardNativeLogin() =>
      const NativeSessionStore().clearPendingHandoff();

  Future<NativeLoginAttempt> _pendingHandoff() async {
    final raw = await const NativeSessionStore().readPendingHandoff();
    if (raw == null) {
      throw const NativeHandoffException('NO_PENDING_LOGIN', 400);
    }
    final value = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return NativeLoginAttempt(
      handoffId: value['handoff_id'] as String,
      secret: value['secret'] as String,
      challenge: value['challenge'] as String,
      matchCode: '',
    );
  }

  Map<String, dynamic> _handoffBody(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)
          .cast<String, dynamic>();
    } catch (_) {
      throw NativeHandoffException('INVALID_RESPONSE', response.statusCode);
    }
    if (response.statusCode >= 400) {
      final data = body['data'];
      final code = data is Map ? data['code'] : null;
      throw NativeHandoffException(
        code is String ? code : 'HANDOFF_FAILED',
        response.statusCode,
      );
    }
    return body;
  }

  String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  String _matchCode(List<int> bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final output = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        output.write(alphabet[(buffer >> bits) & 31]);
        if (output.length == 4) return output.toString();
      }
    }
    return output.toString();
  }

  /// Revokes the gateway session (ported unchanged from v1).
  Future<void> logout() async {
    final uri = Uri.parse('$apiForAppsBaseUrl/user/sync/v1/log-out');
    final csrfToken = readCsrfToken();
    try {
      await _httpClient.post(
        uri,
        headers: {
          if (csrfToken != null && csrfToken.isNotEmpty)
            'X-CSRF-Token': csrfToken,
          if (csrfToken != null && csrfToken.isNotEmpty)
            'X-CSRFToken': csrfToken,
        },
      );
    } catch (e) {
      AppLogger.warning('Logout request failed: $e');
    }
  }
}

class NativeLoginAttempt {
  const NativeLoginAttempt({
    required this.handoffId,
    required this.secret,
    required this.challenge,
    required this.matchCode,
    this.launchUri,
  });
  final String handoffId, secret, challenge, matchCode;
  final Uri? launchUri;

  NativeLoginAttempt copyWith({Uri? launchUri}) => NativeLoginAttempt(
    handoffId: handoffId,
    secret: secret,
    challenge: challenge,
    matchCode: matchCode,
    launchUri: launchUri ?? this.launchUri,
  );
}

class NativeHandoffException implements Exception {
  const NativeHandoffException(this.code, this.statusCode);
  final String code;
  final int statusCode;
}
