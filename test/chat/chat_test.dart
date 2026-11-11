import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cortex/core/utils/file_picker.dart';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/chat_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const sid = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e0f';
const oid = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e10';

String sse(
  int id,
  String name,
  Map<String, Object?> data, [
  String message = '',
]) =>
    'id: $id\nevent: $name\ndata: ${jsonEncode({'message': message, 'data': data})}\n\n';

List<String> stream({List<String> middle = const [], bool done = true}) => [
  sse(1, 'stage', {
    'stage': 'accept',
    'status': 'started',
    'time_ms': 0,
    'expected_ms': 9000,
  }),
  sse(2, 'stage', {'stage': 'accept', 'status': 'ok', 'time_ms': 3}),
  sse(3, 'step', {
    'stage': 'gather',
    'step': 'memory.search',
    'params': {},
    'elapsed_ms': 0,
  }),
  ...middle,
  if (done)
    sse(90, 'done', {
      'session_id': sid,
      'output_id': oid,
      'tokens': {'input': 120, 'output': 8, 'total': 128},
      'total_ms': 4200,
    }),
];

/// Cortex API double: scripted SSE per request, JSON for the rest.
class Api {
  final requests = <(String, String, String)>[];
  List<String> Function(http.BaseRequest) streamFor = (_) => stream();
  bool keepOpen = false;
  int maxTokens = 5120;
  Map<String, dynamic> page = {
    'chat': {'session_id': sid, 'title': 'Saved chat', 'is_pinned': false},
    'inputs': [],
    'outputs': [
      {
        'input_id': 'i-new',
        'output_id': oid,
        'session_id': sid,
        'status': 'running',
        'text': '',
      },
    ],
  };
  final open = StreamController<List<int>>();

  late final client = MockClient.streaming((request, body) async {
    final text = await utf8.decodeStream(body);
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    requests.add((
      request.method,
      '$path${request.url.hasQuery ? '?${request.url.query}' : ''}',
      text,
    ));
    http.StreamedResponse json(Object data, [int status = 200]) =>
        http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(data))),
          status,
          headers: {'content-type': 'application/json'},
        );
    if (path == '/models') {
      return json({
        'message': 'Active model',
        'data': {
          'max_input_tokens': maxTokens,
          'estimate_rule': {
            'unit': 'utf8_bytes',
            'bytes_per_token': 3,
            'copies': 2,
          },
        },
      });
    }
    if (path == '/personas') return json({'message': '', 'data': []});
    if (path == '/files') {
      return json({
        'message': 'File saved',
        'data': {'file_id': 'r-1'},
      }, 201);
    }
    if (path == '/chats' && request.method == 'GET') {
      return json({
        'message': '',
        'data': [
          {'session_id': sid, 'updated_at': '2026-11-10T10:00:00Z'},
        ],
      });
    }
    if (path == '/chats/$sid' && request.method == 'GET') {
      return json({'message': '', 'data': page});
    }
    if (request.method == 'PATCH') {
      return json({
        'message': 'ok',
        'data': {'session_id': sid, 'output_id': oid},
      });
    }
    final events = streamFor(request);
    if (events.isEmpty) {
      return json({
        'message': 'Are you kidding me, clown?',
        'data': {'error_number': 1014},
      }, 400);
    }
    final out = Stream.fromIterable(events.map(utf8.encode));
    return http.StreamedResponse(
      keepOpen ? StreamGroup.merge([out, open.stream]) : out,
      200,
      headers: {'content-type': 'text/event-stream'},
    );
  });
}

/// Merges streams without an extra package.
class StreamGroup {
  static Stream<T> merge<T>(List<Stream<T>> streams) async* {
    for (final s in streams) {
      yield* s;
    }
  }
}

