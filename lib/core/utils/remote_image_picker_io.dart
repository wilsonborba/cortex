import 'package:file_picker/file_picker.dart' as native_picker;

import 'file_picker.dart';

const _imageTypes = <String, String>{
  'bmp': 'image/bmp',
  'gif': 'image/gif',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'jpeg': 'image/jpeg',
  'jpg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

Future<List<PickedFile>> pickRemoteImages() async {
  final selection = await native_picker.FilePicker.platform.pickFiles(
    type: native_picker.FileType.image,
    allowMultiple: true,
    withData: true,
  );
  if (selection == null) return const [];
  return [
    for (final file in selection.files)
      if (file.bytes != null &&
          _imageTypes.containsKey(file.extension?.toLowerCase()))
        (
          name: file.name,
          contentType: _imageTypes[file.extension!.toLowerCase()]!,
          bytes: file.bytes!.toList(),
        ),
  ];
}
