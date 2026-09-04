import 'package:flutter/foundation.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

/// Orchestrates submitting a prompt from the dock: keeps a `busy` flag so
/// the dock can show a stop affordance, calls into [ChatService], and
/// notifies listeners so the screen can rebuild with the updated
/// conversation. No business logic lives in the widgets themselves.
///
/// Also owns the `useMemory` toggle wired from the prompt dock's memory
/// recall affordance: when on, [submit] routes through cortex_api's native
/// `/execute` (server-side memory recall) instead of the streamed chat
/// completion facade.
class ChatFlowHandler extends ChangeNotifier {
  ChatFlowHandler(this._chatService, Conversation initialConversation)
    : conversation = initialConversation;

  final ChatService _chatService;

  Conversation conversation;
  bool isBusy = false;
  bool useMemory = false;
  String? error;

  void setUseMemory(bool value) {
    if (useMemory == value) return;
    useMemory = value;
    notifyListeners();
  }

  Future<void> submit(String text) async {
    if (text.trim().isEmpty || isBusy) return;
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      conversation = await _chatService.sendMessage(
        conversationId: conversation.id,
        content: text,
        useMemory: useMemory,
        onUpdate: (updated) {
          conversation = updated;
          notifyListeners();
        },
      );
    } catch (e) {
      error = 'Could not send message: $e';
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
