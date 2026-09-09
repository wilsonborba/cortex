import 'browser_history_guard.dart';

class _NoopBrowserHistoryGuard implements BrowserHistoryGuard {
  @override
  void disarm() {}
}

/// Non-web platform (VM tests, native builds): no browser history to guard.
BrowserHistoryGuard armBrowserHistoryGuard({required void Function() onBack}) {
  return _NoopBrowserHistoryGuard();
}
