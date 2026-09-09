// Verifies DraftStoreService persists a per-conversation draft through the
// real LocalStorageAdapter (backed by shared_preferences' mocked in-memory
// values, no platform channel touched) and that ChatFlowHandler restores the
// right draft when switching between conversations (issue #7).

import 'dart:async';
import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api_adapter.dart';
import 'package:cortex/domain/models/conversation.dart';
import 'package:cortex/domain/services/chat_service.dart';
import 'package:cortex/domain/services/draft_store_service.dart';
import 'package:cortex/presentation/frontend/handlers/chat_flow_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}

/// A fake streaming-capable http client (same shape used by
/// chat_service_test.dart / cortex_api_adapter_test.dart) so no real network
/// call is ever made from these tests.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._respond);

  final FutureOr<http.StreamedResponse> Function(http.BaseRequest request)
  _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _respond(request);
  }
}

ChatService _chatServiceWithFakeStream() {
  final client = _FakeHttpClient((request) async {
    final frames = [
      'data: ${jsonEncode({
        "choices": [
          {
            "delta": {"content": "ok"},
          },
        ],
      })}\n\n',
      'data: [DONE]\n\n',
    ];
    return http.StreamedResponse(
      Stream.fromIterable(frames.map(utf8.encode)),
      200,
    );
  });
  return ChatService(
    cortexApiAdapter: CortexApiAdapter(
      apiForAppsBaseUrl: 'http://test.local',
      httpClient: client,
    ),
    initialConversations: [
      Conversation(
        id: 'conv-1',
        title: 'Conversation 1',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Conversation(
        id: 'conv-2',
        title: 'Conversation 2',
        messages: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DraftStoreService', () {
    test('loadDraft returns empty string when nothing was saved', () async {
      const store = DraftStoreService();
      expect(await store.loadDraft('conv-1'), '');
    });

    test(
      'saveDraft then loadDraft round-trips the text for that conversation',
      () async {
        const store = DraftStoreService();
        await store.saveDraft('conv-1', 'half-typed message');

        expect(await store.loadDraft('conv-1'), 'half-typed message');
        // A different conversation id keeps its own, independent draft.
        expect(await store.loadDraft('conv-2'), '');
      },
    );

    test('saveDraft with an empty string clears the persisted draft', () async {
      const store = DraftStoreService();
      await store.saveDraft('conv-1', 'something');
      expect(await store.loadDraft('conv-1'), 'something');

      await store.saveDraft('conv-1', '');
      expect(await store.loadDraft('conv-1'), '');
    });

    test('clearDraft removes a persisted draft', () async {
      const store = DraftStoreService();
      await store.saveDraft('conv-1', 'something');
      await store.clearDraft('conv-1');
      expect(await store.loadDraft('conv-1'), '');
    });
  });

  group('ChatFlowHandler draft persistence across conversation switches', () {
    test(
      'restores a conversation-specific draft when switching back to it',
      () async {
        final chatService = _chatServiceWithFakeStream();
        const draftStore = DraftStoreService();
        final conversations = chatService.listConversations();
        final first = conversations[0];
        final second = conversations[1];

        // Pre-seed drafts as if the user had typed in both conversations
        // during an earlier session.
        await draftStore.saveDraft(first.id, 'draft for first conversation');
        await draftStore.saveDraft(second.id, 'draft for second conversation');

        final handler = ChatFlowHandler(
          chatService,
          first,
          draftStore: draftStore,
        );
        await _flushMicrotasks();
        expect(handler.draftText, 'draft for first conversation');

        handler.switchConversation(second);
        await _flushMicrotasks();
        expect(handler.draftText, 'draft for second conversation');

        handler.switchConversation(first);
        await _flushMicrotasks();
        expect(handler.draftText, 'draft for first conversation');
      },
    );

    test(
      'updateDraft persists the typed text so it survives a switch away and back',
      () async {
        final chatService = _chatServiceWithFakeStream();
        const draftStore = DraftStoreService();
        final conversations = chatService.listConversations();
        final first = conversations[0];
        final second = conversations[1];

        final handler = ChatFlowHandler(
          chatService,
          first,
          draftStore: draftStore,
        );
        await _flushMicrotasks();

        handler.updateDraft('typed but never sent');
        expect(handler.draftText, 'typed but never sent');
        // updateDraft debounces the actual write, give it time to land.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(await draftStore.loadDraft(first.id), 'typed but never sent');

        handler.switchConversation(second);
        await _flushMicrotasks();
        expect(handler.draftText, '');

        handler.switchConversation(first);
        await _flushMicrotasks();
        expect(handler.draftText, 'typed but never sent');
      },
    );

    test(
      'submit clears the draft for the conversation the message was sent in',
      () async {
        final chatService = _chatServiceWithFakeStream();
        const draftStore = DraftStoreService();
        final conversation = chatService.listConversations().first;

        await draftStore.saveDraft(conversation.id, 'leftover draft');
        final handler = ChatFlowHandler(
          chatService,
          conversation,
          draftStore: draftStore,
        );
        await _flushMicrotasks();
        expect(handler.draftText, 'leftover draft');

        await handler.submit('an actual message');
        await _flushMicrotasks();

        expect(handler.draftText, '');
        expect(await draftStore.loadDraft(conversation.id), '');
      },
    );
  });
}
