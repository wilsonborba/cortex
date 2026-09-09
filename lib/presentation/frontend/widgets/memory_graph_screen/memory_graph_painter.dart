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

/// Per-[MemoryGraphNodeType] visual identity: an icon and a subtle accent,
/// staying within the app's monochrome-plus-one-accent palette (no rainbow
/// colors, just small alpha/hue nudges on top of the base ink color).
class MemoryGraphNodeStyle {
  const MemoryGraphNodeStyle({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  static MemoryGraphNodeStyle forType(MemoryGraphNodeType type, ColorScheme scheme) {
    switch (type) {
      case MemoryGraphNodeType.memory:
        return MemoryGraphNodeStyle(icon: Icons.psychology_alt_outlined, accent: scheme.onSurface);
      case MemoryGraphNodeType.attachment:
        return MemoryGraphNodeStyle(icon: Icons.attach_file_rounded, accent: scheme.onSurface.withValues(alpha: 0.85));
      case MemoryGraphNodeType.tag:
        return MemoryGraphNodeStyle(icon: Icons.sell_outlined, accent: scheme.secondary);
      case MemoryGraphNodeType.entity:
        return MemoryGraphNodeStyle(icon: Icons.person_outline_rounded, accent: scheme.secondary);
      case MemoryGraphNodeType.resource:
        return MemoryGraphNodeStyle(icon: Icons.link_rounded, accent: scheme.onSurface.withValues(alpha: 0.7));
      case MemoryGraphNodeType.cluster:
        return MemoryGraphNodeStyle(icon: Icons.hub_rounded, accent: scheme.onSurface);
      case MemoryGraphNodeType.unknown:
        return MemoryGraphNodeStyle(icon: Icons.circle_outlined, accent: scheme.onSurface.withValues(alpha: 0.5));
    }
  }
}
