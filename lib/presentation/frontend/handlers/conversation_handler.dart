import 'package:flutter/foundation.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

/// Sidebar/drawer conversation selection and listing. Filters and creation
/// flows are mocked for now: there is no persistence beyond the in-memory
/// list held by [ChatService].
class ConversationHandler extends ChangeNotifier {
  ConversationHandler(this._chatService)
    : conversations = _chatService.listConversations(),
      selectedId = _chatService.listConversations().first.id {
    _initRemote();
  }

  final ChatService _chatService;

  List<Conversation> conversations;
  String selectedId;

  Conversation get selected =>
      conversations.firstWhere((c) => c.id == selectedId, orElse: () => conversations.first);

  Future<void> _initRemote() async {
    final list = await _chatService.loadRemoteConversations();
    if (list.isNotEmpty) {
      conversations = list;
      if (!conversations.any((c) => c.id == selectedId)) {
        selectedId = conversations.first.id;
      }
      notifyListeners();
      await _loadSelectedDetails();
    }
  }

  Future<void> _loadSelectedDetails() async {
    final loaded = await _chatService.loadRemoteConversation(selectedId);
    if (loaded != null) {
      conversations = _chatService.listConversations();
      notifyListeners();
    }
  }

  Future<void> select(String id) async {
    if (id == selectedId) return;
    selectedId = id;
    notifyListeners();
    await _loadSelectedDetails();
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

  void rename(String id, String newTitle) {
    _chatService.renameConversation(id, newTitle);
    conversations = _chatService.listConversations();
    notifyListeners();
  }

  void togglePin(String id) {
    _chatService.togglePinConversation(id);
    conversations = _chatService.listConversations();
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
