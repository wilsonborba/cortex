import 'online_stub.dart'
    if (dart.library.js_interop) 'online_web.dart'
    as impl;

bool get browserOnline => impl.browserOnline;
Stream<bool> get onlineChanges => impl.onlineChanges;
