import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';

/// The chat list of the sidebar (issue #31). The order comes from the API:
/// pinned first, then recent; the UI never sorts.
class ChatListController extends ChangeNotifier {
  ChatListController({required this.api});
  final CortexApi api;
  List<Map<String, dynamic>> chats = const [];
  Set<String> running = const {};
  bool loading = false;
  ApiError? error;

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      chats = await api.chats();
      running = {
        for (final c in await api.chats(running: true)) '${c['session_id']}',
      };
      error = null;
    } on ApiError catch (e) {
      error = e;
    } catch (_) {
      error = const ApiError(0, null, '');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> rename(String session, String title) async {
    await api.patchChat(session, {'title': title});
    await refresh();
  }

  Future<void> togglePin(Map<String, dynamic> chat) async {
    await api.patchChat('${chat['session_id']}', {
      'is_pinned': chat['is_pinned'] != true,
    });
    await refresh();
  }

  /// On an error the chat stays in the list (31.4); the caller offers Retry.
  Future<ApiError?> delete(String session) async {
    try {
      await api.deleteChat(session);
      await refresh();
      return null;
    } on ApiError catch (e) {
      return e;
    } catch (_) {
      return const ApiError(0, null, '');
    }
  }
}
