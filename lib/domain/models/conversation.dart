import 'chat_message.dart';

/// A conversation thread shown in the sidebar / drawer.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    this.isPinned = false,
    this.isEphemeral = false,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final bool isPinned;

  /// True for an incognito/temporary chat (issue #6): messages sent in this
  /// conversation are never written to `LocalStorageAdapter` or any
  /// conversation history, it is not listed by `ChatService.listConversations`
  /// and disappears once the user navigates away from it.
  final bool isEphemeral;

  String get preview =>
      messages.isEmpty ? '' : messages.last.content.replaceAll('\n', ' ');
}
