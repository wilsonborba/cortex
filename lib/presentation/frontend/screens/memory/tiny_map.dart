import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/models/memory_overview.dart';
import '../../theme/tokens.dart';

/// The optional picture of one memory and its direct links (cortex #65): the
/// selected memory in the center, at most 12 neighbors on a circle, labels
/// always visible in `caption1`, edges 1 px `divider`, selected ring
/// `brandStroke1`. No zoom, no depth and no limit.
class TinyMap extends StatelessWidget {
  const TinyMap({super.key, required this.detail});
  final MemoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final names = [
      for (final n in detail.mapNodes)
        if (n.id != detail.item.id) n.label,
    ];
    return Semantics(
      label: [detail.item.title, ...names].join(', '),
      excludeSemantics: true,
      child: SizedBox(
        key: const Key('tiny-map'),
        height: 260,
        width: double.infinity,
        child: CustomPaint(
          painter: TinyMapPainter(
            detail: detail,
            palette: p,
            textScaler: MediaQuery.textScalerOf(context),
            direction: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class TinyMapPainter extends CustomPainter {
  TinyMapPainter({
    required this.detail,
    required this.palette,
    required this.textScaler,
    required this.direction,
  });
  final MemoryDetail detail;
  final Palette palette;
  final TextScaler textScaler;
  final TextDirection direction;

  static const _node = Space.s6;

  @override
  void paint(Canvas canvas, Size size) {
    final selected = detail.item.id;
    final others = [
      for (final n in detail.mapNodes)
        if (n.id != selected) n,
    ].take(12).toList();
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - Space.s32;
    final positions = <String, Offset>{selected: center};
    for (final (i, n) in others.indexed) {
      final angle = -math.pi / 2 + 2 * math.pi * i / others.length;
      positions[n.id] =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
    }
    final edge = Paint()
      ..color = palette.divider
      ..strokeWidth = Strokes.thin;
    for (final (a, b) in detail.mapEdges) {
      final pa = positions[a], pb = positions[b];
      if (pa != null && pb != null) canvas.drawLine(pa, pb, edge);
    }
    final fill = Paint()..color = palette.surface;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.thin
      ..color = palette.strokeAccessible;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.thick
      ..color = palette.brandStroke1;
    final labels = {
      selected: detail.item.title,
      for (final n in others) n.id: n.label,
    };
    for (final MapEntry(key: id, value: at) in positions.entries) {
      final isSelected = id == selected;
      canvas.drawCircle(at, _node, fill);
      canvas.drawCircle(at, _node, isSelected ? ring : stroke);
      final label = TextPainter(
        text: TextSpan(
          text: labels[id],
          style: (isSelected ? TextStyles.caption1Strong : TextStyles.caption1)
              .copyWith(color: isSelected ? palette.text : palette.text2),
        ),
        textDirection: direction,
        textScaler: textScaler,
        maxLines: 1,
        ellipsis: '…',
        textAlign: TextAlign.center,
      )..layout(maxWidth: 120);
      // Labels of the top half go above the node, so the edge to the
      // center never crosses the text.
      final above = at.dy < center.dy - 1;
      label.paint(
        canvas,
        at +
            Offset(
              -label.width / 2,
              above ? -_node - Space.s4 - label.height : _node + Space.s4,
            ),
      );
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(TinyMapPainter old) =>
      old.detail != detail || old.palette != palette;
}
