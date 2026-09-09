import 'package:flutter/material.dart';

/// Monochromatic Architectural Grid Background matching the Asodya / Neural Grid visual system.
class MyBackground extends StatelessWidget {
  const MyBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gridLineColor = isDark
        ? Colors.white.withValues(alpha: 0.035)
        : Colors.black.withValues(alpha: 0.05);

    return IgnorePointer(
      child: CustomPaint(
        painter: _NeuralGridPainter(gridLineColor: gridLineColor),
        size: Size.infinite,
      ),
    );
  }
}

class _NeuralGridPainter extends CustomPainter {
  _NeuralGridPainter({required this.gridLineColor});

  final Color gridLineColor;
  static const double gridSize = 40.0;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralGridPainter oldDelegate) =>
      oldDelegate.gridLineColor != gridLineColor;
}
