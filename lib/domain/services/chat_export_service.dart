import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Renders a [Conversation] as a plain Markdown transcript for export.
/// Pure/no platform dependency, so it's independently testable; actually
/// triggering a download is a separate, platform-specific concern (see
/// `core/utils/file_download.dart`).
class ChatExportService {
  const ChatExportService();

  String buildMarkdown(Conversation conversation) {
    final buffer = StringBuffer()
      ..writeln('# ${conversation.title}')
      ..writeln()
      ..writeln('_Exported ${_formatDateTime(DateTime.now())}_')
      ..writeln();

    for (final message in conversation.messages) {
      buffer
        ..writeln('**${_roleLabel(message.role)}** — ${_formatDateTime(message.createdAt)}')
        ..writeln()
        ..writeln(message.content.isEmpty ? '_(no text content)_' : message.content)
        ..writeln();

      if (message.attachments.isNotEmpty) {
        for (final attachment in message.attachments) {
          buffer.writeln('- 📎 ${attachment.filename}');
        }
        buffer.writeln();
      }

      if (message.sources.isNotEmpty) {
        buffer.writeln('Sources:');
        for (final source in message.sources) {
          buffer.writeln('- $source');
        }
        buffer.writeln();
      }

      buffer
        ..writeln('---')
        ..writeln();
    }

    return buffer.toString();
  }

  /// A safe filename derived from the conversation's title and id, e.g.
  /// `my-conversation-convo-123.md`.
  String suggestedFilename(Conversation conversation) {
    final slug = conversation.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'conversation' : slug;
    return '$base-${conversation.id}.md';
  }

  String _roleLabel(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'User';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
