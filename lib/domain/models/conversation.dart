import 'chat_message.dart';

/// A conversation thread shown in the sidebar / drawer.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.messages,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final bool isPinned;

  String get preview =>
      messages.isEmpty ? '' : messages.last.content.replaceAll('\n', ' ');
}
