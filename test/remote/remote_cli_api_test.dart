import 'dart:async';
import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/dal/remote/remote_cli_api.dart';
import 'package:cortex/domain/models/api.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _ChunkedClient extends http.BaseClient {
  _ChunkedClient(this.chunks);
  final List<List<int>> chunks;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream<List<int>>.fromIterable(chunks),
        200,
        headers: const {'content-type': 'text/event-stream'},
      );
}

class _StreamedResponseClient extends http.BaseClient {
  _StreamedResponseClient(this.response);
  final http.StreamedResponse response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      response;
}

void main() {
  test('lists only the API-provided session fields', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/apps/cortex/v1/remote/sessions');
      return http.Response(
        jsonEncode({
          'message': 'Remote sessions loaded',
          'data': {
            'sessions': [
              {
                'session_id': 'session-1',
                'device_name': 'Linux laptop',
                'platform': 'linux',
                'last_seen_ms': 1234,
                'online': true,
              },
            ],
          },
        }),
        200,
      );
    });
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
    );

    final sessions = await api.sessions();

    expect(sessions, hasLength(1));
    expect(sessions.single.id, 'session-1');
    expect(sessions.single.deviceName, 'Linux laptop');
    expect(sessions.single.platform, 'linux');
    expect(sessions.single.online, isTrue);
  });

  test('posts prompt with explicit selected file ids', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/apps/cortex/v1/remote/sessions/s1/prompts');
      expect(jsonDecode(request.body), {
        'prompt': 'Review this image',
        'file_ids': ['fsm-file-7'],
      });
      return http.Response(
        '{"message":"Remote prompt queued","data":{"id":51,"kind":"prompt","payload":{"prompt":"Review this image","file_ids":["fsm-file-7"]},"created_at_ms":10}}',
        202,
      );
    });
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
    );

    expect(
      await api.sendPrompt('s1', 'Review this image', fileIds: ['fsm-file-7']),
      51,
    );
  });

  test('parses UTF-8 events when CRLF separators cross byte chunks', () async {
    final body = utf8.encode(
      'id: 5\r\ndata: {"id":5,"kind":"progress","payload":{"text":"กำลังอ่าน"},"created_at_ms":500}\r\n\r\n',
    );
    final client = MockClient((request) async {
      expect(request.headers['accept'], 'text/event-stream');
      expect(request.url.queryParameters['cursor'], '4');
      return http.Response('', 200);
    });
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
      streamClient: _ChunkedClient([
        for (final byte in body) [byte],
      ]),
    );

    final events = await api.events('s1', after: 4).toList();

    expect(events, hasLength(1));
    expect(events.single.id, 5);
    expect(events.single.kind, 'progress');
    expect(events.single.payload['text'], 'กำลังอ่าน');
  });

  test('rejects mismatched durable event ids instead of skipping them', () async {
    final client = MockClient((_) async => http.Response('', 200));
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
      streamClient: _ChunkedClient([
        utf8.encode(
          'id: 4\ndata: {"id":5,"kind":"progress","payload":{},"created_at_ms":500}\n\n',
        ),
      ]),
    );

    await expectLater(
      api.events('s1', after: 3).toList(),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'rejects an oversized SSE line without waiting for a delimiter',
    () async {
      final client = MockClient((_) async => http.Response('', 200));
      final api = RemoteCliApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: client,
        streamClient: _ChunkedClient([
          utf8.encode('data: ${'x' * (RemoteCliApi.maxSseLineCharacters + 1)}'),
        ]),
      );

      await expectLater(
        api.events('s1', after: 0).toList(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'bounds a frame made from several individually valid data lines',
    () async {
      final dataLine = 'x' * (RemoteCliApi.maxSseLineCharacters - 5);
      final frame = 'id: 1\n${'data: $dataLine\n' * 5}\n';
      final api = RemoteCliApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: MockClient((_) async => http.Response('', 200)),
        streamClient: _ChunkedClient([utf8.encode(frame)]),
      );

      await expectLater(
        api.events('s1', after: 0).toList(),
        throwsA(isA<FormatException>()),
      );
    },
  );

  test(
    'uses existing files route through CortexApi and rejects missing file id',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/apps/cortex/v1/files');
        expect(
          request.headers['content-type'],
          startsWith('multipart/form-data;'),
        );
        expect(request.body, contains('filename="photo.jpg"'));
        return http.Response(
          '{"message":"saved","data":{"file_id":"fsm-9"}}',
          201,
        );
      });
      final filesApi = CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: client,
        streamClient: client,
      );
      final api = RemoteCliApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: client,
        filesApi: filesApi,
      );

      expect(
        await api.uploadImage(
          name: 'photo.jpg',
          bytes: [1, 2],
          contentType: 'image/jpeg',
        ),
        'fsm-9',
      );
    },
  );

  test(
    'downloads an artifact through the authenticated existing files route',
    () async {
      final image = [137, 80, 78, 71, 13, 10, 26, 10, 0];
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/apps/cortex/v1/files/file-9/content');
        expect(request.url.queryParameters, {'app_id': 'cortex'});
        expect(request.headers['content-type'], isNull);
        return http.Response.bytes(
          image,
          200,
          headers: const {'content-type': 'image/png'},
        );
      });
      final filesApi = CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: client,
        streamClient: client,
      );
      final api = RemoteCliApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: client,
        filesApi: filesApi,
      );

      final content = await api.artifactImage('file-9');

      expect(content.contentType, 'image/png');
      expect(content.bytes, image);
    },
  );

  test('bounds file content and preserves expired status', () async {
    final oversized = CortexApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: MockClient(
        (_) async => http.Response.bytes(
          [1, 2, 3],
          200,
          headers: const {'content-type': 'image/png'},
        ),
      ),
    );
    await expectLater(
      oversized.downloadFileContent('f', maxBytes: 2),
      throwsA(isA<ApiError>().having((error) => error.status, 'status', 413)),
    );

    final expired = CortexApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: MockClient(
        (_) async => http.Response(
          '{"message":"File expired","data":{"error_number":1051}}',
          404,
        ),
      ),
    );
    await expectLater(
      expired.downloadFileContent('expired'),
      throwsA(isA<ApiError>().having((error) => error.status, 'status', 404)),
    );
  });

  test('bounds declared and streamed file error responses', () async {
    var declaredStreamCancelled = false;
    final declaredStream = StreamController<List<int>>(
      onCancel: () => declaredStreamCancelled = true,
    );
    final declared = CortexApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: _StreamedResponseClient(
        http.StreamedResponse(
          declaredStream.stream,
          404,
          contentLength: CortexApi.maxFileErrorResponseBytes + 1,
        ),
      ),
    );
    await expectLater(
      declared.downloadFileContent('expired'),
      throwsA(
        isA<ApiError>()
            .having((error) => error.status, 'status', 404)
            .having((error) => error.number, 'number', isNull),
      ),
    );
    expect(declaredStreamCancelled, isTrue);

    var deliveredChunks = 0;
    Stream<List<int>> oversizedChunks() async* {
      deliveredChunks++;
      yield List.filled(CortexApi.maxFileErrorResponseBytes, 0);
      deliveredChunks++;
      yield [1];
      deliveredChunks++;
      yield [2];
    }

    final streamed = CortexApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: _StreamedResponseClient(
        http.StreamedResponse(oversizedChunks(), 404),
      ),
    );
    await expectLater(
      streamed.downloadFileContent('expired'),
      throwsA(
        isA<ApiError>()
            .having((error) => error.status, 'status', 404)
            .having((error) => error.number, 'number', isNull),
      ),
    );
    expect(deliveredChunks, 2);
  });

  test('times out and cancels an idle file error response stream', () async {
    var streamCancelled = false;
    late Future<void> expectation;
    fakeAsync((async) {
      var streamListened = false;
      final stalledStream = StreamController<List<int>>(
        onListen: () => streamListened = true,
        onCancel: () => streamCancelled = true,
      );
      final api = CortexApi(
        baseUrl: 'https://api.test/apps/cortex/v1',
        client: _StreamedResponseClient(
          http.StreamedResponse(stalledStream.stream, 503),
        ),
      );
      expectation = expectLater(
        api.downloadFileContent('stalled'),
        throwsA(
          isA<ApiError>()
              .having((error) => error.status, 'status', 503)
              .having(
                (error) => error.message,
                'message',
                contains('timed out'),
              ),
        ),
      );

      async.flushMicrotasks();
      expect(streamListened, isTrue);
      expect(async.nonPeriodicTimerCount, greaterThan(0));
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
    });
    await expectation;
    expect(streamCancelled, isTrue);
  });
}
