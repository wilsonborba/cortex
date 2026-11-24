import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();

/// Native requests carry the gateway session obtained from the installed-app
/// handoff. The values are read from Android Keystore-backed storage for each
/// request and are never copied into preferences or logs.
class _NativeCredentialsClient extends http.BaseClient {
  _NativeCredentialsClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    String? sid;
    String? csrf;
    try {
      sid = await _secureStorage.read(key: 'cortex.native.sid');
      csrf = await _secureStorage.read(key: 'cortex.native.csrf');
    } catch (_) {
      // Continue without credentials if secure storage is unavailable.
    }
    if (sid != null && csrf != null) {
      request.headers['Cookie'] = 'sid=$sid; csrf=$csrf';
      if (request.method != 'GET' && request.method != 'HEAD') {
        request.headers['X-CSRF-Token'] = csrf;
        request.headers['X-CSRFToken'] = csrf;
      }
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

/// Non-web platforms have no browser cookie jar to opt into: a plain client
/// is wrapped to attach the Android native session when one exists.
http.Client createCredentialsClient() =>
    _NativeCredentialsClient(http.Client());
