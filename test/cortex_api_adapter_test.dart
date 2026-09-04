// Tests for CortexApiAdapter's SSE parsing and /execute wiring, run
// entirely against a fake `http.Client` (extends `http.BaseClient`, no live
// api_for_apps/cortex_api server involved). This is the seam issue #3 fills
// in: streaming chat completions and native memory-recall execution.

import 'dart:async';
import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api_adapter.dart';
import 'package:cortex/domain/models/chat_message.dart';
import 'package:cortex/domain/models/execute_request.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// A fake streaming-capable client: records the last request it received
/// and replies with whatever `_respond` returns, without touching the
/// network. Mirrors the shape of api_for_apps' real SSE/JSON responses.
class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._respond);

  final FutureOr<http.StreamedResponse> Function(http.BaseRequest request)
  _respond;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return _respond(request);
  }
}

http.StreamedResponse _sseResponse(List<String> frames, {int statusCode = 200}) {
  final bytes = frames.map((f) => utf8.encode(f)).toList();
  return http.StreamedResponse(
    Stream.fromIterable(bytes),
    statusCode,
    headers: const {'content-type': 'text/event-stream'},
  );
}

void main() {
  group('CortexApiAdapter.streamChatCompletion', () {
    test('parses chat.completion.chunk SSE frames into content deltas', () async {
      final client = _FakeHttpClient((request) async {
        return _sseResponse([
          'data: ${jsonEncode({
            "id": "chatcmpl-1",
            "object": "chat.completion.chunk",
            "created": 1,
            "model": "cortex-t0",
            "choices": [
              {"index": 0, "delta": {"role": "assistant"}, "finish_reason": null},
            ],
          })}\n\n',
          'data: ${jsonEncode({
            "id": "chatcmpl-1",
            "object": "chat.completion.chunk",
            "created": 1,
            "model": "cortex-t0",
            "choices": [
              {"index": 0, "delta": {"content": "Hello "}, "finish_reason": null},
            ],
          })}\n\n',
          'data: ${jsonEncode({
            "id": "chatcmpl-1",
            "object": "chat.completion.chunk",
            "created": 1,
            "model": "cortex-t0",
            "choices": [
              {"index": 0, "delta": {"content": "world"}, "finish_reason": null},
            ],
          })}\n\n',
          'data: ${jsonEncode({
            "id": "chatcmpl-1",
            "object": "chat.completion.chunk",
            "created": 1,
            "model": "cortex-t0",
            "choices": [
              {"index": 0, "delta": {}, "finish_reason": "stop"},
            ],
          })}\n\n',
          'data: [DONE]\n\n',
        ]);
      });

      final adapter = CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      );

      final deltas = await adapter
          .streamChatCompletion(
            messages: [
              ChatMessage(
                id: 'm1',
                role: MessageRole.user,
                content: 'hi',
                createdAt: DateTime.now(),
              ),
            ],
          )
          .toList();

      expect(deltas, ['Hello ', 'world']);

      final request = client.lastRequest! as http.Request;
      expect(
        request.url.toString(),
        'http://test.local/cortex/v1/v1/chat/completions',
      );
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['model'], 'cortex-t0');
      expect(body['stream'], true);
    });

    test('ignores malformed SSE frames instead of throwing', () async {
      final client = _FakeHttpClient((request) async {
        return _sseResponse([
          'data: not-json\n\n',
          'data: ${jsonEncode({
            "choices": [
              {"delta": {"content": "ok"}},
            ],
          })}\n\n',
          'data: [DONE]\n\n',
        ]);
      });

      final adapter = CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      );

      final deltas = await adapter
          .streamChatCompletion(messages: const [])
          .toList();

      expect(deltas, ['ok']);
    });

    test('throws CortexApiException on a non-200 status', () async {
      final client = _FakeHttpClient((request) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('boom')),
          500,
        );
      });

      final adapter = CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      );

      expect(
        () => adapter.streamChatCompletion(messages: const []).toList(),
        throwsA(isA<CortexApiException>()),
      );
    });
  });

  group('CortexApiAdapter.execute', () {
    test('posts to the double-prefixed /execute path and parses the response', () async {
      final client = _FakeHttpClient((request) async {
        expect(
          request.url.toString(),
          'http://test.local/cortex/v1/execute',
        );
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
                'response': 'recalled memory',
                'input_tokens': 0,
                'output_tokens': 0,
                'total_tokens': 0,
                'cost_usd': 0.0,
                'latency_ms': 15,
                'steps': [],
              }),
            ),
          ),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });

      final adapter = CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      );

      final result = await adapter.execute(
        const ExecuteRequest(prompt: 'remember this', useMemory: true),
      );

      expect(result.success, isTrue);
      expect(result.response, 'recalled memory');
      expect(result.strategyId, 'hippocampus_proxy_passthrough');

      final request = client.lastRequest! as http.Request;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['use_memory'], true);
      expect(body['capabilities'], {'memory': true});
      // Never sends any tier/model override: the client offers no UI for
      // it, and the proxy would strip it anyway.
      expect(body.containsKey('tier'), isFalse);
      expect(body.containsKey('force_model'), isFalse);
      expect(body.containsKey('force_provider'), isFalse);
    });

    test('throws CortexApiException on a non-200 status', () async {
      final client = _FakeHttpClient((request) async {
        return http.StreamedResponse(Stream.value(utf8.encode('bad')), 400);
      });

      final adapter = CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      );

      expect(
        () => adapter.execute(const ExecuteRequest(prompt: 'x')),
        throwsA(isA<CortexApiException>()),
      );
    });
  });
}
