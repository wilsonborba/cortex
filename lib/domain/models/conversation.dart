import 'chat_message.dart';

/// A conversation thread shown in the sidebar / drawer.
class Conversation {
  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    this.isPinned = false,
    this.isEphemeral = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final List<ChatMessage> messages;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// True for an incognito/temporary chat (issue #6): messages sent in this
  /// conversation are never written to `LocalStorageAdapter` or any
  /// conversation history, it is not listed by `ChatService.listConversations`
  /// and disappears once the user navigates away from it.
  final bool isEphemeral;

  Conversation copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    bool? isPinned,
    bool? isEphemeral,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      isEphemeral: isEphemeral ?? this.isEphemeral,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get preview =>
      messages.isEmpty ? '' : messages.last.content.replaceAll('\n', ' ');
}
