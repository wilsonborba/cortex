import 'dart:math' as math;
import 'dart:ui' show Offset;

import '../../../../domain/models/memory_graph.dart';

/// A graph node together with its computed 2D position on the layout
/// canvas.
class PositionedGraphNode {
  PositionedGraphNode(this.node, this.position);

  final MemoryGraphNode node;
  Offset position;
}

/// Result of [computeForceDirectedLayout]: node positions plus the logical
/// canvas size they were laid out within.
class GraphLayout {
  const GraphLayout({
    required this.positions,
    required this.canvasSize,
  });

  final List<PositionedGraphNode> positions;
  final math.Point<double> canvasSize;
}

/// A small, dependency-free force-directed layout (Fruchterman-Reingold
/// style): repulsion between every pair of nodes, attraction along edges,
/// a fixed number of cooling iterations run once when the graph loads.
///
/// Deliberately simple rather than pulling in a graph-layout package (per
/// product constraint): this runs once on load for up to a few hundred
/// nodes, `O(nodes^2 * iterations)` is cheap enough there (a few hundred
/// thousand ops) without needing an isolate or a real physics engine.
GraphLayout computeForceDirectedLayout(
  MemoryGraph graph, {
  int iterations = 120,
}) {
  final nodes = graph.nodes;
  final n = nodes.length;
  if (n == 0) {
    return const GraphLayout(positions: [], canvasSize: math.Point(0, 0));
  }

  // Scale the canvas with node count so dense graphs don't pile up.
  final side = math.max(900.0, 220.0 * math.sqrt(n.toDouble()));
  final width = side;
  final height = side;
  final center = Offset(width / 2, height / 2);

  // Seeded so layout is stable across rebuilds/tests, not truly random.
  final random = math.Random(42);
  final positions = <String, Offset>{};
  final order = <String>[];
  for (var i = 0; i < n; i++) {
    final angle = (i / n) * 2 * math.pi;
    final radius = side * 0.35 * (0.5 + random.nextDouble() * 0.5);
    positions[nodes[i].id] = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    order.add(nodes[i].id);
  }

  final indexById = {for (var i = 0; i < order.length; i++) order[i]: i};
  final edges = graph.edges
      .where((e) => indexById.containsKey(e.sourceId) && indexById.containsKey(e.targetId))
      .toList();

  final k = math.sqrt((width * height) / n);
  var temperature = side / 10;
  final cooling = temperature / iterations;

  for (var iter = 0; iter < iterations; iter++) {
    final displacement = <String, Offset>{for (final id in order) id: Offset.zero};

    // Repulsion between every pair (Coulomb-like, capped so it never
    // explodes when two nodes start at nearly the same spot).
    for (var i = 0; i < order.length; i++) {
      final idA = order[i];
      final posA = positions[idA]!;
      for (var j = i + 1; j < order.length; j++) {
        final idB = order[j];
        final posB = positions[idB]!;
        var delta = posA - posB;
        var distance = delta.distance;
        if (distance < 0.01) {
          delta = Offset(random.nextDouble() - 0.5, random.nextDouble() - 0.5);
          distance = 0.01;
        }
        final force = (k * k) / distance;
        final push = delta / distance * force;
        displacement[idA] = displacement[idA]! + push;
        displacement[idB] = displacement[idB]! - push;
      }
    }

    // Attraction along edges (spring-like, pulls connected nodes closer).
    for (final edge in edges) {
      final posA = positions[edge.sourceId]!;
      final posB = positions[edge.targetId]!;
      final delta = posA - posB;
      final distance = math.max(delta.distance, 0.01);
      final force = (distance * distance) / k;
      final pull = delta / distance * force;
      displacement[edge.sourceId] = displacement[edge.sourceId]! - pull;
      displacement[edge.targetId] = displacement[edge.targetId]! + pull;
    }

    // Apply, capped by the cooling temperature, then re-center within bounds.
    for (final id in order) {
      final disp = displacement[id]!;
      final distance = math.max(disp.distance, 0.01);
      final capped = disp / distance * math.min(distance, temperature);
      var next = positions[id]! + capped;
      next = Offset(
        next.dx.clamp(40.0, width - 40.0),
        next.dy.clamp(40.0, height - 40.0),
      );
      positions[id] = next;
    }

    temperature = math.max(temperature - cooling, 1.0);
  }

  return GraphLayout(
    positions: [
      for (final node in nodes) PositionedGraphNode(node, positions[node.id] ?? center),
    ],
    canvasSize: math.Point(width, height),
  );
}
