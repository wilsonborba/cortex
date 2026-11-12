// Synthetic release web benchmark for #55. It never opens an API connection.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cortex/presentation/frontend/screens/memory/graph_canvas.dart';
import 'graph_fixtures.dart';

void main() {
  final data = graphFixture(200), times = <double>[];
  var checksum = 0.0;
  for (var i = 0; i < 10; i++) {
    final watch = Stopwatch()..start();
    final positions = graphPositions(data);
    watch.stop();
    times.add(watch.elapsedMicroseconds / 1000);
    checksum += positions.values.first.dx;
  }
  final sorted = [...times]..sort();
  final result = jsonEncode({
    'nodes': data.nodes.length,
    'runs': times.length,
    'cold_ms': times.first,
    'median_ms': sorted[sorted.length ~/ 2],
    'max_ms': sorted.last,
    'checksum': checksum,
  });
  // ignore: avoid_print
  print('CORTEX_GRAPH_BENCH $result');
  runApp(MaterialApp(home: Scaffold(body: SelectableText(result))));
}
