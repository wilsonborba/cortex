import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/services/app_preferences_service.dart';
import '../../../domain/services/chat_service.dart';
import '../../../domain/services/draft_store_service.dart';

/// Orchestrates submitting a prompt from the dock: keeps a `busy` flag so
/// the dock can show a stop affordance, calls into [ChatService], and
/// notifies listeners so the screen can rebuild with the updated
/// conversation. No business logic lives in the widgets themselves.
///
/// Also owns:
/// - the `useMemory` toggle wired from the prompt dock's memory recall
///   affordance: when on, [submit] routes through cortex_api's native
///   `/execute` (server-side memory recall) instead of the streamed chat
///   completion facade;
/// - the `needsWeb` toggle (issue #6): sets `needs_web`/`capabilities.web`
///   on the outgoing request, on whichever route is used;
/// - `pendingAttachments` (issue #6): files picked from the prompt dock
///   that will be sent with the next [submit] and cleared afterwards;
/// - incognito mode (issue #6, #18): [startIncognitoConversation] swaps
///   [conversation] for a brand-new, never-persisted one; while
///   `conversation.isEphemeral` is true, [submit] routes through
///   [ChatService.sendEphemeralMessage], which forces memory off and
///   `capabilities.temporary = true` unconditionally; [exitIncognitoConversation]
///   swaps back to a persisted conversation.
class ChatFlowHandler extends ChangeNotifier {
  ChatFlowHandler(
    this._chatService,
    Conversation initialConversation, {
    DraftStoreService? draftStore,
    AppPreferencesService? preferencesService,
  }) : conversation = initialConversation,
       _draftStore = draftStore ?? const DraftStoreService(),
       _preferencesService = preferencesService {
    _loadDraftForCurrentConversation();
  }

  final ChatService _chatService;
  final DraftStoreService _draftStore;
  final AppPreferencesService? _preferencesService;
  Timer? _draftSaveDebounce;

  Conversation conversation;
  Conversation? _previousPersistedConversation;
  bool isBusy = false;
  bool useMemory = false;
  bool needsWeb = false;
  List<ChatAttachment> pendingAttachments = [];

  /// Current, in-progress, unsent prompt draft for [conversation] (issue
  /// #7): kept in sync with `DraftStoreService` as the user types (see
  /// [updateDraft]) and reloaded whenever [switchConversation] changes
  /// which conversation is active, so switching away and back never loses
  /// typed-but-unsent text.
  String draftText = '';

  /// Id of the assistant message currently being retried via
  /// [continueGeneration], if any. Lets the UI show a spinner on just that
  /// message's chip instead of a global busy state.
  String? continuingMessageId;

  /// Raw error thrown by [ChatService.sendMessage], if the last submit
  /// failed. Kept untranslated here (this handler has no [BuildContext]):
  /// the widget layer turns it into a localized message via
  /// `AppLocalizations.couldNotSendMessage`.
  Object? error;

  Future<void> _loadDraftForCurrentConversation() async {
    final conversationId = conversation.id;
    final draft = await _draftStore.loadDraft(conversationId);
    // The user may have already switched conversations again by the time
    // this resolves, don't clobber a newer draft with a stale load.
    if (conversation.id != conversationId) return;
    draftText = draft;
    notifyListeners();
  }

  /// Called by the prompt input widget on every keystroke: updates in-memory
  /// [draftText] immediately and persists it (debounced) via `DraftStore`.
  void updateDraft(String text) {
    draftText = text;
    _draftSaveDebounce?.cancel();
    final conversationId = conversation.id;
    _draftSaveDebounce = Timer(const Duration(milliseconds: 400), () {
      _draftStore.saveDraft(conversationId, text);
    });
  }

  void setUseMemory(bool value) {
    if (useMemory == value) return;
    useMemory = value;
    notifyListeners();
  }

  void setNeedsWeb(bool value) {
    if (needsWeb == value) return;
    needsWeb = value;
    notifyListeners();
  }

  void addPendingAttachment(ChatAttachment attachment) {
    pendingAttachments = [...pendingAttachments, attachment];
    notifyListeners();
  }

