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
