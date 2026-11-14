import 'dart:convert';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/screens/memory/tiny_map.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Synthetic memory scenario of cortex_api #121 as the API returns it: 3
/// chats, 2 files, 1 person, 4 topics, 13 memories titled "ola" in one chat
/// (merged into one row) and one memory used in 2 answers. 19 memories.
const memoryId = 'm-used';
const chatA = '0190f000-0000-7000-8000-00000000000a';
const chatB = '0190f000-0000-7000-8000-00000000000b';
const chatC = '0190f000-0000-7000-8000-00000000000c';

Map<String, dynamic> _item(
  String id,
  String title,
  String kind,
  String? sourceId,
  String? sourceTitle,
  String at, {
  int used = 0,
  int stack = 0,
  bool long = false,
}) => {
  'id': id,
  'title': long
      ? List.filled(12, 'Long synthetic memory title').join(' ')
      : title,
  'summary': 'Synthetic summary of $title',
  'type': kind == 'chat' ? 'episodic' : kind,
  'type_label': 'unused label',
  'source': {'kind': kind, 'id': sourceId, 'title': sourceTitle},
  'created_at': at,
  'updated_at': at,
  'size_bytes': 2048,
  'words': 310,
  'used_in_answers': used,
  'last_used_at': used > 0 ? '2026-11-10T16:00:00Z' : null,
  'status': 'active',
  'topics': [
    {'id': 'tag:project-cortex', 'label': 'Project: Cortex'},
  ],
  'people': <Map<String, dynamic>>[],
  'files': <Map<String, dynamic>>[],
  'stack': stack > 1
      ? {
          'count': stack,
          'ids': [
            for (var i = 0; i < stack; i++) 'm-ola-${'$i'.padLeft(2, '0')}',
          ],
          'first_at': '2026-11-10T13:50:00Z',
          'last_at': at,
        }
      : null,
};

List<Map<String, dynamic>> memoryItems({bool long = false}) => [
  _item(
    'm-ola-00',
    'ola',
    'chat',
    chatA,
    'Deploy problems',
    '2026-11-10T14:02:00Z',
    stack: 13,
  ),
  _item(
    'm-used',
    'Fix the Cloudflare deploy',
    'chat',
    chatA,
    'Deploy problems',
    '2026-11-10T09:30:00Z',
    used: 2,
    long: long,
  ),
  _item(
    'm-trip',
    'Train times to Chiang Mai',
    'chat',
    chatB,
    'Travel plan',
    '2026-11-09T11:00:00Z',
  ),
  _item(
    'm-books',
    'Books to read',
    'chat',
    chatC,
    'Reading list',
    '2026-11-08T20:15:00Z',
  ),
  _item(
    'm-file-1',
    'Quarterly report summary',
    'file',
    'f-1',
    'report.pdf',
    '2026-11-07T10:00:00Z',
  ),
  _item(
    'm-file-2',
    'Meeting notes',
    'file',
    'f-2',
    'notes.txt',
    '2026-11-06T08:00:00Z',
  ),
  _item(
    'm-note',
    'Prefers short answers',
    'note',
    null,
    null,
    '2026-11-05T12:00:00Z',
  ),
  if (long)
    for (var i = 0; i < 120; i++)
      _item(
        'm-long-$i',
        'Synthetic note $i',
        'note',
        null,
        null,
        '2026-10-20T12:00:00Z',
      ),
];

Map<String, dynamic> memoryOverview({
  bool empty = false,
  bool truncated = false,
}) => {
  'summary': {
    'memories': empty ? 0 : 19,
    'size_bytes': empty ? 0 : 38912,
    'chats': empty ? 0 : 3,
    'files': empty ? 0 : 2,
    'people': empty ? 0 : 1,
    'topics': empty ? 0 : 4,
    'notes': empty ? 0 : 1,
    'first_at': empty ? null : '2026-11-05T12:00:00Z',
    'last_at': empty ? null : '2026-11-10T14:02:00Z',
    'added_7_days': empty ? 0 : 19,
    'used_7_days': empty ? 0 : 1,
    'last_used_at': empty ? null : '2026-11-10T16:00:00Z',
  },
  'facets': {
    'sources': empty
        ? []
        : [
            {'kind': 'chat', 'label': 'Chats', 'count': 16},
            {'kind': 'file', 'label': 'Files', 'count': 2},
            {'kind': 'note', 'label': 'Saved notes', 'count': 1},
          ],
    'types': [],
    'months': [
      for (var m = 0; m < 12; m++)
        {
          'month': m < 1 ? '2025-12' : '2026-${'$m'.padLeft(2, '0')}',
          'count': empty
              ? 0
              : (m == 11
                    ? 19
                    : m == 10
                    ? 2
                    : 0),
        },
    ],
    'topics': [],
    'people': [],
  },
  'truncated': truncated,
};

