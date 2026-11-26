import 'file_picker.dart';
import 'remote_image_picker_stub.dart'
    if (dart.library.js_interop) 'remote_image_picker_web.dart'
    if (dart.library.io) 'remote_image_picker_io.dart'
    as impl;

/// Opens the platform image chooser only after the user taps Attach image.
Future<List<PickedFile>> pickRemoteImages() => impl.pickRemoteImages();
