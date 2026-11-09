import 'package:url_launcher/url_launcher.dart';
import '../../core/settings.dart';
import '../../dal/remote/auth_api_adapter.dart';

class AuthService {
  AuthService(this.adapter);
  final AuthApiAdapter adapter;
  Future<void> signIn() async {
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
}
