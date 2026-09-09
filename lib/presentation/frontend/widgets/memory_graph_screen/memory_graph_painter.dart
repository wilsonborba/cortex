import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/memory_graph.dart';

/// Paints every edge as a gently-curved line between its two nodes'
/// positions. Nodes themselves are real widgets (see
/// `MemoryGraphNodeWidget`), stacked on top of this painter.
class MemoryGraphEdgePainter extends CustomPainter {
  MemoryGraphEdgePainter({
    required this.edges,
    required this.positionById,
    required this.lineColor,
  });

  final List<MemoryGraphEdge> edges;
  final Map<String, Offset> positionById;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = positionById[edge.sourceId];
      final to = positionById[edge.targetId];
      if (from == null || to == null) continue;

      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      // Gentle curve: bow the midpoint slightly perpendicular to the edge
      // so overlapping edges between the same rough area stay followable.
      final direction = to - from;
      final normal = Offset(-direction.dy, direction.dx);
      final normalLength = normal.distance;
      final bow = normalLength == 0 ? Offset.zero : normal / normalLength * 12;
      final control = mid + bow;

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MemoryGraphEdgePainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.positionById != positionById || oldDelegate.lineColor != lineColor;
  }
}

/// Per-[MemoryGraphNodeType] visual identity: an icon, a subtle accent
/// (staying within the app's monochrome-plus-one-accent palette, no rainbow
/// colors, just small alpha/hue nudges on top of the base ink color) and the
/// card's exact footprint.
///
/// [size] is the single source of truth for how much room a node of this
/// type occupies on the canvas: it drives both the card widget's own
/// [SizedBox] and the layout margin (`memory_graph_layout.dart`) and node
/// centering (`memory_graph_screen.dart`) math, so all three always agree on
/// the same footprint per type and a card can never clip past its own
/// declared bounds.
class MemoryGraphNodeStyle {
  const MemoryGraphNodeStyle({required this.icon, required this.accent, required this.size});

  final IconData icon;
  final Color accent;
  final Size size;

  static MemoryGraphNodeStyle forType(MemoryGraphNodeType type, ColorScheme scheme) {
    return MemoryGraphNodeStyle(
      icon: _iconForType(type),
      accent: _accentForType(type, scheme),
      size: sizeForType(type),
    );
  }

  static IconData _iconForType(MemoryGraphNodeType type) {
    switch (type) {
      case MemoryGraphNodeType.memory:
        return Icons.psychology_alt_outlined;
      case MemoryGraphNodeType.attachment:
        return Icons.attach_file_rounded;
      case MemoryGraphNodeType.tag:
        return Icons.sell_outlined;
      case MemoryGraphNodeType.entity:
        return Icons.person_outline_rounded;
      case MemoryGraphNodeType.resource:
        return Icons.link_rounded;
      case MemoryGraphNodeType.cluster:
        return Icons.hub_rounded;
      case MemoryGraphNodeType.unknown:
        return Icons.circle_outlined;
    }
  }

  static Color _accentForType(MemoryGraphNodeType type, ColorScheme scheme) {
    switch (type) {
      case MemoryGraphNodeType.memory:
        return scheme.onSurface;
      case MemoryGraphNodeType.attachment:
        return scheme.onSurface.withValues(alpha: 0.85);
      case MemoryGraphNodeType.tag:
        return scheme.secondary;
      case MemoryGraphNodeType.entity:
        return scheme.secondary;
      case MemoryGraphNodeType.resource:
        return scheme.onSurface.withValues(alpha: 0.7);
      case MemoryGraphNodeType.cluster:
        return scheme.onSurface;
      case MemoryGraphNodeType.unknown:
        return scheme.onSurface.withValues(alpha: 0.5);
    }
  }

  /// Fixed per-type card footprint (width, height). Deliberately a fixed
  /// size per type rather than content-driven sizing: it keeps the
  /// centering/margin math in the layout and screen exact instead of an
  /// estimate, while each type still gets a footprint that fits its own
  /// content (a tag chip is small, a memory card needs room for a snippet
  /// plus a date row plus a type row, etc).
  static Size sizeForType(MemoryGraphNodeType type) {
    switch (type) {
      case MemoryGraphNodeType.memory:
        return const Size(210, 96);
      case MemoryGraphNodeType.attachment:
        return const Size(190, 80);
      case MemoryGraphNodeType.tag:
        return const Size(120, 36);
      case MemoryGraphNodeType.entity:
        return const Size(170, 60);
      case MemoryGraphNodeType.resource:
        return const Size(180, 64);
      case MemoryGraphNodeType.cluster:
        return const Size(170, 74);
      case MemoryGraphNodeType.unknown:
        return const Size(150, 40);
    }
  }

  /// The largest footprint across every type, in each axis independently.
  /// Used to compute a layout margin that guarantees no card of any type can
  /// clip at the canvas edge (see `computeForceDirectedLayout`).
  static Size get maxSize {
    var maxWidth = 0.0;
    var maxHeight = 0.0;
    for (final type in MemoryGraphNodeType.values) {
      final size = sizeForType(type);
      maxWidth = math.max(maxWidth, size.width);
      maxHeight = math.max(maxHeight, size.height);
    }
    return Size(maxWidth, maxHeight);
  }
}
