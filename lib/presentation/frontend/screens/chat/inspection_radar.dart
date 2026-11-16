import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../domain/models/answer_inspection.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import 'answer_inspection.dart';

/// Geometry of the alternatives radar in [InspectionAnswer] space.
class RadarGeometry {
  const RadarGeometry({
    required this.center,
    required this.radius,
    required this.cursor,
    required this.bounds,
  });
  final Offset center;
  final double radius;

  /// Text cursor: the stem starts here.
  final Offset cursor;

  /// Area of the radar widget: stem, circle, chips and readout.
  final Rect bounds;

  /// Below the cursor line. Wide layouts follow the cursor; narrow layouts
  /// center the radar in the answer width.
  static RadarGeometry place({
    required Rect cursorRect,
    required Offset cursor,
    required double width,
    required double textLeft,
    required bool compact,
  }) {
    final r = compact ? 58.0 : 100.0;
    final side = compact ? 96.0 : 116.0;
    final cx = compact
        ? width / 2
        : cursor.dx
              .clamp(
                textLeft + r + side,
                math.max(textLeft + r + side, width - r - side),
              )
              .toDouble();
    final cy = cursorRect.bottom + 26 + r;
    final top = cursorRect.bottom + 2;
    final left = compact ? 0.0 : cx - r - side;
    final right = compact ? width : cx + r + side;
    return RadarGeometry(
      center: Offset(cx, cy),
      radius: r,
      cursor: cursor,
      bounds: Rect.fromLTRB(left, top, right, cy + r + 166),
    );
  }

  /// Angle of option [k] of [n]. The top stays free for the stem.
  static double angle(int k, int n) =>
      -math.pi / 2 + math.pi / n + k * 2 * math.pi / n;
}

/// Alternatives radar (cortex#78, owner prototype). One spoke per recorded
/// option; the polygon vertex sits at radius = likelihood. Hover or tap
/// selects an option; nothing here changes the saved text or calls a model.
class InspectionRadar extends StatelessWidget {
  const InspectionRadar({
    super.key,
    required this.controller,
    required this.geometry,
    this.onContinue,
  });
  final AnswerInspectionController controller;
  final RadarGeometry geometry;

  /// Continue the answer with the selected option (cortex#82). The button
  /// shows only when this is set.
  final ValueChanged<InspectionOption>? onContinue;

  void _selectAt(Offset local) {
    final g = geometry;
    final v = local + g.bounds.topLeft - g.center;
    if (v.distance < 12 || v.distance > g.radius + 40) return;
    final options = controller.current!.options;
    final a = math.atan2(v.dy, v.dx);
    var best = 0;
    var gap = double.infinity;
    for (var k = 0; k < options.length; k++) {
      final d = RadarGeometry.angle(k, options.length) - a;
      final wrapped = math.atan2(math.sin(d), math.cos(d)).abs();
      if (wrapped < gap) {
        gap = wrapped;
        best = k;
      }
    }
    controller.select(best);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final c = controller;
    final span = c.current!;
    final options = span.options;
    final g = geometry;
    final origin = g.bounds.topLeft;
    final center = g.center - origin;
    final r = g.radius;
    final chosen = options.indexWhere((o) => o.chosen);
    final pick = c.pick ?? chosen;
    final selected = options[pick];
    final range = InspectionTones.range(p);
    return MouseRegion(
      opaque: true,
      onHover: (e) => _selectAt(e.localPosition),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (d) => _selectAt(d.localPosition),
        onPanUpdate: (d) => _selectAt(d.localPosition),
        child: Semantics(
          container: true,
          label: l.inspectionRadarLabel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RadarPainter(
                    center: center,
                    radius: r,
                    cursor: g.cursor - origin,
                    options: options,
                    pick: pick,
                    range: range,
                    grid: InspectionTones.grid(b),
                    backdrop: p.background,
                  ),
                ),
              ),
              for (final f in const [0.25, 0.5, 0.75])
                Positioned(
                  left: center.dx + 4,
                  top: center.dy - r * f - 7,
                  child: Text(
                    '${(f * 100).round()}',
                    style: TextStyles.caption2.copyWith(
                      color: InspectionTones.grid(b),
                    ),
                  ),
                ),
              for (var k = 0; k < options.length; k++)
                _chip(context, l, p, k, options, k == pick, center, r),
              Positioned(
                left: 0,
                right: 0,
                top: center.dy + r + 46,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _readout(context, l, p, b, span, selected, options),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    AppLocalizations l,
    Palette p,
    int k,
    List<InspectionOption> options,
    bool picked,
    Offset center,
    double r,
  ) {
    final option = options[k];
    final a = RadarGeometry.angle(k, options.length);
    final cs = math.cos(a), sn = math.sin(a);
    final at = center + Offset(cs, sn) * (r + 12);
    final range = InspectionTones.range(p);
    final compact = geometry.radius < 80;
    final border = picked
        ? range
        : option.chosen
        ? p.text2
        : p.divider;
    final chip = Container(
      key: ValueKey('radar-option-$k'),
      decoration: BoxDecoration(
        color: picked ? Color.lerp(p.surface, range, 0.16) : p.surface,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s8,
                vertical: 3,
              ),
              child: Text(
                optionLabel(option),
                style: TextStyles.caption1.copyWith(color: p.text),
              ),
            ),
            if (option.chosen && !compact)
              Padding(
                padding: const EdgeInsets.only(right: Space.s6),
                child: Center(
                  child: Text(
                    l.inspectionChosenTag,
                    style: TextStyles.caption2.copyWith(color: p.muted),
                  ),
                ),
              ),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: Space.s6),
              decoration: BoxDecoration(
                color: picked ? range : p.tagBackground,
                border: Border(left: BorderSide(color: border)),
              ),
              child: Text(
                inspectionPercent(context, option.likelihood),
                style: TextStyles.caption1Strong.copyWith(
                  color: picked ? InspectionTones.onRange(p) : p.muted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: Offset(
          cs > 0.25
              ? 0
              : cs < -0.25
              ? -1
              : -0.5,
          sn > 0.5
              ? 0
              : sn < -0.5
              ? -1
              : -0.5,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => controller.select(k),
          child: Semantics(
            button: true,
            selected: picked,
            label:
                '${optionLabel(option)}, ${inspectionPercent(context, option.likelihood)}',
            child: GestureDetector(
              onTap: () => controller.select(k),
              child: chip,
            ),
          ),
        ),
      ),
    );
  }

