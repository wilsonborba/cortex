import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'dart:async';
import 'dart:convert';
import 'graph_fixtures.dart';
import 'package:cortex/domain/models/memory_graph.dart';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/memory_controller.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cortex/presentation/frontend/screens/memory/graph_canvas.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const memoryId = 'memory-one';
const nodeIds = [memoryId, 'tag:t1', 'entity:p1', 'resource:f1'];
final now = DateTime.utc(2026, 11, 10, 12);
Map<String, dynamic> graph({String? focus, String? title}) {
  final nodes = [
    {
      'id': memoryId,
      'node_type': 'memory',
      'label': 'Saved decision',
      'metadata': {
        'title': title ?? 'Saved decision',
        'summary': 'First summary line\nSecond line\nThird line\nFourth line',
        'memory_type': 'episodic',
        'app_id': 'cortex',
        'created_at': '2026-11-09T12:00:00Z',
        'status': 'superseded',
      },
    },
    {
      'id': 'tag:t1',
      'node_type': 'tag',
      'label': 'project:cortex',
      'metadata': <String, dynamic>{},
    },
    {
      'id': 'entity:p1',
      'node_type': 'entity',
      'label': 'Wilson Borba',
      'metadata': {'entity_type': 'person'},
    },
    {
      'id': 'resource:f1',
      'node_type': 'file',
      'label': 'report.pdf',
      'metadata': {'title': 'report.pdf'},
    },
  ];
  return {
    'nodes': nodes,
    'edges': [
      for (final id in nodeIds.skip(1))
        {'source_id': memoryId, 'target_id': id, 'edge_type': 'related_to'},
    ],
    'truncated': false,
    if (focus != null) 'node': nodes.where((n) => n['id'] == focus).firstOrNull,
  };
}

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode({'message': '', 'data': data}),
  status,
  headers: {'content-type': 'application/json'},
);

class Api {
  final requests = <Uri>[];
  final graphResponses = <Completer<http.Response>>[];
  final nodeResponses = <String, Completer<http.Response>>{};
  bool deferGraph = false;
  bool failGraph = false;
  bool empty = false;
  bool isolated = false;
  bool single = false;
  String? title;
  Map<String, dynamic>? custom;
  late final client = MockClient((r) async {
    requests.add(r.url);
    final path = r.url.path.replaceFirst('/apps/cortex/v1', '');
    if (path == '/chats') return response([]);
    if (path == '/memory-graph') {
      if (deferGraph) {
        final pending = Completer<http.Response>();
        graphResponses.add(pending);
        return pending.future;
      }
      if (failGraph) return response({'error_number': 1029}, 503);
      if (empty) {
        return response({'nodes': [], 'edges': [], 'truncated': false});
      }
      final value = custom ?? graph(title: title);
      if (isolated || single) value['edges'] = [];
      if (single) value['nodes'] = (value['nodes'] as List).take(1).toList();
      return response(value);
    }
    if (path.startsWith('/memory-graph/nodes/')) {
      final id = Uri.decodeComponent(
        path.substring('/memory-graph/nodes/'.length),
      );
      if (nodeResponses.containsKey(id)) return nodeResponses[id]!.future;
      if (custom != null) {
        final node = (custom!['nodes'] as List)
            .where((n) => n['id'] == id)
            .firstOrNull;
        return node == null
            ? response({'error_number': 1039}, 404)
            : response({...custom!, 'node': node});
      }
      if (!nodeIds.contains(id)) return response({'error_number': 1039}, 404);
      return response(graph(focus: id, title: title));
    }
    return response({}, 404);
  });
  CortexApi get cortex =>
      CortexApi(baseUrl: 'https://api.test/apps/cortex/v1', client: client);
}

class Auth extends AuthService {
  Auth() : super(AuthApiAdapter());
}

