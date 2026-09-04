import 'package:http/http.dart' as http;

import 'credentials_client_stub.dart'
    if (dart.library.js_interop) 'credentials_client_web.dart'
    as impl;

/// An [http.Client] configured to carry cookies on web, where that must be
/// requested explicitly. See `credentials_client_web.dart`.
http.Client createCredentialsClient() => impl.createCredentialsClient();
