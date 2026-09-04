import '../../dal/local/local_storage_adapter.dart';

/// Persists an in-progress, unsent prompt draft per conversation id, so
/// switching conversations in the chat UI never silently discards text the
/// user has typed but not yet sent (issue #7).
///
/// Backed by [LocalStorageAdapter] (`shared_preferences` under the hood),
/// keyed by conversation id so each conversation keeps its own draft. This
/// is intentionally a thin, synchronous-looking wrapper: callers (the prompt
/// input widget, `ChatFlowHandler`) own debouncing and in-memory state, this
/// service only knows how to read/write/clear one draft string.
class DraftStoreService {
  const DraftStoreService({LocalStorageAdapter? localStorageAdapter})
    : _localStorage = localStorageAdapter ?? const LocalStorageAdapter();

  final LocalStorageAdapter _localStorage;

  static const _keyPrefix = 'draft:';

  String _keyFor(String conversationId) => '$_keyPrefix$conversationId';

  /// Returns the persisted draft for [conversationId], or `''` when there is
  /// none (an empty draft and "no draft" are treated the same by callers).
  Future<String> loadDraft(String conversationId) async {
    final value = await _localStorage.readString(_keyFor(conversationId));
    return value ?? '';
  }

  /// Persists [text] as the draft for [conversationId]. An empty [text]
  /// clears the draft instead of storing an empty string, keeping storage
  /// tidy once the user deletes everything they typed.
  Future<void> saveDraft(String conversationId, String text) async {
    if (text.isEmpty) {
      await clearDraft(conversationId);
      return;
    }
    await _localStorage.writeString(_keyFor(conversationId), text);
  }

  /// Removes any persisted draft for [conversationId], e.g. once its text
  /// has actually been sent as a message.
  Future<void> clearDraft(String conversationId) async {
    await _localStorage.remove(_keyFor(conversationId));
  }
}