  Widget _readout(
    BuildContext context,
    AppLocalizations l,
    Palette p,
    Brightness b,
    InspectionSpan span,
    InspectionOption selected,
    List<InspectionOption> options,
  ) {
    final chosen = options.firstWhere((o) => o.chosen);
    final style = TextStyles.body1.copyWith(color: p.muted);
    final text = selected.chosen
        ? '${l.inspectionChose(optionLabel(chosen), inspectionPercent(context, chosen.likelihood))} '
              '${l.inspectionRest(inspectionPercent(context, span.otherLikelihood))}'
        : l.inspectionInstead(
            optionLabel(chosen),
            inspectionPercent(context, chosen.likelihood),
            optionLabel(selected),
            inspectionPercent(context, selected.likelihood),
          );
    final grid = InspectionTones.grid(b);
    final canContinue =
        onContinue != null && !selected.chosen && selected.rank != null;
    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            key: const Key('radar-readout'),
            textAlign: TextAlign.center,
            style: style,
          ),
          if (span.fork)
            Container(
              margin: const EdgeInsets.only(top: Space.s6),
              padding: const EdgeInsets.symmetric(horizontal: Space.s8),
              decoration: BoxDecoration(
                border: Border.all(color: grid.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(Radii.circular),
              ),
              child: Text(
                l.inspectionFork,
                style: TextStyles.caption1.copyWith(color: grid),
              ),
            ),
          if (canContinue)
            Padding(
              padding: const EdgeInsets.only(top: Space.s10),
              child: OutlinedButton.icon(
                key: const Key('radar-continue'),
                icon: const Icon(AppIcons.branchFork, size: IconSizes.small),
                label: Text(l.inspectionContinue(optionLabel(selected))),
                onPressed: () => onContinue!(selected),
              ),
            ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.center,
    required this.radius,
    required this.cursor,
    required this.options,
    required this.pick,
    required this.range,
    required this.grid,
    required this.backdrop,
  });
  final Offset center, cursor;
  final double radius;
  final List<InspectionOption> options;
  final int pick;
  final Color range, grid, backdrop;
  @override
  void paint(Canvas canvas, Size size) {
    final r = radius;
    canvas.drawCircle(
      center,
      r + 30,
      Paint()..color = backdrop.withValues(alpha: 0.94),
    );
    final stem = Path()
      ..moveTo(cursor.dx, cursor.dy + 9)
      ..cubicTo(
        cursor.dx,
        center.dy - r - 14,
        center.dx,
        cursor.dy + 20,
        center.dx,
        center.dy - r,
      );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grid.withValues(alpha: 0.6);
    canvas.drawPath(stem, line);
    canvas.drawCircle(center, r, Paint()..color = grid.withValues(alpha: 0.06));
    for (final f in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(
        center,
        r * f,
        line..color = grid.withValues(alpha: f == 1 ? 0.55 : 0.28),
      );
    }
    final n = options.length;
    final points = <Offset>[];
    for (var k = 0; k < n; k++) {
      final a = RadarGeometry.angle(k, n);
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center,
        center + d * r,
        line..color = grid.withValues(alpha: 0.28),
      );
      points.add(center + d * r * math.max(options[k].likelihood, 0.03));
    }
    final polygon = Path()..addPolygon(points, true);
    canvas.drawPath(polygon, Paint()..color = range.withValues(alpha: 0.2));
    canvas.drawPath(
      polygon,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = range,
    );
    canvas.drawLine(
      center,
      points[pick],
      Paint()
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = range,
    );
    for (var k = 0; k < n; k++) {
      final selected = k == pick;
      canvas.drawCircle(
        points[k],
        selected ? 5.5 : 3,
        Paint()..color = selected ? range : backdrop,
      );
      canvas.drawCircle(
        points[k],
        selected ? 5.5 : 3,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = range,
      );
    }
    canvas.drawCircle(center, 2.5, Paint()..color = grid);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.pick != pick ||
      old.options != options ||
      old.center != center ||
      old.cursor != cursor ||
      old.range != range;
}
