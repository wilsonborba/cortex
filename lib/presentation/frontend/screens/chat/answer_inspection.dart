import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/answer_inspection.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';

class AnswerInspectionView extends StatefulWidget {
  const AnswerInspectionView({super.key, required this.controller});
  final AnswerInspectionController controller;
  @override
  State<AnswerInspectionView> createState() => _AnswerInspectionViewState();
}

class _AnswerInspectionViewState extends State<AnswerInspectionView> {
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

  String tokenText(InspectionAlternative value, AppLocalizations l) =>
      value.bytes.isEmpty
      ? l.inspectionControlToken
      : value.text == null
      ? l.inspectionPartial
      : jsonEncode(value.text);
  String likelihood(BuildContext context, double value) {
    final format = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;
    return value > 0 && value < 0.001
        ? '<${format.format(0.001)}'
        : format.format(value);
  }

  Widget metadata(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final next = c.nextToken;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.loading)
          Row(
            children: [
              const AppSpinner(),
              const SizedBox(width: Space.s8),
              Expanded(child: Text(l.inspectionLoading)),
            ],
          )
        else if (c.failed)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.inspectionReadFailed,
                style: TextStyles.body1.copyWith(color: p.dangerForeground),
              ),
              AppButton(label: l.retry, onPressed: c.load),
            ],
          )
        else if (!c.data.available)
          Text(switch (c.data.reason) {
            'not_supported' => l.inspectionUnsupported,
            'invalid_data' || 'incomplete' => l.inspectionUnverified,
            _ => l.inspectionNoData,
          }, style: TextStyles.body1.copyWith(color: p.muted))
        else ...[
          Text(
            l.inspectionRecorded,
            style: TextStyles.caption1.copyWith(color: p.muted),
          ),
          const SizedBox(height: Space.s8),
          if (next == null)
            Text(
              l.inspectionEnd,
              style: TextStyles.body1.copyWith(color: p.text2),
            )
          else ...[
            Text(
              l.inspectionNextToken,
              style: TextStyles.body1Strong.copyWith(color: p.text),
            ),
            SelectableText(
              '${tokenText(next, l)}  ${likelihood(context, next.likelihood)}',
              style: TextStyles.code.copyWith(color: p.text),
            ),
            if (next.alternatives.isNotEmpty) ...[
              const SizedBox(height: Space.s4),
              Text(
                l.inspectionAlternatives,
                style: TextStyles.caption1.copyWith(color: p.muted),
              ),
              Wrap(
                spacing: Space.s12,
                runSpacing: Space.s4,
                children: [
                  for (final alternative in next.alternatives)
                    Text(
                      '${tokenText(alternative, l)}  ${likelihood(context, alternative.likelihood)}',
                      style: TextStyles.code.copyWith(color: p.text2),
                    ),
                ],
              ),
            ],
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final height = MediaQuery.sizeOf(context).height * 0.6;
    return SizedBox(
      width: Space.dialogMaxWidth - Space.s48,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.inspectionDescription,
            style: TextStyles.body1.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s8),
          Text(
            l.inspectionVisible((c.fraction * 100).round()),
            style: TextStyles.body1Strong.copyWith(color: p.text),
          ),
          InspectionSlider(
            value: c.fraction,
            label: l.inspectionTitle,
            onChanged: c.reveal,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.45,
                    ),
                    child: SingleChildScrollView(child: metadata(context)),
                  ),
                  const SizedBox(height: Space.s8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: InspectionTextCanvas(
                        controller: c,
                        dragExtent: height,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s8),
          Text(
            l.inspectionPlainText,
            style: TextStyles.caption1.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}

/// The neutral Fluent track and thumb reuse the current spacing and stroke tokens.
class InspectionSlider extends StatefulWidget {
  const InspectionSlider({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.divisions,
  });
  final double value;
  final String label;
  final ValueChanged<double> onChanged;
  final int? divisions;
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
            semanticFormatterCallback: (v) => '${(v * 100).round()}%',
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

class InspectionTextCanvas extends StatefulWidget {
  const InspectionTextCanvas({
    super.key,
    required this.controller,
    required this.dragExtent,
  });
  final AnswerInspectionController controller;
  final double dragExtent;
  @override
  State<InspectionTextCanvas> createState() => _InspectionTextCanvasState();
}

class _InspectionTextCanvasState extends State<InspectionTextCanvas> {
  final handle = GlobalKey();
  int? previous;
  AnswerInspectionController get controller => widget.controller;
  double get dragExtent => widget.dragExtent;
  @override
  Widget build(BuildContext context) {
    final before = previous;
    previous = controller.cursor.codeUnit;
    if (before != null && before != previous) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = handle.currentContext;
        if (mounted && target != null) {
          unawaited(
            Scrollable.ensureVisible(
              target,
              duration: Duration.zero,
              alignmentPolicy: controller.cursor.codeUnit < before
                  ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
                  : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
            ),
          );
        }
      });
    }
    final p = Palette.from(context);
    final l = AppLocalizations.of(context);
    final style = TextStyles.body2.copyWith(color: p.text);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(1.0, constraints.maxWidth - Space.s48);
        final full = TextPainter(
          text: TextSpan(text: controller.text, style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: width);
        final prefix = TextPainter(
          text: TextSpan(text: controller.visibleText, style: style),
          textDirection: direction,
          textScaler: scaler,
        )..layout(maxWidth: width);
        final caret = prefix.getOffsetForCaret(
          TextPosition(offset: controller.cursor.codeUnit),
          Rect.zero,
        );
        final height = math.max(Space.s48, full.height + Space.s24);
        final caretY = caret.dy;
        full.dispose();
        prefix.dispose();
        return SizedBox(
          key: const Key('inspection-text-area'),
          height: height,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: Space.s48,
                right: 0,
                child: SelectableText(
                  controller.visibleText,
                  key: const Key('inspection-visible-text'),
                  style: style,
                  textDirection: direction,
                ),
              ),
              Positioned(
                left: 0,
                top: caretY,
                width: Space.s48,
                height: Space.s48,
                child: Semantics(
                  label: l.inspectionDragHint,
                  value: l.inspectionVisible(
                    (controller.fraction * 100).round(),
                  ),
                  increasedValue: l.inspectionVisible(
                    (controller.fractionAfterStep(1) * 100).round(),
                  ),
                  decreasedValue: l.inspectionVisible(
                    (controller.fractionAfterStep(-1) * 100).round(),
                  ),
                  onIncrease: () => controller.step(1),
                  onDecrease: () => controller.step(-1),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      key: const Key('inspection-handle'),
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (d) => controller.reveal(
                        controller.fraction + d.delta.dy / dragExtent,
                      ),
                      child: Center(
                        key: handle,
                        child: Container(
                          width: Space.s16,
                          height: Space.s16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.background,
                            border: Border.all(
                              color: p.text2,
                              width: Strokes.thick,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
