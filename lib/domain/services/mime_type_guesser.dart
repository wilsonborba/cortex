/// Guesses a mime type from a filename's extension.
///
/// Shared by [AttachmentService] (freshly-picked files, which have no mime
/// type of their own until this runs) and [ChatService] (historical
/// attachments reconstructed from `GET /conversations/{id}`, which only ever
/// get a filename back from the server, never a mime type). Keeping this in
/// one place avoids the two call sites drifting apart.
String guessMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  if (lower.endsWith('.docx')) {
    return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
  }
  if (lower.endsWith('.csv')) return 'text/csv';
  if (lower.endsWith('.md')) return 'text/markdown';
  return 'text/plain';
}
