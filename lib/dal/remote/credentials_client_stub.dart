import 'package:http/http.dart' as http;

/// Non-web platforms have no browser cookie jar to opt into: a plain client
/// already sends whatever the platform's HTTP stack manages.
http.Client createCredentialsClient() => http.Client();
