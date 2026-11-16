import 'package:flutter/material.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import 'answer_inspection.dart';

/// Width of the compact rail when the gutter is too small (cortex#78).
const compactRailWidth = 64.0;

/// Certainty rail at the left of the inspected text (cortex#78): one row per
/// visual line with the line number, one soft bar per token, the line value
/// and fork marks. Rows after the cursor line fade. A click goes to the least
/// certain token of the line.
class InspectionRail extends StatefulWidget {
  const InspectionRail({
    super.key,
    required this.controller,
    required this.layout,
    required this.width,
    required this.linkedLines,
  });
  final AnswerInspectionController controller;
  final InspectionLayout layout;
  final double width;
  final Set<int> linkedLines;
  bool get compact => width <= compactRailWidth;
  @override
  State<InspectionRail> createState() => _InspectionRailState();
}

class _InspectionRailState extends State<InspectionRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      _enter.value = 1;
    } else if (!_enter.isAnimating && _enter.value == 0) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final c = widget.controller;
    final lines = widget.layout.lines;
    final cursorLine = widget.layout.lineOf(c.cursor);
    final number = TextStyles.caption2.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (!widget.compact)
          Positioned(
            right: Space.s10,
            top: -Space.s20,
            child: Text(
              '${l.inspectionRailLine}   ${l.inspectionRailTokens}   ${l.inspectionRailCertainty}',
              style: number.copyWith(color: p.muted),
            ),
          ),
        for (var k = 0; k < lines.length; k++)
          Positioned(
            key: ValueKey('rail-row-$k'),
            left: 0,
            right: 0,
            top: lines[k].top + (lines[k].height - 24) / 2,
            height: 24,
            child: AnimatedBuilder(
              animation: _enter,
              builder: (context, child) {
                final start = (k * 0.04).clamp(0.0, 0.6);
                final t = ((_enter.value - start) / 0.4).clamp(0.0, 1.0);
                return Opacity(
                  opacity: t * (k <= cursorLine ? 1 : 0.35),
                  child: Transform.translate(
                    offset: Offset(-8 * (1 - t), 0),
                    child: child,
                  ),
                );
              },
              child: _row(context, l, p, b, k, k == cursorLine, number),
            ),
          ),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l,
    Palette p,
    Brightness b,
    int k,
    bool active,
    TextStyle number,
  ) {
    final c = widget.controller;
    final line = widget.layout.lines[k];
    final value = c.certaintyOf(line.spans);
    final words = [
      for (final i in line.spans)
        if (c.spans[i].hasWord && c.spans[i].certainty != null) i,
    ];
    final forks = line.spans.where((i) => c.spans[i].fork).length;
    int? weakest;
    for (final i in words) {
      if (weakest == null ||
          c.spans[i].certainty! < c.spans[weakest].certainty!) {
        weakest = i;
      }
    }
    final linked = widget.linkedLines.contains(k);
    final bar = widget.compact ? 2.0 : 3.0;
    final spark = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final i in words)
          Padding(
            padding: const EdgeInsets.only(left: 1),
            child: Container(
              width: bar,
              height: 3 + 13 * c.spans[i].certainty!,
              decoration: BoxDecoration(
                color: InspectionTones.soft(p, b, c.spans[i].certainty!),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
      ],
    );
    final valueText = value == null
        ? ''
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'^0'), '');
    final valueColor = value == null
        ? p.muted
        : active
        ? p.text
        : Color.lerp(InspectionTones.grade(p, b, value), p.text2, 0.4)!;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!widget.compact) ...[
          SizedBox(
            width: 18,
            child: Text(
              '${k + 1}',
              textAlign: TextAlign.right,
              style: number.copyWith(
                color: linked ? InspectionTones.range(p) : p.muted,
                fontWeight: linked ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: Space.s8),
        ],
        Flexible(
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerRight,
              maxWidth: double.infinity,
              child: spark,
            ),
          ),
        ),
        if (!widget.compact || active) ...[
          const SizedBox(width: Space.s6),
          SizedBox(
            width: 26,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: number.copyWith(
                color: valueColor,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
        if (!widget.compact) ...[
          const SizedBox(width: Space.s4),
          SizedBox(
            width: 12,
            child: Row(
              children: [
                for (var f = 0; f < forks.clamp(0, 2); f++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 1),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: InspectionTones.grid(b),
                        width: 1.25,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        Container(
          width: 2,
          height: 14,
          margin: const EdgeInsets.only(left: Space.s4, right: Space.s6),
          decoration: BoxDecoration(
            color: active ? InspectionTones.range(p) : null,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
    final target = weakest;
    final tip = target == null || value == null
        ? null
        : l.inspectionLineTip(
            k + 1,
            inspectionPercent(context, value),
            c.spans[target].text.trim(),
            inspectionPercent(context, c.spans[target].certainty!),
            forks,
          );
    final tappable = MouseRegion(
      cursor: target == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: target == null
            ? null
            : () {
                c.moveTo(target, pin: true);
                c.openRadar();
              },
        child: row,
      ),
    );
    return tip == null
        ? tappable
        : Tooltip(
            message: tip,
            waitDuration: MotionDurations.slower,
            child: tappable,
          );
  }
}
