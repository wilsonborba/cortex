import 'package:web/web.dart' as web;

const _key = 'cortex_return_path';
void save(String path) => web.window.sessionStorage.setItem(_key, path);
String? take() {
  final path = web.window.sessionStorage.getItem(_key);
  web.window.sessionStorage.removeItem(_key);
  return path;
}
