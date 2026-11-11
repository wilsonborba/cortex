String? _path;
void save(String path) => _path = path;
String? take() {
  final path = _path;
  _path = null;
  return path;
}
