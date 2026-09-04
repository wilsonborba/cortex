// Tests ChatService's real (non-mocked) send paths, both wired through a
// CortexApiAdapter backed by a fake http.Client, no live backend involved.

import 'dart:async';
import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api_adapter.dart';
import 'package:cortex/domain/models/conversation.dart';
import 'package:cortex/domain/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._respond);

  final FutureOr<http.StreamedResponse> Function(http.BaseRequest request)
  _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _respond(request);
  }
}

void main() {
  test('sendMessage streams assistant tokens and reports incremental updates', () async {
    final client = _FakeHttpClient((request) async {
      final frames = [
        'data: ${jsonEncode({
          "choices": [
            {"delta": {"content": "Hi "}},
          ],
        })}\n\n',
        'data: ${jsonEncode({
          "choices": [
            {"delta": {"content": "there"}},
          ],
        })}\n\n',
        'data: [DONE]\n\n',
      ];
      return http.StreamedResponse(
        Stream.fromIterable(frames.map(utf8.encode)),
        200,
      );
    });

    final chatService = ChatService(
      cortexApiAdapter: CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      ),
    );

    final conversation = chatService.listConversations().first;
    final updates = <Conversation>[];

    final result = await chatService.sendMessage(
      conversationId: conversation.id,
      content: 'hello',
      onUpdate: updates.add,
    );

    expect(result.messages.last.content, 'Hi there');
    // At least: user message appended, then growing assistant deltas.
    expect(updates.length, greaterThanOrEqualTo(3));
    expect(updates.first.messages.last.content, 'hello');
  });

  test('sendMessage with useMemory calls /execute and does not stream', () async {
    final client = _FakeHttpClient((request) async {
      expect(request.url.path, endsWith('/execute'));
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({
              'request_id': 'req-1',
              'tier_requested': 0,
              'tier_executed': 0,
              'strategy_id': 'hippocampus_proxy_passthrough',
              'task_type': 'memory_recall',
              'success': true,
              'response': 'from memory',
              'input_tokens': 0,
              'output_tokens': 0,
              'total_tokens': 0,
              'cost_usd': 0.0,
              'latency_ms': 5,
              'steps': [],
            }),
          ),
        ),
        200,
      );
    });

    final chatService = ChatService(
      cortexApiAdapter: CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      ),
    );

    final conversation = chatService.listConversations().first;

    final result = await chatService.sendMessage(
      conversationId: conversation.id,
      content: 'what do you remember?',
      useMemory: true,
    );

    expect(result.messages.last.content, 'from memory');
  });

  test(
    'sendEphemeralMessage never sets capabilities.memory and forces capabilities.temporary (issue #6)',
    () async {
      final client = _FakeHttpClient((request) async {
        // Attachments force the native /execute route even with useMemory
        // left at its default (false), so an ephemeral message with an
        // attachment reaches /execute; here there is no attachment, but
        // sendEphemeralMessage always routes through /execute regardless.
        expect(request.url.path, endsWith('/execute'));
        final body = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
        expect(body['use_memory'], false);
        expect(body['capabilities'], {
          'memory': false,
          'web': false,
          'temporary': true,
        });
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'request_id': 'req-incognito',
                'tier_requested': 0,
                'tier_executed': 0,
                'strategy_id': 'ephemeral',
                'task_type': 'general',
                'success': true,
                'response': 'this is not remembered',
                'input_tokens': 0,
                'output_tokens': 0,
                'total_tokens': 0,
                'cost_usd': 0.0,
                'latency_ms': 5,
                'steps': [],
              }),
            ),
          ),
          200,
        );
      });

      final chatService = ChatService(
        cortexApiAdapter: CortexApiAdapter(
          apiForAppsBaseUrl: 'http://test.local',
          httpClient: client,
        ),
      );

      final before = chatService.listConversations();
      final ephemeral = chatService.newEphemeralConversation(title: 'Incognito chat');
      expect(ephemeral.isEphemeral, isTrue);

      final result = await chatService.sendEphemeralMessage(
        conversation: ephemeral,
        content: 'do not remember this',
      );

      expect(result.messages.last.content, 'this is not remembered');
      // The ephemeral conversation was never added to the persisted list.
      expect(chatService.listConversations().length, before.length);
      expect(chatService.conversationById(ephemeral.id), isNull);
    },
  );

  test('sendMessage with needsWeb sets needs_web/capabilities.web and surfaces sources', () async {
    final client = _FakeHttpClient((request) async {
      final frames = [
        'data: ${jsonEncode({
          "choices": [
            {"delta": {"content": "See https://example.com/docs for more."}},
          ],
        })}\n\n',
        'data: [DONE]\n\n',
      ];
      final body = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      expect(body['needs_web'], true);
      return http.StreamedResponse(
        Stream.fromIterable(frames.map(utf8.encode)),
        200,
      );
    });

    final chatService = ChatService(
      cortexApiAdapter: CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      ),
    );

    final conversation = chatService.listConversations().first;

    final result = await chatService.sendMessage(
      conversationId: conversation.id,
      content: 'what happened today?',
      needsWeb: true,
    );

    expect(result.messages.last.content, contains('example.com/docs'));
    expect(result.messages.last.sources, ['https://example.com/docs']);
  });

  test('sendMessage surfaces a friendly error when the backend is unreachable', () async {
    final client = _FakeHttpClient((request) async {
      return http.StreamedResponse(Stream.value(utf8.encode('boom')), 500);
    });

    final chatService = ChatService(
      cortexApiAdapter: CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      ),
    );

    final conversation = chatService.listConversations().first;

    final result = await chatService.sendMessage(
      conversationId: conversation.id,
      content: 'hello',
    );

    expect(result.messages.last.content, contains('could not reach Cortex'));
  });
}
