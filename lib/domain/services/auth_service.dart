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
