import '../models/chat_message.dart';
import '../models/conversation.dart';

/// Conversation and message lifecycle.
///
/// There is no backend wiring in this issue (that lands in issue #3), so
/// this service returns a static mocked dataset and simulates an assistant
/// reply with a short delay. The public method shapes already match what a
/// real, streaming implementation would expose, so callers will not need to
/// change when the real service arrives.
class ChatService {
  ChatService() : _conversations = _mockConversations();

  final List<Conversation> _conversations;

  List<Conversation> listConversations() => List.unmodifiable(_conversations);

  Conversation? conversationById(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  /// Appends [content] as a user message, then simulates a mocked assistant
  /// reply. Returns the updated conversation.
  Future<Conversation> sendMessage({
    required String conversationId,
    required String content,
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

    await Future<void>.delayed(const Duration(milliseconds: 400));

    final reply = ChatMessage(
      id: 'msg-${now.microsecondsSinceEpoch}-r',
      role: MessageRole.assistant,
      content:
          'This is a mocked Tier 0 response. Live model output will be '
          'wired up once the backend integration (issue #3) lands.',
      createdAt: DateTime.now(),
    );

    updated = Conversation(
      id: updated.id,
      title: updated.title,
      isPinned: updated.isPinned,
      messages: [...updated.messages, reply],
    );
    _conversations[index] = updated;

    return updated;
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
