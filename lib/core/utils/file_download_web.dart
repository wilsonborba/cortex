import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Triggers a browser download of [content] as [filename]: builds a Blob,
/// a throwaway anchor with `download` set, clicks it programmatically, then
/// cleans up. This is the standard way to save a client-generated file on
/// Flutter web, there is no filesystem to write to directly.
void downloadTextFile({required String filename, required String content}) {
  final blobParts = <JSAny>[content.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'text/markdown;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
