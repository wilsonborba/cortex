import 'package:flutter/foundation.dart';

import '../../../domain/models/conversation.dart';
import '../../../domain/services/chat_service.dart';

/// Sidebar/drawer conversation selection and listing. Create/rename/pin/
/// delete all call through to [ChatService], which persists them via
/// `cortex_api`'s `/conversations` CRUD endpoints.
///
/// `conversations` (and therefore the sidebar) can be genuinely empty. When
/// it is, [selected] falls back to a client-only draft conversation (never
/// added to `conversations`, never persisted) purely so the chat screen
/// always has something to hand its composer, exactly like starting a new
/// chat before typing the first message. The draft becomes a real,
/// persisted conversation the moment a message is actually sent through it
/// (see `ChatService.sendMessage`'s doc comment).
class ConversationHandler extends ChangeNotifier {
  ConversationHandler(this._chatService)
    : conversations = _chatService.listConversations() {
    _ensureSelection();
    _initRemote();
  }

  final ChatService _chatService;

  List<Conversation> conversations;
  late String selectedId;
  Conversation? _draft;

  Conversation get selected {
    for (final c in conversations) {
      if (c.id == selectedId) return c;
    }
    return _draft!;
  }

  /// Keeps `selectedId`/`_draft` consistent after any mutation to
  /// `conversations`: drops the draft once a real conversation exists to
  /// select, or creates one when the list is genuinely empty.
  void _ensureSelection() {
    if (conversations.isEmpty) {
      _draft = _chatService.newDraftConversation();
      selectedId = _draft!.id;
    } else {
      _draft = null;
      if (!conversations.any((c) => c.id == selectedId)) {
        selectedId = conversations.first.id;
      }
    }
  }

  Future<void> _initRemote() async {
    final list = await _chatService.loadRemoteConversations();
    conversations = list;
    _ensureSelection();
    notifyListeners();
    if (conversations.isNotEmpty) await _loadSelectedDetails();
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
    _draft = null;
    notifyListeners();
    await _loadSelectedDetails();
  }

  Future<void> createNew({String title = 'New Conversation'}) async {
    final created = await _chatService.newConversation(title: title);
    conversations = _chatService.listConversations();
    selectedId = created.id;
    _draft = null;
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _chatService.clearAllConversations();
    conversations = _chatService.listConversations();
    _ensureSelection();
    notifyListeners();
  }

  Future<void> rename(String id, String newTitle) async {
    await _chatService.renameConversation(id, newTitle);
    conversations = _chatService.listConversations();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    await _chatService.togglePinConversation(id);
    conversations = _chatService.listConversations();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _chatService.deleteConversation(id);
    conversations = _chatService.listConversations();
    _ensureSelection();
    notifyListeners();
  }

  /// Refreshes from [ChatService]'s local state (no network call): used
  /// right after sending a message, which may have just adopted the draft
  /// into a real conversation.
  void refresh() {
    conversations = _chatService.listConversations();
    if (conversations.any((c) => c.id == selectedId)) {
      _draft = null;
    }
    notifyListeners();
  }
}
