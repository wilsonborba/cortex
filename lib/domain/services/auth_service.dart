import 'package:url_launcher/url_launcher.dart';
import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../core/utils/return_path.dart';
import '../../dal/remote/auth_api_adapter.dart';
import 'session_service.dart';

class AuthService {
  AuthService(this.adapter, {this.session = const SessionService()});
  final AuthApiAdapter adapter;
  final SessionService session;

  /// Starts the SSO login. [returnPath] is the page to open after the login
  /// (28.2); the SSO itself always returns to /sync.
  Future<void> signIn({String? returnPath}) async {
    if (returnPath != null) saveReturnPath(returnPath);
    await launchUrl(
      adapter.buildSsoRedirectUri(returnOrigin: Uri.base.origin),
      webOnlyWindowName: '_self',
    );
  }

  Future<NativeLoginAttempt> startNativeLogin() async {
    final attempt = await adapter.prepareNativeLogin();
    final uri = attempt.launchUri;
    try {
      if (uri == null ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open the sign-in page');
      }
    } catch (_) {
      try {
        await adapter.cancelNativeLogin();
      } catch (_) {
        await adapter.discardNativeLogin();
      }
      rethrow;
    }
    return attempt;
  }

  Future<String?> finishNativeLogin() => adapter.finishNativeLogin();
  Future<String> checkNativeLogin() => adapter.nativeHandoffStatus();
  Future<void> cancelNativeLogin() => adapter.cancelNativeLogin();
  Future<void> discardNativeLogin() => adapter.discardNativeLogin();
  Future<NativeLoginAttempt?> restoreNativeLogin() =>
      adapter.restoreNativeLogin();

  Future<bool> consumeReturn(Uri uri) async {
    final token = uri.queryParameters[AppSettings.authExchangeTokenQueryParam];
    return token != null &&
        token.isNotEmpty &&
        await adapter.exchangeToken(token);
  }

  /// Revokes the session, clears the readable cookie and reloads (ported from v1).
  Future<void> signOut() async {
    await adapter.logout();
    await session.clear();
    reloadPage();
  }
}
