// Tests for the memory graph feature: `MemoryGraph.fromJson` parsing
// (including lenient handling of unrecognized node/edge types) and the
// `MemoryGraphScreen` widget's empty and populated states, run entirely
// against a fake `http.Client` (mirrors `cortex_api_adapter_test.dart`'s
// house style, no live api_for_apps/cortex_api server involved).

import 'dart:async';
import 'dart:convert';

import 'package:cortex/dal/remote/cortex_api_adapter.dart';
import 'package:cortex/domain/models/memory_graph.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/widgets/memory_graph_screen/memory_graph_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._respond);

  final FutureOr<http.StreamedResponse> Function(http.BaseRequest request) _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return _respond(request);
  }
}

http.StreamedResponse _jsonResponse(Object body, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('MemoryGraph.fromJson', () {
    test('parses nodes, edges, root_ids and truncated', () {
      final graph = MemoryGraph.fromJson({
        'nodes': [
          {
            'id': 'mem-1',
            'node_type': 'memory',
            'label': 'A memory',
            'subtitle': 'subtitle',
            'metadata': {'foo': 'bar'},
          },
          {
            'id': 'tag:foo',
            'node_type': 'tag',
            'label': 'foo',
          },
        ],
        'edges': [
          {
            'source_id': 'mem-1',
            'target_id': 'tag:foo',
            'edge_type': 'tagged_with',
            'confidence': null,
          },
        ],
        'root_ids': ['mem-1'],
        'truncated': false,
      });

      expect(graph.nodes, hasLength(2));
      expect(graph.nodes[0].id, 'mem-1');
      expect(graph.nodes[0].nodeType, MemoryGraphNodeType.memory);
      expect(graph.nodes[0].subtitle, 'subtitle');
      expect(graph.nodes[0].metadata, {'foo': 'bar'});
      expect(graph.nodes[1].nodeType, MemoryGraphNodeType.tag);

      expect(graph.edges, hasLength(1));
      expect(graph.edges.first.sourceId, 'mem-1');
      expect(graph.edges.first.targetId, 'tag:foo');
      expect(graph.edges.first.edgeType, 'tagged_with');
      expect(graph.edges.first.confidence, isNull);

      expect(graph.rootIds, ['mem-1']);
      expect(graph.truncated, isFalse);
    });

    test('degrades unrecognized node_type/edge_type gracefully instead of throwing', () {
      final graph = MemoryGraph.fromJson({
        'nodes': [
          {'id': 'n1', 'node_type': 'some_future_type', 'label': 'X'},
        ],
        'edges': [
          {'source_id': 'n1', 'target_id': 'n1', 'edge_type': 'some_future_relationship'},
        ],
        'root_ids': [],
        'truncated': true,
      });

      expect(graph.nodes.single.nodeType, MemoryGraphNodeType.unknown);
      expect(graph.edges.single.edgeType, 'some_future_relationship');
      expect(graph.truncated, isTrue);
    });

    test('parses a cluster node with cluster_of metadata', () {
      final graph = MemoryGraph.fromJson({
        'nodes': [
          {
            'id': 'cluster-1',
            'node_type': 'cluster',
            'label': 'Cluster',
            'metadata': {
              'cluster_of': ['mem-1', 'mem-2'],
            },
          },
        ],
        'edges': [],
        'root_ids': [],
        'truncated': false,
      });

      expect(graph.nodes.single.nodeType, MemoryGraphNodeType.cluster);
      expect(graph.nodes.single.clusterOf, ['mem-1', 'mem-2']);
    });
  });

  group('MemoryGraphScreen', () {
    testWidgets('shows the empty-state message when the graph has no nodes', (tester) async {
      final client = _FakeHttpClient((request) async {
        return _jsonResponse({
          'nodes': [],
          'edges': [],
          'root_ids': [],
          'truncated': false,
        });
      });
      final adapter = CortexApiAdapter(apiForAppsBaseUrl: 'http://test.local', httpClient: client);

      await tester.pumpWidget(_wrap(MemoryGraphScreen(adapter: adapter)));
      await tester.pump();
      await tester.pump();

      expect(find.text('No memories yet'), findsOneWidget);
    });

    testWidgets('shows node widgets for a small fixture graph', (tester) async {
      final client = _FakeHttpClient((request) async {
        return _jsonResponse({
          'nodes': [
            {'id': 'mem-1', 'node_type': 'memory', 'label': 'Memory One'},
            {'id': 'mem-2', 'node_type': 'memory', 'label': 'Memory Two'},
            {'id': 'tag:foo', 'node_type': 'tag', 'label': 'foo'},
          ],
          'edges': [
            {'source_id': 'mem-1', 'target_id': 'tag:foo', 'edge_type': 'tagged_with'},
          ],
          'root_ids': ['mem-1'],
          'truncated': false,
        });
      });
      final adapter = CortexApiAdapter(apiForAppsBaseUrl: 'http://test.local', httpClient: client);

      await tester.pumpWidget(_wrap(MemoryGraphScreen(adapter: adapter)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Memory One'), findsOneWidget);
      expect(find.text('Memory Two'), findsOneWidget);
      expect(find.text('foo'), findsOneWidget);
    });

    testWidgets('shows the truncated banner when the graph was truncated', (tester) async {
      final client = _FakeHttpClient((request) async {
        return _jsonResponse({
          'nodes': [
            {'id': 'mem-1', 'node_type': 'memory', 'label': 'Memory One'},
          ],
          'edges': [],
          'root_ids': ['mem-1'],
          'truncated': true,
        });
      });
      final adapter = CortexApiAdapter(apiForAppsBaseUrl: 'http://test.local', httpClient: client);

      await tester.pumpWidget(_wrap(MemoryGraphScreen(adapter: adapter)));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('This view does not show the full graph, some nodes were left out.'),
        findsOneWidget,
      );
    });
  });
}
