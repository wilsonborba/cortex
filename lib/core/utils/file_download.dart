import 'file_download_stub.dart' if (dart.library.js_interop) 'file_download_web.dart' as impl;

/// Triggers a browser download of [content] as a file named [filename].
/// No-op on non-web targets (VM tests, native builds), see
/// `file_download_web.dart`.
void downloadTextFile({required String filename, required String content}) =>
    impl.downloadTextFile(filename: filename, content: content);
