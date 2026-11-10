import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'file_picker.dart';

Future<List<PickedFile>> pickFiles() async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..multiple = true;
  final picked = Completer<List<PickedFile>>();
  input.onchange = (web.Event _) {
    final list = input.files;
    if (list == null) return picked.complete(const []);
    final futures = <Future<PickedFile>>[];
    for (var i = 0; i < list.length; i++) {
      final file = list.item(i)!;
      futures.add(
        file.arrayBuffer().toDart.then(
          (b) => (
            name: file.name,
            contentType: file.type.isEmpty
                ? 'application/octet-stream'
                : file.type,
            bytes: Uint8List.view(b.toDart).toList(),
          ),
        ),
      );
    }
    Future.wait(futures).then(picked.complete);
  }.toJS;
  input.click();
  return picked.future;
}
