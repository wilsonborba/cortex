import 'package:flutter/material.dart';
import '../../../../domain/models/answer_inspection.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../theme/tokens.dart';

TextSpan inspectionSpans(
  AnswerInspectionController c,
  TextStyle style,
  Palette p,
) {
  if (c.mode != InspectionMode.repeatedText || c.focusMatch == null) {
    return TextSpan(text: c.visibleText, style: style);
  }
  final ranges = [...c.earlierMatches, c.focusMatch!]
    ..sort((a, b) => a.start.compareTo(b.start));
  final spans = <TextSpan>[];
  var offset = 0;
  for (final range in ranges) {
    if (range.start < offset || range.end > c.cursor.codeUnit) continue;
    spans.add(TextSpan(text: c.text.substring(offset, range.start)));
    spans.add(
      TextSpan(
        text: c.text.substring(range.start, range.end),
        style: TextStyle(
          backgroundColor: p.selected,
          decoration: TextDecoration.underline,
          decorationColor: p.strokeAccessible,
        ),
      ),
    );
    offset = range.end;
  }
  spans.add(TextSpan(text: c.visibleText.substring(offset)));
  return TextSpan(style: style, children: spans);
}

class InspectionRailPainter extends CustomPainter {
  InspectionRailPainter({
    required AnswerInspectionController controller,
    required this.style,
    required this.palette,
    required this.direction,
    required this.scaler,
  }) : text = controller.visibleText,
       mode = controller.mode,
       tokens = controller.visibleRecordedTokens.toList(),
       matches = controller.earlierMatches,
       focus = controller.focusMatch,
       units = {
         for (final token in controller.visibleRecordedTokens)
           token.startByte: controller.codeUnitAtByte(token.startByte),
       };
  final String text;
  final InspectionMode mode;
  final List<InspectionToken> tokens;
  final List<InspectionTextMatch> matches;
  final InspectionTextMatch? focus;
  final Map<int, int> units;
  final TextStyle style;
  final Palette palette;
  final TextDirection direction;
  final TextScaler scaler;
  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
    )..layout(maxWidth: (size.width - Space.s48).clamp(1, double.infinity));
    final paint = Paint()
      ..color = palette.strokeAccessible
      ..strokeWidth = Strokes.thick
      ..strokeCap = StrokeCap.round;
    double y(int unit) =>
        painter.getOffsetForCaret(TextPosition(offset: unit), Rect.zero).dy +
        Space.s12 +
        painter.preferredLineHeight / 2;
    if (mode == InspectionMode.predictions) {
      final lines = <double, List<double>>{};
      for (final token in tokens) {
        (lines[y(units[token.startByte]!)] ??= []).add(token.likelihood);
      }
      for (final entry in lines.entries) {
        final mean = entry.value.reduce((a, b) => a + b) / entry.value.length;
        canvas.drawLine(
          Offset(Space.s4, entry.key),
          Offset(Space.s4 + Space.s16 * mean, entry.key),
          paint,
        );
      }
    } else if (focus != null) {
      final origin = y(focus!.start);
      for (final match in matches) {
        final target = y(match.start);
        final path = Path()
          ..moveTo(Space.s36, origin)
          ..quadraticBezierTo(
            Space.s12,
            (origin + target) / 2,
            Space.s36,
            target,
          );
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = Strokes.thin;
        canvas.drawPath(path, paint);
      }
    }
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant InspectionRailPainter old) =>
      text != old.text ||
      mode != old.mode ||
      matches != old.matches ||
      palette != old.palette ||
      style != old.style ||
      scaler != old.scaler ||
      tokens.length != old.tokens.length;
}
