import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'browser_history_guard.dart';

class _WebBrowserHistoryGuard implements BrowserHistoryGuard {
  _WebBrowserHistoryGuard(this._listener);

  final web.EventListener _listener;
  bool _consumedByBrowser = false;
  bool _disarmed = false;

  void _markConsumedByBrowser() => _consumedByBrowser = true;

  @override
  void disarm() {
    if (_disarmed) return;
    _disarmed = true;
    web.window.removeEventListener('popstate', _listener);
    // Only consume the dummy entry ourselves when the browser's own back
    // button didn't already do it (screen closed some other way, e.g. an
    // in-app back button) -- calling `back()` a second time after the
    // browser already went back for real would send the user one page
    // further back than intended, exactly the bug this guard exists to fix.
    if (!_consumedByBrowser) {
      web.window.history.back();
    }
  }
}

BrowserHistoryGuard armBrowserHistoryGuard({required void Function() onBack}) {
  web.window.history.pushState(null, '', web.window.location.href);

  late final _WebBrowserHistoryGuard guard;
  final listener = (web.Event _) {
    guard._markConsumedByBrowser();
    onBack();
  }.toJS;
  guard = _WebBrowserHistoryGuard(listener);
  web.window.addEventListener('popstate', listener);
  return guard;
}