final _groups = {
  'chat': [
    (
      'chat',
      chatA,
      'Deploy problems',
      14,
      '2026-11-10T09:30:00Z',
      '2026-11-10T14:02:00Z',
    ),
    (
      'chat',
      chatB,
      'Travel plan',
      1,
      '2026-11-09T11:00:00Z',
      '2026-11-09T11:00:00Z',
    ),
    (
      'chat',
      chatC,
      'Reading list',
      1,
      '2026-11-08T20:15:00Z',
      '2026-11-08T20:15:00Z',
    ),
  ],
  'file': [
    (
      'file',
      'f-1',
      'report.pdf',
      1,
      '2026-11-07T10:00:00Z',
      '2026-11-07T10:00:00Z',
    ),
    (
      'file',
      'f-2',
      'notes.txt',
      1,
      '2026-11-06T08:00:00Z',
      '2026-11-06T08:00:00Z',
    ),
  ],
  'person': [
    (
      'person',
      'entity:person-1',
      'Example Person',
      3,
      '2026-11-07T10:00:00Z',
      '2026-11-10T09:30:00Z',
    ),
  ],
  'topic': [
    (
      'topic',
      'tag:project-cortex',
      'Project: Cortex',
      5,
      '2026-11-05T12:00:00Z',
      '2026-11-10T14:02:00Z',
    ),
    (
      'topic',
      'tag:travel',
      'Travel',
      1,
      '2026-11-09T11:00:00Z',
      '2026-11-09T11:00:00Z',
    ),
    (
      'topic',
      'tag:reading',
      'Reading',
      1,
      '2026-11-08T20:15:00Z',
      '2026-11-08T20:15:00Z',
    ),
    (
      'topic',
      'tag:work',
      'Work',
      2,
      '2026-11-06T08:00:00Z',
      '2026-11-07T10:00:00Z',
    ),
  ],
};

Map<String, dynamic> _page(Map<String, String> q, {bool long = false}) {
  final source = q['source'] ?? 'all';
  final group = q['group_id'];
  final text = (q['q'] ?? '').toLowerCase();
  if (['chat', 'file', 'person', 'topic'].contains(source) && group == null) {
    return {
      'items': [],
      'groups': [
        for (final g in _groups[source]!)
          {
            'kind': g.$1,
            'id': g.$2,
            'title': g.$3,
            'count': g.$4,
            'first_at': g.$5,
            'last_at': g.$6,
          },
      ],
      'next_cursor': null,
      'total': _groups[source]!.length,
    };
  }
  final items = [
    for (final i in memoryItems(long: long))
      if ((source == 'all' || source == i['source']['kind'] || group != null) &&
          (group == null ||
              i['source']['id'] == group ||
              (group == 'tag:project-cortex')) &&
          (text.isEmpty || '${i['title']}'.toLowerCase().contains(text)))
        i,
  ];
  final limit = int.tryParse(q['limit'] ?? '') ?? 50;
  final start = int.tryParse(q['cursor'] ?? '') ?? 0;
  final page = items.skip(start).take(limit).toList();
  return {
    'items': page,
    'groups': [],
    'next_cursor': start + limit < items.length ? '${start + limit}' : null,
    'total': items.length,
  };
}

