import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

/// SSE needs fetch on web: the default BrowserClient gives the whole stream at
/// the end (24.J.1). Cookies go with the request (gateway session).
http.Client createStreamClient() =>
    FetchClient(mode: RequestMode.cors, credentials: RequestCredentials.cors);
