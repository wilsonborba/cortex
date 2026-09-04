import 'attachment.dart';

enum MessageRole { user, assistant, system }

/// A single message inside a conversation.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.sources = const [],
    this.attachments = const [],
  });

  final String id;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  /// Source URLs surfaced alongside a web-search-grounded reply. cortex_api
  /// has no dedicated citation/source field on `ExecuteResponse` or
  /// `ChatCompletionResponse` today (checked against
  /// `lib/presentation/api/schemas/execute.py` and `openai_facade.py`), so
  /// these are extracted heuristically from the raw reply text (see
  /// `ChatService._extractSources`) whenever the request was sent with web
  /// search grounding on. This is real parsing of whatever the model
  /// actually returned, not fabricated data, but it is not a structured
  /// backend guarantee.
  final List<String> sources;

  /// Files the user attached to this message (for user messages) so the
  /// bubble can render the same preview it showed before sending.
  final List<ChatAttachment> attachments;
}
