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

/// Diagnostic only (issue #21): the *names* of every cookie the browser
/// currently has for this origin (never values, `csrf`'s value isn't
/// sensitive but no need to ship it either), so a report sent right after
/// the exchange call can show whether `sid`/`csrf` actually landed in the
/// browser's cookie jar, without needing anyone to open DevTools manually.
List<String> cookieNamesPresent() {
  final cookies = web.document.cookie;
  if (cookies.isEmpty) return const [];
  return cookies
      .split(';')
      .map((c) => c.trim().split('=').first)
      .where((name) => name.isNotEmpty)
      .toList();
}

/// Best-effort client-side sign-out signal: expires the readable `csrf`
/// cookie so `SessionService.currentStatus` stops seeing this browser as
/// authenticated. The real `sid` cookie is httpOnly and can't be cleared
/// from Dart; a full sign-out still needs a backend call to actually
/// invalidate the Redis session, this only clears the local gate check.
void deleteCookie(String name) {
  web.document.cookie = '$name=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
}

/// Full page reload: used right after sign-out so every piece of in-memory
/// app state (SessionGate's cached status, ChatService's conversations,
/// etc.) is torn down and rebuilt fresh against the now-cleared session,
/// rather than trying to reset each of them by hand.
void reloadPage() => web.window.location.reload();
