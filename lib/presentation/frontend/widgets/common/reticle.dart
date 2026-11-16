import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Reticle glyph of answer inspection (owner prototype): a ring, four short
/// ticks and a center dot. The action icon and the text cursor share it.
class Reticle extends StatelessWidget {
  const Reticle({
    super.key,
    required this.color,
    this.size = 16,
    this.dot,
    this.fill,
  });
  final Color color;
  final double size;

  /// Center dot color; defaults to [color].
  final Color? dot;

  /// Ring fill, so the cursor stays readable over text.
  final Color? fill;
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: ReticlePainter(color: color, dot: dot ?? color, fill: fill),
  );
}

class ReticlePainter extends CustomPainter {
  const ReticlePainter({required this.color, required this.dot, this.fill});
  final Color color, dot;
  final Color? fill;

  /// Paint at [center] with outer radius [radius] (tick ends).
  static void paintAt(
    Canvas canvas,
    Offset center,
    double radius, {
    required Color color,
    required Color dot,
    Color? fill,
    double stroke = 1.5,
  }) {
    final ring = radius * 0.62;
    if (fill != null) canvas.drawCircle(center, ring, Paint()..color = fill);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, ring, line);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + d * (ring + 1.5), center + d * radius, line);
    }
    canvas.drawCircle(center, radius * 0.2, Paint()..color = dot);
  }

  @override
  void paint(Canvas canvas, Size size) => paintAt(
    canvas,
    size.center(Offset.zero),
    size.shortestSide / 2,
    color: color,
    dot: dot,
    fill: fill,
    stroke: size.shortestSide < 20 ? 1.25 : 1.5,
  );

  @override
  bool shouldRepaint(ReticlePainter old) =>
      old.color != color || old.dot != dot || old.fill != fill;
}
