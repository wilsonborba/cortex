import '../../dal/remote/cortex_api_adapter.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/execute_request.dart';

/// Conversation and message lifecycle.
///
/// Conversations themselves are still a static mocked dataset (there is no
/// conversation-persistence backend yet), but sending a message now talks to
/// the real cortex_api backend through the `api_for_apps` public proxy (see
/// `CortexApiAdapter`), instead of the delayed, hardcoded reply this used to
/// return.
///
/// Two modes are supported, chosen per-call via [sendMessage]'s `useMemory`:
/// - Plain chat: streams tokens from cortex_api's OpenAI facade
///   (`POST /v1/chat/completions`, `stream: true`).
/// - Memory recall: calls cortex_api's native `POST /execute` with
///   `capabilities.memory = true`, a single non-streamed reply.
class ChatService {
  ChatService({CortexApiAdapter? cortexApiAdapter})
    : _cortexApi = cortexApiAdapter ?? CortexApiAdapter(),
      _conversations = _mockConversations();

  final CortexApiAdapter _cortexApi;
  final List<Conversation> _conversations;

  List<Conversation> listConversations() => List.unmodifiable(_conversations);

  Conversation? conversationById(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  /// Appends [content] as a user message, then produces an assistant reply
  /// either by streaming (default) or, when [useMemory] is true, by calling
  /// the native memory-aware `/execute` route. Returns the final, fully
  /// updated conversation.
  ///
  /// [onUpdate], if given, is called every time the stored conversation
  /// changes: once right after the user message is appended, then once per
  /// streamed token (or once with the full reply in the memory-recall
  /// path). Callers that want to render tokens as they arrive should use
  /// this callback rather than waiting on the returned [Future].
  Future<Conversation> sendMessage({
    required String conversationId,
    required String content,
    bool useMemory = false,
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      throw ArgumentError('Unknown conversation: $conversationId');
    }

    final conversation = _conversations[index];
    final now = DateTime.now();

    final userMessage = ChatMessage(
      id: 'msg-${now.microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: content,
      createdAt: now,
    );

    var updated = Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      messages: [...conversation.messages, userMessage],
    );
    _conversations[index] = updated;
    onUpdate?.call(updated);

    final replyId = 'msg-${now.microsecondsSinceEpoch}-r';

    if (useMemory) {
      updated = await _replyWithMemoryRecall(index, updated, replyId);
    } else {
      updated = await _replyWithStreamedChat(index, updated, replyId, onUpdate);
    }
    onUpdate?.call(updated);
    return updated;
  }

  Future<Conversation> _replyWithStreamedChat(
    int index,
    Conversation conversation,
    String replyId,
    void Function(Conversation conversation)? onUpdate,
  ) async {
    final createdAt = DateTime.now();
    final buffer = StringBuffer();
    var updated = _withAppendedReply(conversation, replyId, '', createdAt);
    _conversations[index] = updated;

    try {
      await for (final tokenDelta in _cortexApi.streamChatCompletion(
        messages: conversation.messages,
      )) {
        buffer.write(tokenDelta);
        updated = _withAppendedReply(
          conversation,
          replyId,
          buffer.toString(),
          createdAt,
        );
        _conversations[index] = updated;
        onUpdate?.call(updated);
      }
    } on CortexApiException catch (e) {
      updated = _withAppendedReply(
        conversation,
        replyId,
        'Sorry, I could not reach Cortex: ${e.message}',
        createdAt,
      );
      _conversations[index] = updated;
    }

    return updated;
  }

  Future<Conversation> _replyWithMemoryRecall(
    int index,
    Conversation conversation,
    String replyId,
  ) async {
    final createdAt = DateTime.now();
    String content;
    try {
      final result = await _cortexApi.execute(
        ExecuteRequest(prompt: conversation.messages.last.content, useMemory: true),
      );
      content = result.response;
    } on CortexApiException catch (e) {
      content = 'Sorry, I could not reach Cortex: ${e.message}';
    }

    final updated = _withAppendedReply(conversation, replyId, content, createdAt);
    _conversations[index] = updated;
    return updated;
  }

  Conversation _withAppendedReply(
    Conversation conversation,
    String replyId,
    String content,
    DateTime createdAt,
  ) {
    final reply = ChatMessage(
      id: replyId,
      role: MessageRole.assistant,
      content: content,
      createdAt: createdAt,
    );
    return Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      messages: [...conversation.messages, reply],
    );
  }

  static List<Conversation> _mockConversations() {
    final base = DateTime.now().subtract(const Duration(minutes: 20));
    return [
      Conversation(
        id: 'conv-1',
        title: 'Welcome to Cortex',
        isPinned: true,
        messages: [
          ChatMessage(
            id: 'm1',
            role: MessageRole.assistant,
            content:
                'Hi, I am Cortex running on Tier 0 (free and fast models). '
                'Ask me anything to get started.',
            createdAt: base,
          ),
        ],
      ),
      Conversation(
        id: 'conv-2',
        title: 'Trip planning ideas',
        messages: [
          ChatMessage(
            id: 'm2',
            role: MessageRole.user,
            content: 'Give me a three day itinerary for Lisbon.',
            createdAt: base.add(const Duration(minutes: 2)),
          ),
          ChatMessage(
            id: 'm3',
            role: MessageRole.assistant,
            content:
                'Day 1: Alfama and the castle. Day 2: Belem and the '
                'monastery. Day 3: a day trip to Sintra.',
            createdAt: base.add(const Duration(minutes: 3)),
          ),
        ],
      ),
      Conversation(
        id: 'conv-3',
        title: 'Refactor notes',
        messages: [
          ChatMessage(
            id: 'm4',
            role: MessageRole.user,
            content: 'Summarize the changes needed for the new adapter.',
            createdAt: base.add(const Duration(minutes: 10)),
          ),
        ],
      ),
    ];
  }
}
