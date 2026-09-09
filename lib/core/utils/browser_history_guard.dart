import 'browser_history_guard_stub.dart' if (dart.library.js_interop) 'browser_history_guard_web.dart' as impl;

/// Makes one browser back-button press close an in-app overlay screen
/// (e.g. [MemoryGraphScreen]) instead of leaving the single-page app
/// entirely.
///
/// This app has no named routes (`MaterialApp(home: SessionGate(...))`,
/// see `app.dart`) and pushes screens with a plain
/// `Navigator.push(MaterialPageRoute(...))`, which never touches the
/// browser's own history stack. On web, pressing the browser's back button
/// therefore doesn't pop the Flutter [Navigator] at all -- it navigates the
/// *browser* to whatever real page it had in history before this app's
/// current URL was ever loaded, which can be an arbitrary old page (issue:
/// "quando clico pra voltar no browser ele vai pra uma pagina muito
/// antiga"), not this app's chat screen.
///
/// [arm] pushes one dummy history entry (same URL, just a new state marker)
/// the moment an overlay screen opens, and registers [onBack] to fire on
/// the browser's `popstate` event; that first back-press just consumes the
/// dummy entry and calls [onBack] instead of ever leaving the app. Call the
/// returned disarm function when the screen is popped normally (e.g. by an
/// in-app back button) so the dummy entry doesn't linger for a *second*
/// back-press to hit. A no-op everywhere but web (VM tests, native builds
/// have no browser history to guard).
BrowserHistoryGuard armBrowserHistoryGuard({required void Function() onBack}) {
  return impl.armBrowserHistoryGuard(onBack: onBack);
}

/// Disarms a guard started by [armBrowserHistoryGuard]: stops listening for
/// `popstate` and, if the dummy entry armed is still the current history
/// state, consumes it via a same-effect real `back()` so it doesn't linger.
abstract class BrowserHistoryGuard {
  void disarm();
}
