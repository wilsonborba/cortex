import 'package:web/web.dart' as web;

String? readCookie(String name) {
  final cookies = web.document.cookie;
  if (cookies.isEmpty) return null;

  for (final cookie in cookies.split(';')) {
    final parts = cookie.trim().split('=');
    if (parts.length == 2 && parts[0] == name) {
      return parts[1];
    }
  }
  return null;
}

/// Best-effort client-side sign-out signal: expires the readable `csrf`
/// cookie so `SessionService.currentStatus` stops seeing this browser as
/// authenticated. The real `sid` cookie is httpOnly and can't be cleared
/// from Dart; a full sign-out still needs a backend call to actually
/// invalidate the Redis session, this only clears the local gate check.
void deleteCookie(String name) {
  web.document.cookie = '$name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
}