Future<GoRouter> pump(
  WidgetTester tester,
  Api api, {
  String path = '/v1/memory',
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

void main() {
  testWidgets('refresh failure keeps the old graph with a retry action', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api);
    api.failGraph = true;
    final canvas = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    final old = Map.of(canvas.positions);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('depth')),
        matching: find.byType(AppSelect<int>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(GraphCanvas), findsOneWidget);
    expect(
      tester.state<GraphCanvasState>(find.byType(GraphCanvas)).positions,
      old,
    );
  });
  testWidgets('stack expansion and search use the same graph and list nodes', (
    tester,
  ) async {
    final data = graphFixture(6, stack: true);
    Map<String, dynamic> asJson(MemoryGraphData d) => {
      'nodes': [
        for (final n in d.nodes)
          {
            'id': n.id,
            'node_type': n.type,
            'label': n.label,
            'metadata': n.metadata,
          },
      ],
      'edges': [
        for (final e in d.edges)
          {'source_id': e.source, 'target_id': e.target, 'edge_type': e.type},
      ],
      'truncated': false,
    };
    final api = Api()..custom = asJson(data);
    await pump(tester, api);
    var state = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    expect(state.scene.nodes.length, 2);
    final old = Map.of(state.positions), matrix = state.transform.value.clone();
    final stack = state.scene.stacks.keys.single;
    await tester.tapAt(
      tester.getTopLeft(find.byType(InteractiveViewer)) +
          MatrixUtils.transformPoint(matrix, state.positions[stack]!),
    );
    await tester.pumpAndSettle();
    state = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    expect(state.scene.nodes.length, 6);
    expect(state.positions, old);
    expect(state.transform.value, matrix);
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    for (final n in data.nodes) {
      expect(find.byKey(Key('list-node-${n.id}')), findsOneWidget);
    }
    await tester.enterText(
      find.byKey(const Key('graph-search')),
      'Example chat',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('list-node-synthetic-0')), findsOneWidget);
    expect(find.byKey(const Key('list-node-synthetic-1')), findsNothing);
  });

  testWidgets('a single unlinked memory opens the accessible list', (
    tester,
  ) async {
    final api = Api()..single = true;
    await pump(tester, api);
    expect(find.byKey(const Key('list-node-$memoryId')), findsOneWidget);
    expect(find.text('These memories have no links yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning to Memory fetches fresh saved nodes', (tester) async {
    final api = Api();
    final router = await pump(tester, api);
    final initial = api.requests
        .where((r) => r.path.endsWith('/memory-graph'))
        .length;
    router.go('/v1/home/faq');
    await tester.pumpAndSettle();
    router.go('/v1/memory');
    await tester.pumpAndSettle();
    expect(
      api.requests.where((r) => r.path.endsWith('/memory-graph')).length,
      initial + 1,
    );
  });

  testWidgets('selection keeps positions and the view matrix', (tester) async {
    final router = await pump(tester, Api(), path: '/v1/memory/$memoryId');
    final before = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    final positions = Map.of(before.positions),
        matrix = before.transform.value.clone();
    router.go('/v1/memory/entity:p1');
    await tester.pumpAndSettle();
    final after = tester.state<GraphCanvasState>(find.byType(GraphCanvas));
    expect(identical(before, after), isTrue);
    expect(after.positions, positions);
    expect(after.transform.value, matrix);
    expect(tester.takeException(), isNull);
  });

  testWidgets('graph and list show the same API nodes and node paths', (
    tester,
  ) async {
    final api = Api();
    final router = await pump(tester, api);
    for (final id in nodeIds) {
      expect(
        tester
            .state<GraphCanvasState>(find.byType(GraphCanvas))
            .scene
            .nodes
            .map((n) => n.id),
        contains(id),
      );
    }
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('Persona'), findsOneWidget);
    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    for (final id in nodeIds) {
      expect(find.byKey(Key('list-node-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('list-node-$memoryId')));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/v1/memory/$memoryId',
    );
    expect(find.byKey(const Key('memory-card')), findsOneWidget);
    expect(find.byKey(const Key('memory-list')), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'report.pdf'));
    await tester.pumpAndSettle();
    expect(
      Uri.decodeComponent(router.routeInformationProvider.value.uri.path),
      '/v1/memory/resource:f1',
    );
    expect(find.byKey(const Key('card-title')), findsOneWidget);
    expect(
      api.requests
          .where((r) => r.path.contains('memory-graph'))
          .every((r) => r.queryParameters['app_id'] == 'cortex'),
      isTrue,
    );
  });
  testWidgets(
    'card fields, summary fallback, date hover, linked persona, hidden id and copy',
    (tester) async {
      final api = Api()..title = '';
      await pump(tester, api, path: '/v1/memory/$memoryId');
      expect(
        tester.widget<Text>(find.byKey(const Key('card-title'))).data,
        'First summary line',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('card-type'))).data,
        'Chat',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('card-app'))).data,
        'cortex',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('card-summary'))).maxLines,
        3,
      );
      final tooltip = tester.widget<Tooltip>(
        find
            .ancestor(
              of: find.byKey(const Key('card-date')),
              matching: find.byType(Tooltip),
            )
            .first,
      );
      expect(tooltip.message, contains('2026-11-09'));
      expect(find.byKey(const Key('card-superseded')), findsOneWidget);
      expect(find.text('WB'), findsOneWidget);
      expect(find.text('Wilson Borba'), findsWidgets);
      expect(find.text('#project:cortex'), findsOneWidget);
      expect(find.text(memoryId), findsNothing);
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
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
      await tester.tap(find.byKey(const Key('card-details')));
      await tester.pumpAndSettle();
      expect(find.text(memoryId), findsOneWidget);
      await tester.tap(find.byKey(const Key('copy-id')));
      await tester.pump();
      expect(copied, memoryId);
    },
  );
  testWidgets(
    'English, Thai and Brazilian Portuguese use translated static memory text',
    (tester) async {
      for (final entry in [
        (const Locale('en'), 'Graph', 'Details'),
        (const Locale('pt', 'BR'), 'Grafo', 'Detalhes'),
        (const Locale('th'), 'กราฟ', 'รายละเอียด'),
      ]) {
        await pump(
          tester,
          Api(),
          path: '/v1/memory/$memoryId',
          locale: entry.$1,
        );
        expect(find.text(entry.$2), findsOneWidget);
        expect(find.text(entry.$3), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'depth and limit are sent to the API without filtering nodes locally',
    (tester) async {
      final api = Api();
      await pump(tester, api);
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('depth')),
          matching: find.byType(AppSelect<int>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('limit')),
          matching: find.byType(AppSelect<int>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('200').last);
      await tester.pumpAndSettle();
      final requests = api.requests
          .where((uri) => uri.path.endsWith('/memory-graph'))
          .toList();
      expect(requests.last.queryParameters['depth'], '3');
      expect(requests.last.queryParameters['limit'], '200');
      for (final id in nodeIds) {
        expect(
          tester
              .state<GraphCanvasState>(find.byType(GraphCanvas))
              .scene
              .nodes
              .map((n) => n.id),
          contains(id),
        );
      }
    },
  );
  testWidgets(
    'compact memory card works at 200 percent text in all three languages',
    (tester) async {
      for (final locale in [
        const Locale('en'),
        const Locale('pt', 'BR'),
        const Locale('th'),
      ]) {
        await pump(
          tester,
          Api(),
          path: '/v1/memory/$memoryId',
          locale: locale,
          size: const Size(390, 844),
          scale: 2,
        );
        expect(find.byKey(const Key('memory-card')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
  test(
    'late graph and card replies cannot overwrite the current selection',
    () async {
      final api = Api()..deferGraph = true;
      final memory = MemoryController(api: api.cortex);
      final first = memory.load();
      await Future<void>.delayed(Duration.zero);
      memory.setDepth(3);
      await Future<void>.delayed(Duration.zero);
      api.graphResponses[1].complete(response(graph(title: 'Current')));
      await Future<void>.delayed(Duration.zero);
      api.graphResponses[0].complete(response(graph(title: 'Old')));
      await first;
      expect(memory.graph!.nodes.first.metadata['title'], 'Current');
      api.nodeResponses[memoryId] = Completer<http.Response>();
      final old = memory.open(memoryId);
      await Future<void>.delayed(Duration.zero);
      await memory.open('resource:f1');
      api.nodeResponses[memoryId]!.complete(response(graph(focus: memoryId)));
      await old;
      expect(memory.node!.node!.id, 'resource:f1');
      api.nodeResponses[memoryId] = Completer<http.Response>();
      final pending = memory.open(memoryId);
      await Future<void>.delayed(Duration.zero);
      await memory.open(null);
      api.nodeResponses[memoryId]!.complete(response(graph(focus: memoryId)));
      await pending;
      expect(memory.node, isNull);
      expect(memory.nodeLoading, isFalse);
      memory.dispose();
    },
  );
}