Map<String, dynamic>? memoryDetail(String id) {
  final ola = RegExp(r'^m-ola-(\d+)$').firstMatch(id);
  final base = ola != null
      ? _item(
          id,
          'ola',
          'chat',
          chatA,
          'Deploy problems',
          '2026-11-10T14:${ola.group(1)}:00Z',
        )
      : memoryItems().where((i) => i['id'] == id).firstOrNull;
  if (base == null) return null;
  final used = id == memoryId;
  return {
    'node': {'id': id, 'node_type': 'memory', 'label': base['title']},
    'nodes': [],
    'edges': [],
    'item': base,
    'content': ola != null
        ? 'Synthetic greeting number ${ola.group(1)} in the deploy chat.'
        : 'Synthetic content of ${base['title']}. The deploy failed because the build step used an old cache. Clearing the cache fixed it.',
    'usage': used
        ? [
            {
              'session_id': chatA,
              'chat_title': 'Deploy problems',
              'output_id': 'o-1',
              'used_at': '2026-11-10T16:00:00Z',
            },
            {
              'session_id': chatB,
              'chat_title': 'Travel plan',
              'output_id': 'o-2',
              'used_at': '2026-11-10T12:00:00Z',
            },
          ]
        : [],
    'connections': [
      if (base['source']['kind'] == 'chat')
        {
          'kind': 'source_chat',
          'target': {
            'id': base['source']['id'],
            'label': base['source']['title'],
            'node_type': 'chat',
          },
        },
      if (used) ...[
        {
          'kind': 'person',
          'target': {
            'id': 'entity:person-1',
            'label': 'Example Person',
            'node_type': 'entity',
          },
        },
        {
          'kind': 'topic',
          'target': {
            'id': 'tag:project-cortex',
            'label': 'Project: Cortex',
            'node_type': 'tag',
          },
        },
        {
          'kind': 'relation',
          'relation_type': 'supersedes',
          'target': {
            'id': 'm-note',
            'label': 'Old deploy note',
            'node_type': 'memory',
          },
        },
      ],
      if (ola != null) {'kind': 'same_title', 'count': 12},
    ],
    'map': {
      'nodes': [
        {'id': id, 'node_type': 'memory', 'label': base['title']},
        if (used) ...[
          {
            'id': 'tag:project-cortex',
            'node_type': 'tag',
            'label': 'Project: Cortex',
          },
          {
            'id': 'entity:person-1',
            'node_type': 'entity',
            'label': 'Example Person',
          },
          {'id': 'm-note', 'node_type': 'memory', 'label': 'Old deploy note'},
        ],
      ],
      'edges': [
        if (used)
          for (final t in ['tag:project-cortex', 'entity:person-1', 'm-note'])
            {'source_id': id, 'target_id': t, 'edge_type': 'related_to'},
      ],
    },
  };
}

/// The data of a memory route, or null for another path. Shared by the
/// layout and keyboard tests.
(int, Map<String, dynamic>)? memoryReply(
  Uri url, {
  String method = 'GET',
  bool long = false,
  bool empty = false,
}) {
  final path = url.path.replaceFirst('/apps/cortex/v1', '');
  if (path == '/memory-graph/overview') {
    return (200, memoryOverview(empty: empty));
  }
  if (path == '/memory-graph/items') {
    return (
      200,
      empty
          ? {'items': [], 'groups': [], 'next_cursor': null, 'total': 0}
          : _page(url.queryParameters, long: long),
    );
  }
  if (path.startsWith('/memory-graph/nodes/')) {
    final id = Uri.decodeComponent(
      path.substring('/memory-graph/nodes/'.length),
    );
    final detail = memoryDetail(id);
    if (detail == null) return (404, {'error_number': 1039});
    if (method == 'DELETE') return (200, {'node_id': id});
    return (200, detail);
  }
  return null;
}

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode({'message': '', 'data': data}),
  status,
  headers: {'content-type': 'application/json'},
);

class Api {
  final requests = <(String, Uri)>[];
  bool empty = false;
  bool long = false;
  late final client = MockClient((r) async {
    requests.add((r.method, r.url));
    final path = r.url.path.replaceFirst('/apps/cortex/v1', '');
    if (path == '/chats') return response([]);
    final reply = memoryReply(
      r.url,
      method: r.method,
      long: long,
      empty: empty,
    );
    if (reply != null) return response(reply.$2, reply.$1);
    return response({}, 404);
  });
  CortexApi get cortex =>
      CortexApi(baseUrl: 'https://api.test/apps/cortex/v1', client: client);
  Iterable<Uri> get(String path) => requests
      .where((r) => r.$1 == 'GET' && r.$2.path.endsWith(path))
      .map((r) => r.$2);
}

class Auth extends AuthService {
  Auth() : super(AuthApiAdapter());
}

