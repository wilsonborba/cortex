import 'return_path_stub.dart'
    if (dart.library.js_interop) 'return_path_web.dart'
    as impl;

/// The path a signed-out visitor wanted (28.2). The SSO returns to /sync, so the
/// path is kept in sessionStorage across the redirect.
void saveReturnPath(String path) => impl.save(path);

/// Reads and removes the saved path.
String? takeReturnPath() => impl.take();
