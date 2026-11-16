import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/models/answer_inspection.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';

/// The neutral Fluent track and thumb reuse the current spacing and stroke tokens.
class InspectionSlider extends StatefulWidget {
  const InspectionSlider({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.divisions,
    this.semanticFormatter,
  });
  final double value;
  final String label;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final String Function(double)? semanticFormatter;
  @override
  State<InspectionSlider> createState() => _InspectionSliderState();
}

class _InspectionSliderState extends State<InspectionSlider> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return FoundationFocus(
      child: Semantics(
        label: widget.label,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: Strokes.thickest,
            activeTrackColor: p.text2,
            inactiveTrackColor: p.stroke,
            thumbColor: p.text,
            overlayColor: p.subtleHover,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: Space.s8,
            ),
          ),
          child: Slider(
            value: widget.value,
            focusNode: focus,
            divisions: widget.divisions,
            semanticFormatterCallback:
                widget.semanticFormatter ?? (v) => '${(v * 100).round()}%',
            onChanged: (value) {
              focus.requestFocus();
              widget.onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}

class InspectionControls extends StatefulWidget {
  const InspectionControls({super.key, required this.controller});
  final AnswerInspectionController controller;
  @override
  State<InspectionControls> createState() => _InspectionControlsState();
}

class _InspectionControlsState extends State<InspectionControls> {
  AnswerInspectionController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return SingleChildScrollView(
      child: SizedBox(
        width: Space.menuMaxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.inspectionDialHint,
              style: TextStyles.body1.copyWith(color: p.text2),
            ),
            const SizedBox(height: Space.s12),
            ExcludeSemantics(child: InspectionDial(controller: c)),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Space.s12,
              runSpacing: Space.s4,
              children: [
                Text(
                  l.inspectionPredictions,
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
                Text(
                  l.inspectionRepeatedText,
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
              ],
            ),
            const SizedBox(height: Space.s16),
            Text(
              l.inspectionMode,
              style: TextStyles.body1Strong.copyWith(color: p.text),
            ),
            const SizedBox(height: Space.s4),
            AppSelect<InspectionMode>(
              key: const Key('inspection-mode'),
              value: c.mode,
              isExpanded: true,
              items: [
                DropdownMenuItem(
                  value: InspectionMode.predictions,
                  child: Text(l.inspectionPredictions),
                ),
                DropdownMenuItem(
                  value: InspectionMode.repeatedText,
                  child: Text(l.inspectionRepeatedText),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) c.selectMode(mode);
              },
            ),
            const SizedBox(height: Space.s12),
            Text(
              l.inspectionDetail(c.detail),
              style: TextStyles.body1Strong.copyWith(color: p.text),
            ),
            InspectionSlider(
              key: const Key('inspection-detail'),
              value: (c.detail - 1) / 4,
              divisions: 4,
              label: l.inspectionDetail(c.detail),
              semanticFormatter: (v) => l.inspectionDetail(1 + (v * 4).round()),
              onChanged: (v) => c.selectDetail(1 + (v * 4).round()),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectionDial extends StatelessWidget {
  const InspectionDial({super.key, required this.controller});
  final AnswerInspectionController controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final center = Offset(width / 2, width / 2 + Space.s8);
      final radius = width / 2 - Space.s16;
      void update(Offset point) {
        final vector = point - center;
        controller.setDial(
          math.atan2(-vector.dy, vector.dx),
          vector.distance / radius,
        );
      }

      return MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          key: const Key('inspection-dial'),
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: CustomPaint(
            size: Size(width, width / 2 + Space.s24),
            painter: _DialPainter(
              controller.dialAngle,
              controller.dialDistance,
              Palette.from(context),
            ),
          ),
        ),
      );
    },
  );
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.angle, this.distance, this.palette);
  final double angle, distance;
  final Palette palette;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.width / 2 + Space.s8),
        radius = size.width / 2 - Space.s16;
    final grid = Paint()
      ..color = palette.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = Strokes.thin;
    for (var i = 1; i <= 5; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * i / 5),
        -math.pi,
        math.pi,
        false,
        grid,
      );
    }
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      grid,
    );
    canvas.drawLine(center, center - Offset(0, radius), grid);
    final end =
        center + Offset(math.cos(angle), -math.sin(angle)) * radius * distance;
    final line = Paint()
      ..color = palette.text2
      ..strokeWidth = Strokes.thick
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, end, line);
    canvas.drawCircle(end, Space.s6, line);
    canvas.drawCircle(center, Space.s2, line);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      angle != old.angle || distance != old.distance || palette != old.palette;
}
