import 'platform_stub.dart'
    if (dart.library.js_interop) 'platform_web.dart'
    as impl;

bool get isAndroidPlatform => impl.isAndroidPlatform;