  void addPendingAttachments(List<ChatAttachment> attachments) {
    if (attachments.isEmpty) return;
    pendingAttachments = [...pendingAttachments, ...attachments];
    notifyListeners();
  }

  void removePendingAttachment(String id) {
    pendingAttachments = pendingAttachments.where((a) => a.id != id).toList();
    notifyListeners();
  }

  /// Starts a brand-new incognito/temporary conversation (issue #6): no
  /// persisted history, memory explicitly off. Does not touch
  /// `ConversationHandler`'s sidebar list, an ephemeral conversation is
  /// never part of it.
  void startIncognitoConversation() {
    if (!conversation.isEphemeral) {
      _previousPersistedConversation = conversation;
    }
    conversation = _chatService.newEphemeralConversation(
      title: 'Incognito chat',
    );
    useMemory = false;
    error = null;
    draftText = '';
    _draftSaveDebounce?.cancel();
    notifyListeners();
    _loadDraftForCurrentConversation();
  }

  /// Exits incognito/temporary mode (issue #18), returning to the previous
  /// active conversation (or [fallback] if none was remembered).
  void exitIncognitoConversation({Conversation? fallback}) {
    if (!conversation.isEphemeral) return;
    final target = _previousPersistedConversation ?? fallback ?? _chatService.listConversations().first;
    _previousPersistedConversation = null;
    switchConversation(target);
  }

  Future<void> submit(String text) async {
    // A voice message (issue #11) sends with empty text and just the
    // recorded attachment, so this only bails when there's neither.
    if ((text.trim().isEmpty && pendingAttachments.isEmpty) || isBusy) return;
    isBusy = true;
    error = null;
    final attachments = pendingAttachments;
    pendingAttachments = [];
    // The text is on its way as a real message now, its draft no longer
    // needs to live in `DraftStore`.
    _draftSaveDebounce?.cancel();
    final sentConversationId = conversation.id;
    draftText = '';
    unawaited(_draftStore.clearDraft(sentConversationId));
    notifyListeners();

    final normalizePrompt = _preferencesService == null
        ? true
        : await _preferencesService!.readImproveInput();

    try {
      if (conversation.isEphemeral) {
        conversation = await _chatService.sendEphemeralMessage(
          conversation: conversation,
          content: text,
          needsWeb: needsWeb,
          normalizePrompt: normalizePrompt,
          attachments: attachments,
          onUpdate: (updated) {
            conversation = updated;
            notifyListeners();
          },
        );
      } else {
        conversation = await _chatService.sendMessage(
          conversationId: conversation.id,
          content: text,
          useMemory: useMemory,
          needsWeb: needsWeb,
          normalizePrompt: normalizePrompt,
          attachments: attachments,
          onUpdate: (updated) {
            conversation = updated;
            notifyListeners();
          },
        );
      }
    } catch (e) {
      error = e;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void switchConversation(Conversation next) {
    if (conversation.id == next.id) {
      conversation = next;
      notifyListeners();
      return;
    }
    _draftSaveDebounce?.cancel();
    conversation = next;
    error = null;
    draftText = '';
    notifyListeners();
    _loadDraftForCurrentConversation();
  }

  /// Retries the request that produced [replyMessageId] (see
  /// `ChatService.continueGeneration`) after a dropped SSE connection left
  /// it [ChatMessage.interrupted] (issue #7).
  ///
  /// This is a full retry of the same prompt, not a true resume:
  /// cortex_api has no partial-completion resume endpoint, so once the
  /// retry streams in, it replaces the interrupted message's content
  /// rather than appending to it.
  Future<void> continueGeneration(String replyMessageId) async {
    if (continuingMessageId != null) return;
    continuingMessageId = replyMessageId;
    error = null;
    notifyListeners();

    try {
      conversation = await _chatService.continueGeneration(
        conversation: conversation,
        replyMessageId: replyMessageId,
        needsWeb: needsWeb,
        onUpdate: (updated) {
          conversation = updated;
          notifyListeners();
        },
      );
    } catch (e) {
      error = e;
    } finally {
      continuingMessageId = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _draftSaveDebounce?.cancel();
    super.dispose();
  }
}
