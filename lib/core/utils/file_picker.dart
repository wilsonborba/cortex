import 'file_picker_stub.dart'
    if (dart.library.js_interop) 'file_picker_web.dart'
    as impl;

/// A file the user picked: name, content type and bytes.
typedef PickedFile = ({String name, String contentType, List<int> bytes});

/// Opens the browser file dialog (web only; no files elsewhere).
Future<List<PickedFile>> pickFiles() => impl.pickFiles();
