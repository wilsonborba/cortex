import 'package:flutter/material.dart';

/// Icon for an attachment's filename extension. Falls back to a generic
/// file icon for anything unrecognized (new/unknown extensions must never
/// crash or leave the card without an icon).
///
/// Shared by the memory graph's attachment node card and by
/// [MessageBubble]'s attachment chips (including historical, bytes-less
/// attachments, see `ChatAttachment.isPlaceholder`) so the same file lands
/// on the same icon everywhere in the app.
IconData fileIconForFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  final ext = dot == -1 || dot == filename.length - 1 ? '' : filename.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
    case 'rtf':
      return Icons.description_outlined;
    case 'wav':
    case 'mp3':
    case 'm4a':
    case 'aac':
    case 'ogg':
    case 'flac':
      return Icons.audiotrack_outlined;
    case 'mp4':
    case 'mov':
    case 'webm':
    case 'mkv':
      return Icons.videocam_outlined;
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'heic':
      return Icons.image_outlined;
    case 'txt':
    case 'md':
      return Icons.text_snippet_outlined;
    case 'csv':
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
      return Icons.data_object_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}
