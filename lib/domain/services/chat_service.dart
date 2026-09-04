import '../../dal/remote/cortex_api_adapter.dart';
import '../models/attachment.dart';
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
/// Three modes are supported, chosen per-call:
/// - Plain chat: streams tokens from cortex_api's OpenAI facade
///   (`POST /v1/chat/completions`, `stream: true`).
/// - Memory recall (`useMemory`): calls cortex_api's native `POST /execute`
///   with `capabilities.memory = true`, a single non-streamed reply.
/// - Attachments force the native `/execute` route regardless of
///   `useMemory`: `ChatCompletionRequest` (the streaming facade) has no
///   `attachments` field on cortex_api's real schema, only `ExecuteRequest`
///   does.
///
/// Web-search grounding (`needsWeb`) is orthogonal to the above and is
/// forwarded on whichever route is used (both real schemas carry
/// `needs_web`).
///
/// [sendEphemeralMessage] is the separate incognito/temporary-chat path
/// (issue #6): it never touches the in-memory `_conversations` list (so
/// nothing is added to `listConversations()` and nothing could ever be
/// written to `LocalStorageAdapter`), and it always forces memory off and
/// `capabilities.temporary = true`.
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

  /// Builds a brand-new, never-persisted conversation for incognito mode.
  /// It is intentionally not added to `_conversations`: it never appears in
  /// `listConversations()` and is lost as soon as the caller stops holding
  /// a reference to it (e.g. the user switches to another conversation).
  Conversation newEphemeralConversation({required String title}) {
    final now = DateTime.now();
    return Conversation(
      id: 'ephemeral-${now.microsecondsSinceEpoch}',
      title: title,
      isEphemeral: true,
      messages: const [],
    );
  }

  /// Appends [content] as a user message, then produces an assistant reply
  /// either by streaming (default) or, when [useMemory] is true or
  /// [attachments] is non-empty, by calling the native memory-aware
  /// `/execute` route. Returns the final, fully updated conversation.
  ///
  /// [onUpdate], if given, is called every time the stored conversation
  /// changes: once right after the user message is appended, then once per
  /// streamed token (or once with the full reply in the `/execute` path).
  /// Callers that want to render tokens as they arrive should use this
  /// callback rather than waiting on the returned [Future].
  Future<Conversation> sendMessage({
    required String conversationId,
    required String content,
    bool useMemory = false,
    bool needsWeb = false,
    List<ChatAttachment> attachments = const [],
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      throw ArgumentError('Unknown conversation: $conversationId');
    }

    final conversation = _conversations[index];
    final updated = await _appendUserMessageAndReply(
      conversation: conversation,
      content: content,
      useMemory: useMemory,
      needsWeb: needsWeb,
      temporary: false,
      attachments: attachments,
      onUpdate: (c) {
        _conversations[index] = c;
        onUpdate?.call(c);
      },
    );
    _conversations[index] = updated;
    return updated;
  }

  /// Incognito counterpart of [sendMessage]: operates entirely on the
  /// [conversation] object passed in (expected to be
  /// `isEphemeral == true`, e.g. from [newEphemeralConversation]) and never
  /// touches `_conversations`. Memory is always forced off here regardless
  /// of any caller input: incognito chats must never opt into server-side
  /// memory recall.
  Future<Conversation> sendEphemeralMessage({
    required Conversation conversation,
    required String content,
    bool needsWeb = false,
    List<ChatAttachment> attachments = const [],
    void Function(Conversation conversation)? onUpdate,
  }) {
    return _appendUserMessageAndReply(
      conversation: conversation,
      content: content,
      useMemory: false,
      needsWeb: needsWeb,
      temporary: true,
      attachments: attachments,
      onUpdate: onUpdate,
    );
  }

  Future<Conversation> _appendUserMessageAndReply({
    required Conversation conversation,
    required String content,
    required bool useMemory,
    required bool needsWeb,
    required bool temporary,
    required List<ChatAttachment> attachments,
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final now = DateTime.now();

    final userMessage = ChatMessage(
      id: 'msg-${now.microsecondsSinceEpoch}',
      role: MessageRole.user,
      content: content,
      createdAt: now,
      attachments: attachments,
    );

    var updated = Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      isEphemeral: conversation.isEphemeral,
      messages: [...conversation.messages, userMessage],
    );
    onUpdate?.call(updated);

    final replyId = 'msg-${now.microsecondsSinceEpoch}-r';

    if (useMemory || attachments.isNotEmpty || temporary) {
      updated = await _replyWithExecute(
        updated,
        replyId,
        useMemory: useMemory,
        needsWeb: needsWeb,
        temporary: temporary,
        attachments: attachments,
      );
    } else {
      updated = await _replyWithStreamedChat(
        updated,
        replyId,
        needsWeb: needsWeb,
        onUpdate: onUpdate,
      );
    }
    onUpdate?.call(updated);
    return updated;
  }

  Future<Conversation> _replyWithStreamedChat(
    Conversation conversation,
    String replyId, {
    required bool needsWeb,
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final createdAt = DateTime.now();
    final buffer = StringBuffer();
    var updated = _withAppendedReply(conversation, replyId, '', createdAt);

    try {
      await for (final tokenDelta in _cortexApi.streamChatCompletion(
        messages: conversation.messages,
        needsWeb: needsWeb,
      )) {
        buffer.write(tokenDelta);
        updated = _withAppendedReply(
          conversation,
          replyId,
          buffer.toString(),
          createdAt,
          sources: needsWeb ? _extractSources(buffer.toString()) : const [],
        );
        onUpdate?.call(updated);
      }
    } on CortexApiException catch (e) {
      updated = _withAppendedReply(
        conversation,
        replyId,
        'Sorry, I could not reach Cortex: ${e.message}',
        createdAt,
      );
    }

    return updated;
  }

  Future<Conversation> _replyWithExecute(
    Conversation conversation,
    String replyId, {
    required bool useMemory,
    required bool needsWeb,
    required bool temporary,
    required List<ChatAttachment> attachments,
  }) async {
    final createdAt = DateTime.now();
    String content;
    List<String> sources = const [];
    try {
      final result = await _cortexApi.execute(
        ExecuteRequest(
          prompt: conversation.messages.last.content,
          useMemory: useMemory,
          needsWeb: needsWeb,
          temporary: temporary,
          attachments: attachments,
        ),
      );
      content = result.response;
      if (needsWeb) sources = _extractSources(content);
    } on CortexApiException catch (e) {
      content = 'Sorry, I could not reach Cortex: ${e.message}';
    }

    return _withAppendedReply(
      conversation,
      replyId,
      content,
      createdAt,
      sources: sources,
    );
  }

  Conversation _withAppendedReply(
    Conversation conversation,
    String replyId,
    String content,
    DateTime createdAt, {
    List<String> sources = const [],
  }) {
    final reply = ChatMessage(
      id: replyId,
      role: MessageRole.assistant,
      content: content,
      createdAt: createdAt,
      sources: sources,
    );
    return Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      isEphemeral: conversation.isEphemeral,
      messages: [...conversation.messages, reply],
    );
  }

  /// Heuristically pulls raw `http(s)://` URLs out of [text]. cortex_api has
  /// no dedicated citation/source field on `ExecuteResponse` or
  /// `ChatCompletionResponse` today, so this is the only way to surface a
  /// "Sources (N)" card: it is real extraction of whatever the model
  /// actually wrote, not fabricated data, but it depends on the model
  /// choosing to cite URLs in the reply text and is not a structured
  /// backend guarantee.
  static final _urlPattern = RegExp(r'https?://[^\s)>\]"]+');

  List<String> _extractSources(String text) {
    final seen = <String>{};
    final sources = <String>[];
    for (final match in _urlPattern.allMatches(text)) {
      var url = match.group(0)!;
      // Strip common trailing punctuation picked up by the greedy match.
      url = url.replaceAll(RegExp(r'[.,;:!?]+$'), '');
      if (seen.add(url)) sources.add(url);
    }
    return sources;
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
