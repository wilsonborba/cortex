import 'package:flutter/foundation.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

/// Sidebar/drawer conversation selection and listing. Filters and creation
/// flows are mocked for now: there is no persistence beyond the in-memory
/// list held by [ChatService].
class ConversationHandler extends ChangeNotifier {
  ConversationHandler(this._chatService)
    : conversations = _chatService.listConversations(),
      selectedId = _chatService.listConversations().first.id;

  final ChatService _chatService;

  List<Conversation> conversations;
  String selectedId;

  Conversation get selected =>
      conversations.firstWhere((c) => c.id == selectedId);

  void select(String id) {
    if (id == selectedId) return;
    selectedId = id;
    notifyListeners();
  }

  void createNew({String title = 'New Conversation'}) {
    final created = _chatService.newConversation(title: title);
    conversations = _chatService.listConversations();
    selectedId = created.id;
    notifyListeners();
  }

  void clearAll() {
    _chatService.clearAllConversations();
    conversations = _chatService.listConversations();
    selectedId = conversations.first.id;
    notifyListeners();
  }

  void delete(String id) {
    _chatService.deleteConversation(id);
    conversations = _chatService.listConversations();
    if (!conversations.any((c) => c.id == selectedId)) {
      selectedId = conversations.first.id;
    }
    notifyListeners();
  }

  void refresh() {
    conversations = _chatService.listConversations();
    notifyListeners();
  }
}
