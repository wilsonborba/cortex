import 'dart:js_interop';
import 'package:web/web.dart' as web;

bool get browserOnline => web.window.navigator.onLine;
Stream<bool> get onlineChanges => Stream.multi((controller) {
  void changed(web.Event event) => controller.add(browserOnline);
  final handler = changed.toJS;
  web.window.addEventListener('online', handler);
  web.window.addEventListener('offline', handler);
  controller.onCancel = () {
    web.window.removeEventListener('online', handler);
    web.window.removeEventListener('offline', handler);
  };
});
