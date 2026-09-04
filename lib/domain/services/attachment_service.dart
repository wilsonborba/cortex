import 'package:file_picker/file_picker.dart';

import '../models/attachment.dart';

/// Wraps `file_picker` for the prompt dock's attach flow (issue #6).
///
/// `file_picker` (rather than `image_picker`) is used for both images and
/// documents so a single package covers the whole attach affordance and
/// both pickers share the same result shape; it also works on web, where
/// `PlatformFile.readAsBytes()` is used to get the bytes back directly
/// instead of a file path (there is no filesystem on web).
class AttachmentService {
  const AttachmentService();

  /// Opens the platform picker restricted to image files.
  Future<List<ChatAttachment>> pickImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    return _toAttachments(files);
  }

  /// Opens the platform picker restricted to common document types.
  ///
  /// Note (documented gap, see `ChatAttachment.isAcceptedByBackendToday`):
  /// cortex_api's real `Attachment` schema only accepts `image/...` and
  /// `audio/...` mime types at ingestion today, so a document picked here
  /// can be selected, previewed, and sent on the wire exactly like the
  /// real schema, but is expected to be rejected server-side until
  /// document ingestion ships.
  Future<List<ChatAttachment>> pickDocuments() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'md', 'csv'],
    );
    return _toAttachments(files);
  }

  Future<List<ChatAttachment>> _toAttachments(List<PlatformFile> files) async {
    final attachments = <ChatAttachment>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      attachments.add(
        ChatAttachment(
          id: 'att-${DateTime.now().microsecondsSinceEpoch}-${attachments.length}',
          filename: file.name,
          mimeType: _guessMimeType(file.name),
          bytes: bytes,
        ),
      );
    }
    return attachments;
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.csv')) return 'text/csv';
    if (lower.endsWith('.md')) return 'text/markdown';
    return 'text/plain';
  }
}
