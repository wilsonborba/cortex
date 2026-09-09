// Tests ChatService's real (non-mocked) send paths, both wired through a
// CortexApiAdapter backed by a fake http.Client, no live backend involved.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  test(
    'sendMessage streams assistant tokens and reports incremental updates',
    () async {
      final client = _FakeHttpClient((request) async {
        final frames = [
          'data: ${jsonEncode({
            "choices": [
              {
                "delta": {"content": "Hi "},
              },
            ],
          })}\n\n',
          'data: ${jsonEncode({
            "choices": [
              {
                "delta": {"content": "there"},
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
    },
  );

  test(
    'sendMessage with useMemory calls /execute and does not stream',
    () async {
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
    },
  );

  test(
    'sendEphemeralMessage never sets capabilities.memory and forces capabilities.temporary (issue #6)',
    () async {
      final client = _FakeHttpClient((request) async {
        // Attachments force the native /execute route even with useMemory
        // left at its default (false), so an ephemeral message with an
        // attachment reaches /execute; here there is no attachment, but
        // sendEphemeralMessage always routes through /execute regardless.
        expect(request.url.path, endsWith('/execute'));
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
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
      final ephemeral = chatService.newEphemeralConversation(
        title: 'Incognito chat',
      );
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

  test(
    'sendMessage with needsWeb sets needs_web/capabilities.web and surfaces sources',
    () async {
      final client = _FakeHttpClient((request) async {
        final frames = [
          'data: ${jsonEncode({
            "choices": [
              {
                "delta": {"content": "See https://example.com/docs for more."},
              },
            ],
          })}\n\n',
          'data: [DONE]\n\n',
        ];
        final body =
            jsonDecode((request as http.Request).body) as Map<String, dynamic>;
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
    },
  );

  test(
    'sendMessage preserves partial text and marks the reply interrupted when '
    'the SSE connection drops mid-stream (issue #7)',
    () async {
      final client = _FakeHttpClient((request) async {
        final controller = StreamController<List<int>>();
        controller.add(
          utf8.encode(
            'data: ${jsonEncode({
              "choices": [
                {
                  "delta": {"content": "here is part of the ans"},
                },
              ],
            })}\n\n',
          ),
        );
        Future<void>.delayed(Duration.zero, () {
          controller.addError(const SocketException('connection reset'));
        });
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: const {'content-type': 'text/event-stream'},
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
        content: 'tell me something long',
      );

      final reply = result.messages.last;
      // The partial text already streamed in must not be discarded.
      expect(reply.content, 'here is part of the ans');
      expect(reply.interrupted, isTrue);
    },
  );

  test('continueGeneration retries the same prompt context and replaces the '
      'interrupted reply once a full answer comes back (issue #7)', () async {
    var callCount = 0;
    final client = _FakeHttpClient((request) async {
      callCount++;
      if (callCount == 1) {
        // First call: the original request, interrupted mid-stream.
        final controller = StreamController<List<int>>();
        controller.add(
          utf8.encode(
            'data: ${jsonEncode({
              "choices": [
                {
                  "delta": {"content": "partial answ"},
                },
              ],
            })}\n\n',
          ),
        );
        Future<void>.delayed(Duration.zero, () {
          controller.addError(const SocketException('connection reset'));
        });
        return http.StreamedResponse(
          controller.stream,
          200,
          headers: const {'content-type': 'text/event-stream'},
        );
      }
      // Second call: continueGeneration's retry, this time it completes.
      final body =
          jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      // The retry must resend the same prompt context (just the user
      // message, none of the interrupted assistant reply).
      final messages = body['messages'] as List<dynamic>;
      expect(
        messages.any((m) => (m as Map)['content'] == 'partial answ'),
        isFalse,
      );
      final frames = [
        'data: ${jsonEncode({
          "choices": [
            {
              "delta": {"content": "a full retried answer"},
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

    final chatService = ChatService(
      cortexApiAdapter: CortexApiAdapter(
        apiForAppsBaseUrl: 'http://test.local',
        httpClient: client,
      ),
    );

    final conversation = chatService.listConversations().first;
    final interrupted = await chatService.sendMessage(
      conversationId: conversation.id,
      content: 'tell me something long',
    );
    final replyId = interrupted.messages.last.id;
    expect(interrupted.messages.last.interrupted, isTrue);

    final resumed = await chatService.continueGeneration(
      conversation: interrupted,
      replyMessageId: replyId,
    );

    final finalReply = resumed.messages.firstWhere((m) => m.id == replyId);
    // Content is replaced (not appended to), and the interrupted flag is
    // cleared once the retry completes successfully. No new message is
    // added: the same message id is reused.
    expect(finalReply.content, 'a full retried answer');
    expect(finalReply.interrupted, isFalse);
    expect(resumed.messages.length, interrupted.messages.length);
    expect(callCount, 2);
  });

  test(
    'sendMessage surfaces a friendly error when the backend is unreachable',
    () async {
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
    },
  );

  test('renameConversation updates title and timestamp', () {
    final chatService = ChatService();
    final convo = chatService.listConversations().first;
    chatService.renameConversation(convo.id, 'New Renamed Title');

    final updated = chatService.conversationById(convo.id);
    expect(updated?.title, 'New Renamed Title');
  });

  test('togglePinConversation toggles isPinned boolean flag', () {
    final chatService = ChatService();
    final convo = chatService.listConversations().first;
    final initialPinned = convo.isPinned;

    chatService.togglePinConversation(convo.id);
    expect(chatService.conversationById(convo.id)?.isPinned, !initialPinned);

    chatService.togglePinConversation(convo.id);
    expect(chatService.conversationById(convo.id)?.isPinned, initialPinned);
  });

  test('deleteConversation removes item or resets to fresh conversation', () {
    final chatService = ChatService();
    final convos = chatService.listConversations();
    final targetId = convos.first.id;

    chatService.deleteConversation(targetId);
    expect(chatService.listConversations().any((c) => c.id == targetId), isFalse);
  });
}
