import 'dart:convert';
import 'dart:typed_data';

/// A file attached from the prompt dock (image or document), held
/// client-side from selection until it is sent.
///
/// Mirrors cortex_api's native `Attachment` schema (see
/// `lib/presentation/api/schemas/attachments.py`): `filename`, `mimeType`
/// and a base64 payload. Ingestion accepts `image/...`, `audio/...`,
/// `application/pdf`, docx, and plain-text-ish mime types (see
/// `lib/engine/attachments.py`'s `AttachmentIngestor`); legacy binary
/// `.doc` (`application/msword`) is not supported (no library for the old
/// binary format, only the modern XML-based docx), same gap
/// `certifications_api` already has.
class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.filename,
    required this.mimeType,
    required this.bytes,
    this.audioDuration,
  });

  final String id;
  final String filename;
  final String mimeType;
  final Uint8List bytes;

  /// Recorded length of a voice message (issue #11), null for every other
  /// attachment kind. Drives the duration label/waveform in [MessageBubble]
  /// and [VoiceRecordingBar] without needing to decode the audio client-side.
  final Duration? audioDuration;

  bool get isImage => mimeType.startsWith('image/');
  bool get isAudio => mimeType.startsWith('audio/');

  /// True for a historical attachment reconstructed from `GET
  /// /conversations/{id}` (see `ChatService.loadRemoteConversation`), where
  /// the server only ever gives back a filename, never the original bytes.
  /// Rendering must fall back to a filename+icon chip for these: there is
  /// nothing to decode as an image or play as audio.
  bool get isPlaceholder => bytes.isEmpty;

  /// Whether cortex_api's ingestion step is expected to accept this mime
  /// type. Legacy binary `.doc` is the one picked-but-unsupported gap left
  /// (see this class's doc comment).
  bool get isAcceptedByBackendToday =>
      mimeType.startsWith('image/') ||
      mimeType.startsWith('audio/') ||
      mimeType == 'application/pdf' ||
      mimeType == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||
      mimeType.startsWith('text/') ||
      mimeType == 'application/json' ||
      mimeType == 'application/xml';

  String get base64 => base64Encode(bytes);

  Map<String, dynamic> toJson() => {
    'filename': filename,
    'mime_type': mimeType,
    'data_base64': base64,
  };
}
