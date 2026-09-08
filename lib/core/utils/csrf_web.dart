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
