import 'package:flutter/foundation.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

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
/// - incognito mode (issue #6): [startIncognitoConversation] swaps
///   [conversation] for a brand-new, never-persisted one; while
///   `conversation.isEphemeral` is true, [submit] routes through
///   [ChatService.sendEphemeralMessage], which forces memory off and
///   `capabilities.temporary = true` unconditionally.
class ChatFlowHandler extends ChangeNotifier {
  ChatFlowHandler(this._chatService, Conversation initialConversation)
    : conversation = initialConversation;

  final ChatService _chatService;

  Conversation conversation;
  bool isBusy = false;
  bool useMemory = false;
  bool needsWeb = false;
  List<ChatAttachment> pendingAttachments = [];

  /// Raw error thrown by [ChatService.sendMessage], if the last submit
  /// failed. Kept untranslated here (this handler has no [BuildContext]):
  /// the widget layer turns it into a localized message via
  /// `AppLocalizations.couldNotSendMessage`.
  Object? error;

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
    conversation = _chatService.newEphemeralConversation(
      title: 'Incognito chat',
    );
    useMemory = false;
    error = null;
    notifyListeners();
  }

  Future<void> submit(String text) async {
    if (text.trim().isEmpty || isBusy) return;
    isBusy = true;
    error = null;
    final attachments = pendingAttachments;
    pendingAttachments = [];
    notifyListeners();

    try {
      if (conversation.isEphemeral) {
        conversation = await _chatService.sendEphemeralMessage(
          conversation: conversation,
          content: text,
          needsWeb: needsWeb,
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
    conversation = next;
    error = null;
    notifyListeners();
  }
}
