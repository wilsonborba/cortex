/// Non-web platform (VM tests, native builds): no browser cookie jar
/// exists to read from, so there is never a CSRF cookie here.
String? readCookie(String name) => null;

List<String> cookieNamesPresent() => const [];

void deleteCookie(String name) {}

void reloadPage() {}
