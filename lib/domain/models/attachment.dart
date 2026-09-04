import 'dart:convert';
import 'dart:typed_data';

/// A file attached from the prompt dock (image or document), held
/// client-side from selection until it is sent.
///
/// Mirrors cortex_api's native `Attachment` schema (see
/// `lib/presentation/api/schemas/attachments.py`): `filename`, `mimeType`
/// and a base64 payload. That schema's own comment states ingestion only
/// accepts `image/...` and `audio/...` mime types, other types are
/// rejected server-side. Document attachments (PDF, DOCX, plain text, ...)
/// are therefore fully supported here on the client (pick, preview,
/// remove, and the request is shaped exactly like the real schema), but
/// sending anything other than an image today will be rejected by
/// cortex_api's ingestion step until it grows document support. That is a
/// documented backend gap, not a client-side limitation.
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.bytes,
  });

  final String id;
  final String filename;
  final String mimeType;
  final Uint8List bytes;

  bool get isImage => mimeType.startsWith('image/');

  /// Whether cortex_api's current ingestion step is expected to accept
  /// this mime type (`image/...` or `audio/...` only, per the real
  /// `Attachment` schema's own comment). Non-image, non-audio documents
  /// are still picked/previewed/sent client-side, but flagged here so the
  /// UI can be honest that the backend does not accept them yet.
  bool get isAcceptedByBackendToday =>
      mimeType.startsWith('image/') || mimeType.startsWith('audio/');

  String get base64 => base64Encode(bytes);

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'mime_type': mimeType,
    'data_base64': base64,
  };
}
