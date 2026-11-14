import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'persona_test.dart' as fixture;

// Synthetic memories. The search matches title, summary and person labels,
// like `GET /memory-graph/items` with `q` (cortex #73).
Map<String, dynamic> memory(
  String id,
  String title, {
  String summary = 'Synthetic summary',
  List<String> people = const [],
}) => {
  'id': id,
  'title': title,
  'summary': summary,
  'type': 'episodic',
  'source': {'kind': 'note', 'id': null, 'title': null},
  'created_at': '2026-11-10T12:00:00Z',
  'updated_at': '2026-11-10T12:00:00Z',
  'size_bytes': 100,
  'words': 20,
  'used_in_answers': 0,
  'last_used_at': null,
  'topics': [],
  'people': [
    for (final p in people) {'id': 'entity:$p', 'label': p},
  ],
  'files': [],
  'stack': null,
};

class Api extends fixture.Api {
  List<Map<String, dynamic>> memories = [
    memory('m-1', 'Lunch with Zeta'),
    memory('m-2', 'Planning call', people: ['Alias Zeta']),
    memory('m-3', 'Weekly notes', summary: 'Asked zeta about the trip.'),
    memory('m-4', 'Unrelated memory'),
  ];

  /// When not null, the items route says this total for every search.
  int? forcedTotal;
  bool itemsFail = false;
  final searches = <String>[];
  int overviewCalls = 0;

  late final memoryClient = MockClient((request) async {
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    http.Response reply(Object data, [int status = 200]) => http.Response(
      jsonEncode({'message': '', 'data': data}),
      status,
      headers: {'content-type': 'application/json'},
    );
    if (path == '/memory-graph/overview') {
      overviewCalls++;
      // The top 10 people of the overview. The persona is not one of them.
      return reply({
        'summary': {},
        'facets': {
          'people': [
            for (var i = 0; i < 10; i++)
              {'id': 'entity:p$i', 'label': 'Person $i', 'count': 50 - i},
          ],
        },
        'truncated': false,
      });
    }
    if (path == '/memory-graph/items') {
      final q = request.url.queryParameters['q'] ?? '';
      searches.add(q);
      if (itemsFail) return reply({'error_number': 1041}, 503);
      final n = q.toLowerCase();
      final hits = [
        for (final m in memories)
          if ('${m['title']}'.toLowerCase().contains(n) ||
              '${m['summary']}'.toLowerCase().contains(n) ||
              (m['people'] as List).any(
                (p) => '${p['label']}'.toLowerCase().contains(n),
              ))
            m,
      ];
      final limit = int.parse(request.url.queryParameters['limit'] ?? '50');
      return reply({
        'items': hits.take(limit).toList(),
        'groups': [],
        'next_cursor': null,
        'total': forcedTotal ?? hits.length,
      });
    }
    final copy = http.Request(request.method, request.url)
      ..headers.addAll(request.headers)
      ..bodyBytes = request.bodyBytes;
    return client.send(copy).then(http.Response.fromStream);
  });

  @override
  CortexApi get cortex => CortexApi(
    baseUrl: 'https://api.test/apps/cortex/v1',
    client: memoryClient,
  );
}

Future<void> open(WidgetTester tester, Api api) => fixture.pump(
  tester,
  api,
  path: '/v1/settings/personas/p1',
  brightness: Brightness.light,
);

String usedIn(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('persona-used-in'))).data!;

void main() {
  testWidgets('a persona outside the old top 10 people shows its memories', (
    tester,
  ) async {
    final api = Api();
    await open(tester, api);
    expect(find.text('Used in'), findsOneWidget);
    // m-2 matches the name and the alias. It counts once.
    expect(usedIn(tester), '3 memories mention this persona.');
    expect(api.searches, unorderedEquals(['Zeta', 'Alias Zeta']));
    expect(api.overviewCalls, 0);
  });

  testWidgets('one memory uses the singular text', (tester) async {
    final api = Api()
      ..memories = [
        memory('m-1', 'Lunch with Zeta'),
        memory('m-4', 'Unrelated memory'),
      ];
    await open(tester, api);
    expect(usedIn(tester), '1 memory mentions this persona.');
  });

  testWidgets('a real zero result keeps the empty text', (tester) async {
    final api = Api()..memories = [memory('m-4', 'Unrelated memory')];
    await open(tester, api);
    expect(usedIn(tester), 'No memory mentions this persona yet.');
  });

  testWidgets('a total larger than one page shows the total', (tester) async {
    final api = Api()..forcedTotal = 120;
    await open(tester, api);
    expect(usedIn(tester), '120 memories mention this persona.');
  });

  testWidgets('the search uses the name and at most two aliases', (
    tester,
  ) async {
    final api = Api();
    api.items.first['aliases'] = [
      'zeta',
      'Second alias',
      ' ',
      'Third alias',
      'Fourth alias',
    ];
    await open(tester, api);
    // "zeta" repeats the name and the empty alias is skipped.
    expect(
      api.searches,
      unorderedEquals(['Zeta', 'Second alias', 'Third alias']),
    );
  });

  testWidgets('a failed search hides Used in and keeps the detail', (
    tester,
  ) async {
    final api = Api()..itemsFail = true;
    await open(tester, api);
    expect(find.byKey(const Key('persona-detail')), findsOneWidget);
    expect(find.byKey(const Key('persona-used-in')), findsNothing);
    expect(find.text('Used in'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
