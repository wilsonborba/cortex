import 'dart:async';

import '../../dal/remote/cortex_api_adapter.dart';
import '../models/attachment.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../models/execute_request.dart';

/// Conversation and message lifecycle.
///
/// Conversation metadata (create/rename/pin/delete) is persisted through
/// `cortex_api`'s `/conversations` CRUD endpoints (see `CortexApiAdapter`);
/// message content is sent to the real cortex_api backend through the
/// `api_for_apps` public proxy.
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
  ChatService({
    CortexApiAdapter? cortexApiAdapter,
    List<Conversation>? initialConversations,
  }) : _cortexApi = cortexApiAdapter ?? CortexApiAdapter(),
       _conversations = List.of(initialConversations ?? const []);

  static int _convoIdCounter = 0;
  static String _nextConvoId() {
    _convoIdCounter++;
    return 'convo-${DateTime.now().microsecondsSinceEpoch}-$_convoIdCounter';
  }

  final CortexApiAdapter _cortexApi;
  final List<Conversation> _conversations;

  List<Conversation> listConversations() => List.unmodifiable(_conversations);

  /// Fetches real conversation history from cortex_api's `GET /conversations`.
  /// Genuinely leaves `_conversations` empty when the tenant has none yet:
  /// no conversation is fabricated here, [ChatScreen] hands a client-only
  /// draft (see [newDraftConversation]) to the composer in that case, and
  /// nothing is persisted until the user actually sends a first message.
  Future<List<Conversation>> loadRemoteConversations({String tenantId = 'default'}) async {
    try {
      final remoteList = await _cortexApi.fetchConversations(tenantId: tenantId);
      if (remoteList.isNotEmpty) {
        _conversations.clear();
        for (final item in remoteList) {
          final id = item['id'] as String? ?? 'convo-${DateTime.now().millisecondsSinceEpoch}';
          final title = item['title'] as String? ?? 'Conversation';
          final createdAt = DateTime.tryParse(item['created_at'] as String? ?? '') ?? DateTime.now();
          final updatedAt = DateTime.tryParse(item['updated_at'] as String? ?? '') ?? createdAt;
          _conversations.add(
            Conversation(
              id: id,
              title: title,
              messages: const [],
              isPinned: item['is_pinned'] as bool? ?? false,
              createdAt: createdAt,
              updatedAt: updatedAt,
            ),
          );
        }
      }
    } catch (_) {}
    return listConversations();
  }

  /// Loads full turn details for a specific conversation from cortex_api `GET /conversations/{id}`.
  Future<Conversation?> loadRemoteConversation(String id, {String tenantId = 'default'}) async {
    try {
      final data = await _cortexApi.fetchConversation(id, tenantId: tenantId);
      if (data != null) {
        final messagesData = data['messages'] as List<dynamic>? ?? [];
        final messages = messagesData.map((m) {
          final roleStr = m['role'] as String? ?? 'user';
          final role = roleStr == 'assistant'
              ? MessageRole.assistant
              : (roleStr == 'system' ? MessageRole.system : MessageRole.user);
          return ChatMessage(
            id: m['id'] as String? ?? 'msg-${DateTime.now().microsecondsSinceEpoch}',
            role: role,
            content: m['content'] as String? ?? '',
            createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
          );
        }).toList();

        final index = _conversations.indexWhere((c) => c.id == id);
        if (index != -1) {
          final existing = _conversations[index];
          final updated = existing.copyWith(messages: messages);
          _conversations[index] = updated;
          return updated;
        } else {
          final created = Conversation(
            id: id,
            title: data['title'] as String? ?? 'Conversation $id',
            messages: messages,
            createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
            updatedAt: DateTime.tryParse(data['updated_at'] as String? ?? '') ?? DateTime.now(),
          );
          _conversations.insert(0, created);
          return created;
        }
      }
    } catch (_) {}
    return conversationById(id);
  }

  Conversation? conversationById(String id) {
    for (final conversation in _conversations) {
      if (conversation.id == id) return conversation;
    }
    return null;
  }

  /// Creates a real, persisted conversation (`POST /conversations`) and
  /// inserts it locally. Inserted optimistically even if the backend call
  /// fails, so the UI stays usable offline; a later [loadRemoteConversations]
  /// reconciles with the server's view.
  Future<Conversation> newConversation({
    String title = 'New Conversation',
    String tenantId = 'default',
  }) async {
    final now = DateTime.now();
    final id = _nextConvoId();
    final convo = Conversation(
      id: id,
      title: title,
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
    _conversations.insert(0, convo);
    await _cortexApi.createConversation(conversationId: id, tenantId: tenantId, title: title);
    return convo;
  }

  Future<void> renameConversation(String id, String newTitle, {String tenantId = 'default'}) async {
    final trimmed = newTitle.trim();
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1 && trimmed.isNotEmpty) {
      final convo = _conversations[index];
      _conversations[index] = convo.copyWith(title: trimmed, updatedAt: DateTime.now());
    }
    if (trimmed.isNotEmpty) {
      await _cortexApi.renameConversation(id, trimmed, tenantId: tenantId);
    }
  }

  Future<void> togglePinConversation(String id, {String tenantId = 'default'}) async {
    final index = _conversations.indexWhere((c) => c.id == id);
    bool nextPinned = true;
    if (index != -1) {
      final convo = _conversations[index];
      nextPinned = !convo.isPinned;
      _conversations[index] = convo.copyWith(isPinned: nextPinned, updatedAt: DateTime.now());
    }
    await _cortexApi.setConversationPinned(id, nextPinned, tenantId: tenantId);
  }

  /// Deletes every conversation, leaving the sidebar genuinely empty.
  Future<void> clearAllConversations({String tenantId = 'default'}) async {
    final ids = _conversations.map((c) => c.id).toList();
    _conversations.clear();
    for (final id in ids) {
      await _cortexApi.deleteConversation(id, tenantId: tenantId);
    }
  }

  /// Soft-deletes a conversation (`DELETE /conversations/{id}`). Leaves
  /// `_conversations` empty when it was the last one.
  Future<void> deleteConversation(String id, {String tenantId = 'default'}) async {
    _conversations.removeWhere((c) => c.id == id);
    await _cortexApi.deleteConversation(id, tenantId: tenantId);
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

  /// A client-only conversation for when the sidebar has nothing to select:
  /// not added to `_conversations` (so it never shows up in the sidebar
  /// list), not persisted anywhere. Purely so [ChatFlowHandler] always has a
  /// conversation object to render the composer around. The moment
  /// [sendMessage] is called with this id, it is adopted for real (see
  /// [sendMessage]'s doc comment) and starts showing up in the sidebar like
  /// any other conversation.
  Conversation newDraftConversation({String title = 'New Conversation'}) {
    final now = DateTime.now();
    return Conversation(
      id: _nextConvoId(),
      title: title,
      messages: const [],
      createdAt: now,
      updatedAt: now,
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
  ///
  /// If [conversationId] isn't in `_conversations` yet (the composer was
  /// showing a [newDraftConversation]), it is adopted here: persisted for
  /// real via `POST /conversations` and inserted, so this first message is
  /// what actually turns a draft into a conversation the sidebar shows.
  Future<Conversation> sendMessage({
    required String conversationId,
    required String content,
    bool useMemory = false,
    bool needsWeb = false,
    bool normalizePrompt = true,
    String tenantId = 'default',
    List<ChatAttachment> attachments = const [],
    void Function(Conversation conversation)? onUpdate,
  }) async {
    var index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) {
      final now = DateTime.now();
      _conversations.insert(
        0,
        Conversation(id: conversationId, title: 'New Conversation', messages: const [], createdAt: now, updatedAt: now),
      );
      index = 0;
      unawaited(
        _cortexApi.createConversation(conversationId: conversationId, tenantId: tenantId),
      );
    }

    final conversation = _conversations[index];
    final updated = await _appendUserMessageAndReply(
      conversation: conversation,
      content: content,
      useMemory: useMemory,
      needsWeb: needsWeb,
      normalizePrompt: normalizePrompt,
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
    bool normalizePrompt = true,
    List<ChatAttachment> attachments = const [],
    void Function(Conversation conversation)? onUpdate,
  }) {
    return _appendUserMessageAndReply(
      conversation: conversation,
      content: content,
      useMemory: false,
      needsWeb: needsWeb,
      normalizePrompt: normalizePrompt,
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
    required bool normalizePrompt,
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

    // Surface an empty assistant placeholder immediately, before any network
    // call even starts: without this, no assistant message exists in the UI
    // at all until the first streamed token (or the single non-streamed
    // reply) arrives, so the "waiting" typing indicator (MessageBubble,
    // shown for an empty, non-interrupted assistant message) never actually
    // gets a message to attach to and never renders.
    onUpdate?.call(_withAppendedReply(updated, replyId, '', now));

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
        normalizePrompt: normalizePrompt,
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
    bool normalizePrompt = true,
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final createdAt = DateTime.now();
    final buffer = StringBuffer();
    var updated = _withAppendedReply(conversation, replyId, '', createdAt);

    try {
      await for (final tokenDelta in _cortexApi.streamChatCompletion(
        messages: conversation.messages,
        needsWeb: needsWeb,
        normalizePrompt: normalizePrompt,
        conversationId: conversation.isEphemeral ? null : conversation.id,
        temporary: conversation.isEphemeral,
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
    } on CortexStreamInterruptedException {
      // Preserve whatever partial text already streamed in (issue #7):
      // the reply is marked `interrupted` so the UI can offer "Continue
      // generation" instead of discarding the partial answer.
      updated = _withAppendedReply(
        conversation,
        replyId,
        buffer.toString(),
        createdAt,
        sources: needsWeb ? _extractSources(buffer.toString()) : const [],
        interrupted: true,
      );
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

  /// "Continue generation" for a reply left [ChatMessage.interrupted] by a
  /// dropped SSE connection (issue #7).
  ///
  /// Honesty note: cortex_api's streaming facade sends the full model
  /// response and then chunks it out over SSE (issue #3's finding), it does
  /// not generate token-by-token, and it exposes no partial-completion
  /// resume endpoint. So this is **not** a true "pick up where it left
  /// off": it retries the exact same prompt context that produced the
  /// interrupted reply (every message up to, but excluding, that reply)
  /// from scratch, and once a new response streams in, it *replaces* the
  /// interrupted message's content rather than appending to it, there is no
  /// meaningful token-level continuity between the discarded partial text
  /// and the retried answer. If the retry is interrupted again, the newly
  /// (still partial) text is preserved the same way, so nothing already
  /// received is ever silently dropped.
  ///
  /// [conversation] is the conversation the interrupted message belongs to
  /// (works for both persisted and ephemeral/incognito conversations, the
  /// latter mirroring [sendEphemeralMessage]'s "never touches
  /// `_conversations`" behaviour). [replyMessageId] must be the id of an
  /// existing assistant message in [conversation.messages].
  Future<Conversation> continueGeneration({
    required Conversation conversation,
    required String replyMessageId,
    bool needsWeb = false,
    bool normalizePrompt = true,
    void Function(Conversation conversation)? onUpdate,
  }) async {
    final replyIndex = conversation.messages.indexWhere(
      (m) => m.id == replyMessageId,
    );
    if (replyIndex == -1) {
      throw ArgumentError('Unknown message: $replyMessageId');
    }
    final promptMessages = conversation.messages.sublist(0, replyIndex);

    void publish(Conversation next) {
      final index = _conversations.indexWhere((c) => c.id == next.id);
      if (index != -1) _conversations[index] = next;
      onUpdate?.call(next);
    }

    final createdAt = DateTime.now();
    final buffer = StringBuffer();
    var updated = _withReplacedReply(
      conversation,
      replyMessageId,
      '',
      createdAt,
    );
    publish(updated);

    try {
      await for (final tokenDelta in _cortexApi.streamChatCompletion(
        messages: promptMessages,
        needsWeb: needsWeb,
        normalizePrompt: normalizePrompt,
      )) {
        buffer.write(tokenDelta);
        updated = _withReplacedReply(
          updated,
          replyMessageId,
          buffer.toString(),
          createdAt,
          sources: needsWeb ? _extractSources(buffer.toString()) : const [],
        );
        publish(updated);
      }
    } on CortexStreamInterruptedException {
      updated = _withReplacedReply(
        updated,
        replyMessageId,
        buffer.toString(),
        createdAt,
        interrupted: true,
      );
    } on CortexApiException catch (e) {
      updated = _withReplacedReply(
        updated,
        replyMessageId,
        'Sorry, I could not reach Cortex: ${e.message}',
        createdAt,
      );
    }

    publish(updated);
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
          conversationId: temporary ? null : conversation.id,
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
    bool interrupted = false,
  }) {
    final reply = ChatMessage(
      id: replyId,
      role: MessageRole.assistant,
      content: content,
      createdAt: createdAt,
      sources: sources,
      interrupted: interrupted,
    );
    return Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      isEphemeral: conversation.isEphemeral,
      messages: [...conversation.messages, reply],
    );
  }

  /// Like [_withAppendedReply], but replaces an existing message (by id) in
  /// place instead of appending a new one. Used by [continueGeneration]: a
  /// retried reply reuses the same message id so the UI keeps rendering it
  /// at the same position in the transcript.
  Conversation _withReplacedReply(
    Conversation conversation,
    String replyId,
    String content,
    DateTime createdAt, {
    List<String> sources = const [],
    bool interrupted = false,
  }) {
    final messages = conversation.messages.map((m) {
      if (m.id != replyId) return m;
      return ChatMessage(
        id: replyId,
        role: MessageRole.assistant,
        content: content,
        createdAt: createdAt,
        sources: sources,
        interrupted: interrupted,
      );
    }).toList();
    return Conversation(
      id: conversation.id,
      title: conversation.title,
      isPinned: conversation.isPinned,
      isEphemeral: conversation.isEphemeral,
      messages: messages,
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
}