Future<GoRouter> pump(
  WidgetTester tester,
  Api api, {
  String path = '/v1/settings/memory',
  Locale locale = const Locale('en'),
  Size size = const Size(1500, 950),
  double scale = 1,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    service: SessionService(cookieReader: () => 'fixture-csrf'),
  );
  await session.refresh();
  final router = buildRouter(
    session: session,
    auth: Auth(),
    initialLocation: path,
    api: api.cortex,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: locale,
      theme: cortexTheme(brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String location(GoRouter r) => r.routeInformationProvider.value.uri.path;

/// Every text on screen, for the "no raw names" check.
List<String> texts(WidgetTester tester) => [
  for (final t in tester.widgetList<Text>(find.byType(Text)))
    t.data ?? t.textSpan?.toPlainText() ?? '',
  for (final t in tester.widgetList<RichText>(find.byType(RichText)))
    t.text.toPlainText(),
];

void main() {
  testWidgets('summary, cards and 13 "ola" as one row with distinct lines', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api, size: const Size(1500, 2000));
    expect(find.byKey(const Key('memory-summary')), findsOneWidget);
    expect(
      find.textContaining(
        'Cortex keeps 19 memories (38.0 KB) from 3 chats, 2 files and 1 person.',
      ),
      findsOneWidget,
    );
    expect(find.text('Memories'), findsOneWidget);
    expect(find.text('Added in the last 7 days'), findsOneWidget);
    expect(find.text('By month'), findsOneWidget);
    // The 13 "ola" memories are one row with "13 similar" (#65 acceptance).
    expect(find.text('ola'), findsOneWidget);
    expect(find.text('13 similar'), findsOneWidget);
    expect(find.text('Used 2 times'), findsOneWidget);
    // Every visible row has a different second line.
    final lines = [
      for (final t in tester.widgetList<Text>(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('memory-line-'),
        ),
      ))
        t.data!,
    ];
    expect(lines, hasLength(7));
    expect(lines.toSet(), hasLength(7));
    expect(lines.first, startsWith('Chat: Deploy problems, '));
    // Only the API sends meaning: one overview and one items call.
    expect(api.get('/memory-graph/overview'), hasLength(1));
    expect(api.get('/memory-graph/items'), hasLength(1));
    expect(api.get('/memory-graph'), isEmpty);
  });

  testWidgets('no raw tag and no id is visible', (tester) async {
    final api = Api();
    final router = await pump(tester, api);
    router.go('/v1/settings/memory/$memoryId');
    await tester.pumpAndSettle();
    final all = texts(tester).join('\n');
    expect(all, isNot(contains('project-cortex')));
    expect(all, isNot(contains('tag:')));
    expect(all, isNot(contains('entity:')));
    expect(all, isNot(contains(memoryId)));
    expect(all, isNot(contains(chatA)));
    expect(all, isNot(contains('m-ola')));
  });

  testWidgets('facets: groups, a group, period, search and clear all', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api);
    await tester.tap(find.byKey(const Key('facet-chat')));
    await tester.pumpAndSettle();
    expect(
      api.get('/memory-graph/items').last.queryParameters['source'],
      'chat',
    );
    expect(find.byKey(const Key('group-$chatA')), findsOneWidget);
    expect(find.text('14 memories'), findsOneWidget);
    await tester.tap(find.byKey(const Key('group-$chatA')));
    await tester.pumpAndSettle();
    expect(
      api.get('/memory-graph/items').last.queryParameters['group_id'],
      chatA,
    );
    expect(find.text('Fix the Cloudflare deploy'), findsOneWidget);
    expect(find.byKey(const Key('active-filters')), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-to-groups')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('group-$chatB')), findsOneWidget);
    await tester.tap(find.byKey(const Key('period-week')));
    await tester.pumpAndSettle();
    expect(api.get('/memory-graph/items').last.queryParameters['period'], '7d');
    await tester.tap(find.byKey(const Key('clear-filters')));
    await tester.pumpAndSettle();
    final last = api.get('/memory-graph/items').last.queryParameters;
    expect(last['source'], 'all');
    expect(last['period'], 'all');
    await tester.enterText(
      find.byKey(const Key('memory-search')).last,
      'train',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(api.get('/memory-graph/items').last.queryParameters['q'], 'train');
    expect(find.text('Train times to Chiang Mai'), findsOneWidget);
    expect(find.text('Books to read'), findsNothing);
  });

  testWidgets('detail: facts, connections, usage, tiny map and delete', (
    tester,
  ) async {
    final api = Api();
    final router = await pump(tester, api);
    await tester.tap(find.byKey(const Key('memory-$memoryId')));
    await tester.pumpAndSettle();
    expect(location(router), '/v1/settings/memory/$memoryId');
    expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('memory-detail-panel'))).width,
      360,
    );
    expect(find.text('What Cortex keeps'), findsOneWidget);
    expect(find.text('From the chat Deploy problems'), findsOneWidget);
    expect(find.text('Mentions Example Person'), findsOneWidget);
    expect(find.text('Topic: Project: Cortex'), findsOneWidget);
    expect(find.text('Replaces Old deploy note'), findsOneWidget);
    expect(find.byKey(const Key('usage-o-1')), findsOneWidget);
    expect(find.byKey(const Key('usage-o-2')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('memory-picture')));
    await tester.tap(find.byKey(const Key('memory-picture')));
    await tester.pumpAndSettle();
    expect(find.byType(TinyMap), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('memory-delete')));
    await tester.tap(find.byKey(const Key('memory-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this memory?'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      api.requests.where(
        (r) =>
            r.$1 == 'DELETE' &&
            r.$2.path.endsWith('/memory-graph/nodes/$memoryId'),
      ),
      hasLength(1),
    );
    expect(location(router), '/v1/settings/memory');
    // The usage row opens the chat at that answer.
    router.go('/v1/settings/memory/$memoryId');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('usage-o-1')));
    await tester.tap(find.byKey(const Key('usage-o-1')));
    await tester.pumpAndSettle();
    expect(location(router), '/v1/chats/$chatA/outputs/o-1');
  });

  testWidgets('a merged row opens the copies with time and text', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api);
    await tester.tap(find.byKey(const Key('stack-m-ola-00')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stack-list-m-ola-00')), findsOneWidget);
    expect(find.textContaining('Synthetic greeting number 05'), findsOneWidget);
  });

  testWidgets('compact: filters in a sheet and the detail as a full page', (
    tester,
  ) async {
    final api = Api();
    final router = await pump(tester, api, size: const Size(390, 844));
    expect(find.byKey(const Key('memory-facets')), findsNothing);
    await tester.tap(find.byKey(const Key('memory-filters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-facets')), findsOneWidget);
    await tester.tap(find.byKey(const Key('facet-note')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-facets')), findsNothing);
    expect(
      api.get('/memory-graph/items').last.queryParameters['source'],
      'note',
    );
    router.go('/v1/settings/memory/$memoryId');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-summary')), findsNothing);
    expect(find.byType(BackButton), findsWidgets);
    expect(find.text('What Cortex keeps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium: the detail opens as a drawer', (tester) async {
    final api = Api();
    await pump(
      tester,
      api,
      size: const Size(900, 900),
      path: '/v1/settings/memory/$memoryId',
    );
    expect(find.byKey(const Key('memory-detail-panel')), findsOneWidget);
    expect(find.byKey(const Key('memory-facets')), findsNothing);
    expect(find.byKey(const Key('memory-filters')), findsOneWidget);
    await tester.tap(find.byKey(const Key('memory-detail-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('memory-detail-panel')), findsNothing);
  });

  testWidgets('empty: message and Start a chat', (tester) async {
    final api = Api()..empty = true;
    final router = await pump(tester, api);
    expect(find.byKey(const Key('memory-empty')), findsOneWidget);
    expect(
      find.text(
        'Cortex has no memories yet. Memories are saved when you chat with memory on.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Start a chat'));
    await tester.pumpAndSettle();
    expect(location(router), '/v1/chats');
  });

  testWidgets('long data at 200 percent in three languages', (tester) async {
    for (final locale in [
      const Locale('en'),
      const Locale('pt', 'BR'),
      const Locale('th'),
    ]) {
      for (final size in [
        const Size(390, 844),
        const Size(900, 900),
        const Size(1500, 950),
      ]) {
        final api = Api()..long = true;
        await pump(
          tester,
          api,
          locale: locale,
          size: size,
          scale: 2,
          path: '/v1/settings/memory/$memoryId',
        );
        expect(tester.takeException(), isNull, reason: '$locale $size');
        await tester.pumpWidget(const SizedBox());
      }
    }
  });
}
