import 'csrf_stub.dart' if (dart.library.js_interop) 'csrf_web.dart' as impl;

/// Reads a cookie by name from the browser (issue #16). Mirrors
/// `certifications/lib/dal/local/local_source_adapter.dart`'s `readCookie`
/// exactly: same parsing, same behavior. The real session cookie (`sid`) is
/// httpOnly and intentionally unreadable from Dart; `csrf` is the readable
/// companion cookie `api_for_apps` sets specifically so a CSRF token can be
/// echoed back. Conditionally imported the same way
/// `credentials_client.dart` is, so non-web targets (VM tests) don't try to
/// pull in `package:web`'s browser-only bindings.
String? readCookie(String name) => impl.readCookie(name);

/// The CSRF token every authenticated POST/PUT/PATCH/DELETE to `api_for_apps`
/// must echo back as `X-CSRF-Token` (and `X-CSRFToken`), or `verify_auth`
/// rejects the request with a 403 ("Missing Authentications Parameters").
/// Mirrors `certifications`' `readCsrfToken()` exactly, same mechanism.
String? readCsrfToken() => readCookie('csrf');
