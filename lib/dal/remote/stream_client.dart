import 'package:http/http.dart' as http;
import 'stream_client_stub.dart'
    if (dart.library.js_interop) 'stream_client_web.dart'
    as impl;

http.Client createStreamClient() => impl.createStreamClient();
