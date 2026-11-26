import 'file_picker.dart';
import 'file_picker_web.dart' as web_picker;

Future<List<PickedFile>> pickRemoteImages() async {
  final selected = await web_picker.pickFiles();
  return [
    for (final file in selected)
      if (file.contentType.startsWith('image/')) file,
  ];
}
