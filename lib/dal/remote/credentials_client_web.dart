import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// On web, cross-origin `fetch` calls drop cookies unless `withCredentials`
/// is set. `api_for_apps` sets the `sid` session cookie on the `/v1/exchange`
/// response, so without this the browser would silently discard it.
http.Client createCredentialsClient() =>
    BrowserClient()..withCredentials = true;
