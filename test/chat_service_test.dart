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
