import 'package:flutter/foundation.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

/// Orchestrates submitting a prompt from the dock: keeps a `busy` flag so
/// the dock can show a stop affordance, calls into [ChatService], and
/// notifies listeners so the screen can rebuild with the updated
/// conversation. No business logic lives in the widgets themselves.
class ChatFlowHandler extends ChangeNotifier {
  ChatFlowHandler(this._chatService, Conversation initialConversation)
    : conversation = initialConversation;

  final ChatService _chatService;

  Conversation conversation;
  bool isBusy = false;
  String? error;

  Future<void> submit(String text) async {
    if (text.trim().isEmpty || isBusy) return;
    isBusy = true;
    error = null;
    notifyListeners();

    try {
      conversation = await _chatService.sendMessage(
        conversationId: conversation.id,
        content: text,
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
