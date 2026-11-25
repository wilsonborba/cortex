import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/dal/remote/remote_cli_api.dart';
import 'package:cortex/domain/models/remote_cli.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      return http.Response('{"message":"Remote prompt queued","data":{}}', 202);
    });
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
    );

    await api.sendPrompt('s1', 'Review this image', fileIds: ['fsm-file-7']);
  });

  test('parses durable event ids and ignores malformed cursor blocks', () async {
    final sse = [
      'id: 5\ndata: {"id":5,"kind":"progress","payload":{"text":"reading"},"created_at_ms":500}\n\n',
      'id: 4\ndata: {"id":5,"kind":"progress","payload":{"text":"mismatch"},"created_at_ms":500}\n\n',
    ].join();
    final client = MockClient((request) async {
      expect(request.headers['accept'], 'text/event-stream');
      expect(request.url.queryParameters['cursor'], '4');
      return http.Response(
        sse,
        200,
        headers: {'content-type': 'text/event-stream'},
      );
    });
    final api = RemoteCliApi(
      baseUrl: 'https://api.test/apps/cortex/v1',
      client: client,
      streamClient: client,
    );

    final events = await api.events('s1', after: 4).toList();

    expect(events, hasLength(1));
    expect(events.single, isA<RemoteCliEvent>());
    expect(events.single.id, 5);
    expect(events.single.kind, 'progress');
    expect(events.single.payload['text'], 'reading');
  });

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
}