Future<(ChatController, Api)> pump(
  WidgetTester tester, {
  String? session,
  Api? api,
  List<PickedFile> files = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final fake = api ?? Api();
  final cortex = CortexApi(
    baseUrl: 'https://api.test/apps/cortex/v1',
    client: fake.client,
  );
  final chat = ChatController(
    api: cortex,
    sessionId: session,
    reconnectDelay: const Duration(milliseconds: 10),
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: cortexTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatScreen(
          api: cortex,
          details: DetailsController(),
          sessionId: session,
          controller: chat,
          picker: () async => files,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return (chat, fake);
}

/// A closed test stream looks like a lost connection, and the controller keeps
/// reconnecting; remove the screen and stop it before the test ends.
Future<void> stopReconnecting(WidgetTester tester, ChatController chat) async {
  await tester.pumpWidget(const SizedBox());
  chat.dispose();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> send(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('composer-text')), text);
  await tester.pump();
  await tester.tap(find.byKey(const Key('send')));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  testWidgets('composer uses the reading column and fits a narrow viewport', (
    tester,
  ) async {
    final (chat, _) = await pump(tester);
    expect(
      tester.getSize(find.byKey(const Key('composer'))).width,
      lessThanOrEqualTo(760),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('composer'))).dx,
      greaterThan(100),
    );
    tester.view.physicalSize = const Size(390, 844);
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const Key('composer'))).width,
      lessThan(390),
    );
    expect(tester.takeException(), isNull);
    await stopReconnecting(tester, chat);
  });

  testWidgets(
    'full stream: steps, tokens, sources, memories and the stats line',
    (tester) async {
      final (chat, api) = await pump(tester);
      expect(find.text('What do you want to know?'), findsOneWidget);
      api.streamFor = (_) => stream(
        middle: [
          sse(4, 'sources', {
            'sources': [
              {'title': 'Rust blog', 'url': 'https://blog.rust-lang.org/x'},
            ],
          }),
          sse(5, 'memories', {
            'memories': [
              {'id': 'm-1', 'title': 'Usage balancer'},
            ],
          }),
          sse(6, 'token', {'text': 'Hello '}),
          sse(7, 'token', {'text': '**world**'}),
        ],
      );
      await send(tester, 'hi');
      final post = api.requests.firstWhere(
        (r) => r.$1 == 'POST' && r.$2 == '/chats',
      );
      final body = jsonDecode(post.$3) as Map;
      expect(body, containsPair('app_id', 'cortex'));
      expect(body, containsPair('stream', true));
      expect(body, containsPair('needs_web', false));
      expect(body, containsPair('use_memory', false));
      expect(body, containsPair('thinking', false));
      expect(find.textContaining('Hello'), findsOneWidget);
      expect(
        find.textContaining('Rust blog · blog.rust-lang.org'),
        findsOneWidget,
      );
      expect(find.text('Used 1 memories'), findsOneWidget);
      expect(find.byKey(const Key('stats-line')), findsOneWidget);
      expect(chat.sessionId, sid);
    },
  );

  testWidgets(
    'thinking streams, and Stop thinking sends PATCH thinking false',
    (tester) async {
      final api = Api()..keepOpen = true;
      api.streamFor = (_) => stream(
        done: false,
        middle: [
          sse(4, 'stage', {
            'stage': 'think',
            'status': 'started',
            'time_ms': 0,
          }),
          sse(5, 'thinking', {'role': 'plan', 'round': 1, 'text': 'step one'}),
        ],
      );
      final (chat, _) = await pump(tester, api: api);
      await send(tester, 'think');
      expect(find.byKey(const Key('thinking-section')), findsOneWidget);
      expect(find.textContaining('step one'), findsOneWidget);
      await tester.tap(find.byKey(const Key('stop-thinking')));
      await tester.pump(const Duration(milliseconds: 50));
      final patch = api.requests.lastWhere((r) => r.$1 == 'PATCH');
      expect(patch.$2, '/chats/$sid/outputs/$oid');
      expect(jsonDecode(patch.$3), {'thinking': false});
      await api.open.close();
      await stopReconnecting(tester, chat);
    },
  );

  testWidgets('Send becomes Stop, and Stop sends PATCH status cancelled', (
    tester,
  ) async {
    final api = Api()..keepOpen = true;
    api.streamFor = (_) => stream(done: false);
    final (chat, _) = await pump(tester, api: api);
    await send(tester, 'long');
    expect(find.byKey(const Key('send')), findsNothing);
    await tester.tap(find.byKey(const Key('stop')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(jsonDecode(api.requests.lastWhere((r) => r.$1 == 'PATCH').$3), {
      'status': 'cancelled',
    });
    await api.open.close();
    await stopReconnecting(tester, chat);
  });

  testWidgets('a lost connection reconnects with ?after and loses no token', (
    tester,
  ) async {
    final api = Api();
    api.streamFor = (r) => r.url.path.endsWith('/events')
        ? [
            sse(5, 'token', {'text': 'B'}),
            sse(6, 'token', {'text': 'C'}),
            sse(90, 'done', {
              'session_id': sid,
              'output_id': oid,
              'tokens': {'input': 1, 'output': 3},
              'total_ms': 10,
            }),
          ]
        : stream(
            done: false,
            middle: [
              sse(4, 'token', {'text': 'A'}),
            ],
          );
    final (chat, _) = await pump(tester, api: api);
    await send(tester, 'go');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    final reconnect = api.requests.firstWhere((r) => r.$2.contains('/events'));
    expect(reconnect.$2, '/chats/$sid/outputs/$oid/events?after=4');
    expect(chat.exchanges.last.output.answer.toString(), 'ABC');
    expect(chat.exchanges.last.output.status, 'done');
    expect(find.byKey(const Key('reconnecting')), findsNothing);
  });

  testWidgets('a notice shows inline and the answer continues', (tester) async {
    final api = Api();
    api.streamFor = (_) => stream(
      middle: [
        sse(4, 'notice', {'notice_number': 1029}, 'Memory could not be loaded'),
        sse(5, 'token', {'text': 'still here'}),
      ],
    );
    await pump(tester, api: api);
    await send(tester, 'q');
    expect(find.text('Memory could not be loaded'), findsOneWidget);
    expect(find.textContaining('still here'), findsOneWidget);
  });

  testWidgets(
    'errors: the security block has an icon and no Retry; a model error has Retry',
    (tester) async {
      final api = Api();
      api.streamFor = (_) => const [];
      await pump(tester, api: api);
      await send(tester, 'bad');
      expect(find.text('Are you kidding me, clown?'), findsOneWidget);
      expect(find.byIcon(AppIcons.securityBlock), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      api.streamFor = (_) => stream(
        done: false,
        middle: [
          sse(4, 'error', {
            'error_number': 1012,
          }, 'The local model call failed'),
        ],
      );
      await send(tester, 'again');
      expect(find.text('The local model call failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    },
  );

  testWidgets(
    'token guardrail: counter near the limit and Send blocked over it',
    (tester) async {
      final api = Api()..maxTokens = 10;
      final (chat, _) = await pump(tester, api: api);
      expect(chat.budget.maxTokens, 10);
      // 15 bytes: ceil(15 / 3) * 2 = 10 tokens, above 80 % of the limit.
      await tester.enterText(
        find.byKey(const Key('composer-text')),
        'abcdefghijklmno',
      );
      await tester.pump();
      expect(find.text('10 of 10 tokens'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('composer-text')),
        'abcdefghijklmnopq',
      ); // 6 * 2 = 12
      await tester.pump();
      expect(find.textContaining('over the input limit'), findsOneWidget);
      final send = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('send')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(send.onPressed, isNull);
    },
  );

  testWidgets('files upload first through POST /files, then go as file_ids', (
    tester,
  ) async {
    final (_, api) = await pump(
      tester,
      files: [
        (name: 'plan.pdf', contentType: 'application/pdf', bytes: [1, 2, 3]),
      ],
    );
    await tester.tap(find.byKey(const Key('attach')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(api.requests.any((r) => r.$1 == 'POST' && r.$2 == '/files'), isTrue);
    expect(find.textContaining('plan.pdf'), findsOneWidget);
    await send(tester, 'read it');
    final body =
        jsonDecode(
              api.requests
                  .firstWhere((r) => r.$2 == '/chats' && r.$1 == 'POST')
                  .$3,
            )
            as Map;
    expect(body['file_ids'], ['r-1']);
  });

  testWidgets('opening a chat with a running output replays its events', (
    tester,
  ) async {
    final api = Api();
    api.page = {
      'chat': {'session_id': sid, 'title': 'Saved chat', 'is_pinned': false},
      'inputs': [
        {'input_id': 'i-1', 'text': 'earlier question'},
      ],
      'outputs': [
        {
          'input_id': 'i-1',
          'output_id': oid,
          'session_id': sid,
          'status': 'running',
          'text': '',
          'sources': [],
          'memories': [],
        },
      ],
    };
    api.streamFor = (r) => [
      sse(1, 'token', {'text': 'replayed'}),
      sse(2, 'done', {
        'session_id': sid,
        'output_id': oid,
        'tokens': {'input': 1, 'output': 1},
        'total_ms': 5,
      }),
    ];
    await pump(tester, session: sid, api: api);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(find.text('Saved chat'), findsOneWidget);
    expect(
      api.requests.any((r) => r.$2 == '/chats/$sid/outputs/$oid/events'),
      isTrue,
    );
    expect(find.textContaining('replayed'), findsOneWidget);
  });
  test(
    'history reload and older pages preserve chronological input/output pairs',
    () async {
      final fake = Api();
      Map<String, dynamic> page(int start) => {
        'chat': {'session_id': sid},
        'inputs': [
          for (var i = start + 19; i >= start; i--)
            {
              'input_id': 'i-$i',
              'text': 'question $i',
              'created_at': '2026-11-11T22:30:00Z',
            },
        ],
        'outputs': [
          for (var i = start; i < start + 20; i++)
            {
              'input_id': 'i-$i',
              'output_id': 'o-$i',
              'status': 'done',
              'text': 'answer $i',
            },
        ],
      };
      fake.page = page(20);
      final controller = ChatController(
        api: CortexApi(
          baseUrl: 'https://api.test/apps/cortex/v1',
          client: fake.client,
        ),
        sessionId: sid,
      );
      addTearDown(controller.dispose);
      await controller.open();
      expect(controller.exchanges.map((e) => e.text), [
        for (var i = 20; i < 40; i++) 'question $i',
      ]);
      await controller.open();
      expect(controller.exchanges.length, 20);
      fake.page = page(0);
      await Future.wait([controller.loadOlder(), controller.loadOlder()]);
      expect(controller.exchanges.map((e) => e.text), [
        for (var i = 0; i < 40; i++) 'question $i',
      ]);
      for (var i = 0; i < 40; i++) {
        expect(controller.exchanges[i].output.answer.toString(), 'answer $i');
      }
      expect(
        fake.requests.where((r) => r.$2.contains('before=i-20')).length,
        1,
      );
      expect(
        controller.exchanges.first.createdAt,
        DateTime.parse('2026-11-11T22:30:00Z').toLocal(),
      );
    },
  );

  testWidgets('both message roles copy and user timestamps use local time', (
    tester,
  ) async {
    final fake = Api();
    fake.page = {
      'chat': {'session_id': sid, 'title': 'Saved chat'},
      'inputs': [
        {
          'input_id': 'i-time',
          'text': 'Copy this question',
          'created_at': '2026-11-11T22:30:00Z',
        },
      ],
      'outputs': [
        {
          'input_id': 'i-time',
          'output_id': oid,
          'status': 'done',
          'text': 'Copy **this answer**',
        },
      ],
    };
    String? clipboard;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final (chat, _) = await pump(tester, session: sid, api: fake);
    expect(find.byType(SelectionArea), findsOneWidget);
    final stamp = tester.widget<Text>(
      find.byKey(const ValueKey('message-time-i-time')),
    );
    final context = tester.element(
      find.byKey(const ValueKey('message-time-i-time')),
    );
    final local = DateTime.parse('2026-11-11T22:30:00Z').toLocal();
    final format = MaterialLocalizations.of(context);
    expect(
      stamp.data,
      '${format.formatMediumDate(local)} ${format.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
    );
    await tester.tap(find.byTooltip('Copy').first);
    await tester.pump();
    expect(clipboard, 'Copy this question');
    await tester.tap(find.byTooltip('Copy').last);
    await tester.pump();
    expect(clipboard, 'Copy **this answer**');
    await stopReconnecting(tester, chat);
  });
}
