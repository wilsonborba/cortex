import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/answer_inspection.dart';
import '../../../../domain/services/answer_inspection_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/reticle.dart';

/// Percent text in the active locale, one decimal at most.
String inspectionPercent(BuildContext context, double value) =>
    '${NumberFormat('##0.#', Localizations.localeOf(context).toString()).format(value * 100)}%';

/// Measured geometry of the inspected text, in [InspectionAnswer] space.
class InspectionLayout {
  const InspectionLayout(this.spans, this.lines);

  /// Last box of each span (a span can wrap).
  final List<Rect> spans;

  /// Visual lines: top, height and span indexes.
  final List<InspectionLine> lines;
  int lineOf(int span) {
    for (var i = lines.length - 1; i >= 0; i--) {
      if (lines[i].spans.first <= span) return i;
    }
    return 0;
  }
}

class InspectionLine {
  InspectionLine(this.top, this.height);
  final double top, height;
  final spans = <int>[];
}

/// Answer inspection in place (cortex#77). The saved answer text becomes the
/// surface: the cursor follows the pointer, text after it turns to ghost
/// text, and a click pins the cursor. Nothing here calls a model or changes
/// the saved text.
class InspectionAnswer extends StatefulWidget {
  const InspectionAnswer({
    super.key,
    required this.controller,
    required this.onExit,
    this.gutter = 0,
  });
  final AnswerInspectionController controller;
  final VoidCallback onExit;

  /// Free space at the left of the text column (the rail space at wide
  /// widths). Zero means compact layout.
  final double gutter;
  @override
  State<InspectionAnswer> createState() => InspectionAnswerState();
}

class InspectionAnswerState extends State<InspectionAnswer>
    with SingleTickerProviderStateMixin {
  final _text = GlobalKey();
  final _focus = FocusNode(debugLabel: 'answer inspection');
  InspectionLayout? layout;
  Timer? _dwell;
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: MotionDurations.faster,
  );
  int _lastCursor = -1;
  AnswerInspectionController get c => widget.controller;

  /// Left edge of the text inside this widget.
  double get textLeft => widget.gutter;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    _lastCursor = c.cursor;
  }

  @override
  void didUpdateWidget(InspectionAnswer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != c) {
      oldWidget.controller.removeListener(_changed);
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _dwell?.cancel();
    _tick.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    if (c.cursor != _lastCursor) {
      _lastCursor = c.cursor;
      final span = c.current;
      if (span != null && span.fork && !_reduced) {
        _tick.forward(from: 0);
        HapticFeedback.selectionClick();
      }
    }
    setState(() {});
  }

  bool get _reduced => MediaQuery.maybeDisableAnimationsOf(context) == true;

  RenderParagraph? get _paragraph =>
      _text.currentContext?.findRenderObject() as RenderParagraph?;

  /// Measure span boxes after layout. Lines group spans by box top.
  void _measure() {
    final paragraph = _paragraph;
    if (paragraph == null || !paragraph.hasSize || c.spans.isEmpty) return;
    final rects = <Rect>[];
    final lines = <InspectionLine>[];
    final lineHeight = paragraph.text.style?.fontSize ?? 16;
    for (var i = 0; i < c.spans.length; i++) {
      final s = c.spans[i];
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: s.start, extentOffset: s.end),
      );
      Rect rect;
      if (boxes.isEmpty) {
        final caret = paragraph.getOffsetForCaret(
          TextPosition(offset: s.end),
          Rect.zero,
        );
        rect = Rect.fromLTWH(caret.dx, caret.dy, 0, lineHeight * 1.4);
      } else {
        rect = boxes.last.toRect();
      }
      rect = rect.shift(Offset(textLeft, 0));
      rects.add(rect);
      final visible = s.text.trim().isNotEmpty;
      if (lines.isEmpty || (visible && (rect.top - lines.last.top).abs() > 4)) {
        if (lines.isEmpty || visible) {
          lines.add(InspectionLine(rect.top, rect.height));
        }
      }
      lines.last.spans.add(i);
    }
    final next = InspectionLayout(rects, lines);
    final old = layout;
    if (old == null ||
        old.spans.length != rects.length ||
        old.spans.last != rects.last ||
        old.lines.length != lines.length) {
      setState(() => layout = next);
    } else {
      layout = next;
    }
  }

  int? _spanAt(Offset local) {
    final paragraph = _paragraph;
    if (paragraph == null || c.spans.isEmpty) return null;
    final position = paragraph.getPositionForOffset(local);
    var offset = position.offset;
    if (position.affinity == TextAffinity.upstream && offset > 0) offset--;
    return c.spanAt(offset.clamp(0, c.text.length));
  }

  void _follow(Offset local) {
    if (c.pinned) return;
    final span = _spanAt(local);
    if (span == null) return;
    if (span != c.cursor) c.closeRadar();
    c.moveTo(span);
    _dwell?.cancel();
    _dwell = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !c.pinned) c.openRadar();
    });
  }

  void _tap(TapUpDetails details) {
    if (details.kind != PointerDeviceKind.mouse) return;
    final span = _spanAt(details.localPosition);
    if (span == null) return;
    _dwell?.cancel();
    if (c.pinned) {
      c.closeRadar(unpin: true);
      c.moveTo(span, pin: false);
    } else {
      c.moveTo(span, pin: true);
      c.openRadar();
    }
  }

  void _drag(Offset local) {
    _dwell?.cancel();
    final span = _spanAt(local);
    if (span == null) return;
    c.closeRadar();
    c.moveTo(span, pin: false);
  }

  void _dragEnd() {
    c.moveTo(c.cursor, pin: true);
    c.openRadar();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      c.step(-1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      c.step(1);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (c.radarOpen) {
        c.closeRadar();
      } else {
        c.moveTo(c.cursor, pin: true);
        c.openRadar();
      }
    } else if (key == LogicalKeyboardKey.escape) {
      if (c.radarOpen || c.pinned) {
        c.closeRadar(unpin: true);
      } else {
        widget.onExit();
      }
    } else if (c.radarOpen &&
        (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown)) {
      final options = c.current!.options;
      final now = c.pick ?? options.indexWhere((o) => o.chosen);
      final delta = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      c.select((now + delta) % options.length);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Extra space below the text for overlays (the radar of cortex#78).
  double bottomSpace(InspectionLayout layout) => 0;

  /// Overlays above the text (rail and radar of cortex#78).
  List<Widget> overlays(InspectionLayout layout, Offset cursor) => const [];

  /// Paint below the cursor (links of cortex#78).
  void paintLinks(Canvas canvas, InspectionLayout layout, Offset cursor) {}

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final base = TextStyles.body2.copyWith(color: p.text);
    final spans = <InlineSpan>[
      for (var i = 0; i < c.spans.length; i++)
        TextSpan(text: c.spans[i].text, style: spanStyle(i, p, b)),
    ];
    final measured = layout;
    final cursorRect = measured != null && c.cursor < measured.spans.length
        ? measured.spans[c.cursor]
        : null;
    final cursor = cursorRect == null
        ? null
        : Offset(cursorRect.right + Space.s12, cursorRect.center.dy);
    final touch =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(left: textLeft),
            child: InspectionSummaryBar(controller: c, onExit: widget.onExit),
          ),
          const SizedBox(height: Space.s12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: textLeft,
                  bottom: measured == null ? 0 : bottomSpace(measured),
                ),
                child: Semantics(
                  slider: true,
                  label: l.inspectionCursorLabel,
                  value: _semanticValue(l, c.cursor),
                  increasedValue: _semanticValue(l, c.cursor + 1),
                  decreasedValue: _semanticValue(l, c.cursor - 1),
                  onIncrease: () => c.step(1),
                  onDecrease: () => c.step(-1),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onHover: (e) => _follow(e.localPosition),
                    child: GestureDetector(
                      key: const Key('inspection-text'),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _tap,
                      onVerticalDragUpdate: (d) => _drag(d.localPosition),
                      onHorizontalDragUpdate: (d) => _drag(d.localPosition),
                      onVerticalDragEnd: (_) => _dragEnd(),
                      onHorizontalDragEnd: (_) => _dragEnd(),
                      child: RichText(
                        key: _text,
                        textScaler: MediaQuery.textScalerOf(context),
                        text: TextSpan(style: base, children: spans),
                      ),
                    ),
                  ),
                ),
              ),
              if (measured != null && cursor != null) ...[
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CursorPainter(
                        state: this,
                        layout: measured,
                        cursor: cursor,
                        color: p.text,
                        dot: c.pinned ? InspectionTones.range(p) : p.text,
                        fill: p.background,
                        tick: _tick,
                      ),
                    ),
                  ),
                ),
                if (!c.moved)
                  Positioned(
                    left: cursor.dx + Space.s16,
                    top: cursor.dy - 9,
                    child: IgnorePointer(
                      child: Container(
                        color: p.background,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s4,
                        ),
                        child: Text(
                          touch ? l.inspectionHintTouch : l.inspectionHint,
                          key: const Key('inspection-hint'),
                          style: TextStyles.caption1.copyWith(color: p.muted),
                        ),
                      ),
                    ),
                  ),
                ...overlays(measured, cursor),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Screen reader value of span [index]: its word and certainty.
  String _semanticValue(AppLocalizations l, int index) {
    if (c.spans.isEmpty) return '';
    final span = c.spans[index.clamp(0, c.spans.length - 1)];
    final word = span.text.trim().isEmpty ? '⏎' : span.text.trim();
    return span.certainty == null
        ? word
        : l.inspectionCursorValue(
            word,
            inspectionPercent(context, span.certainty!),
          );
  }

  /// Style of one span: ghost after the cursor, underline at the cursor.
  TextStyle? spanStyle(int i, Palette p, Brightness b) {
    if (i > c.cursor) return TextStyle(color: InspectionTones.ghost(p));
    if (i == c.cursor) {
      final certainty = c.spans[i].certainty;
      return TextStyle(
        decoration: TextDecoration.underline,
        decorationThickness: 2,
        decorationColor: certainty == null
            ? p.text
            : InspectionTones.grade(p, b, certainty),
      );
    }
    return null;
  }
}

class _CursorPainter extends CustomPainter {
  _CursorPainter({
    required this.state,
    required this.layout,
    required this.cursor,
    required this.color,
    required this.dot,
    required this.fill,
    required this.tick,
  }) : super(repaint: tick);
  final InspectionAnswerState state;
  final InspectionLayout layout;
  final Offset cursor;
  final Color color, dot, fill;
  final Animation<double> tick;
  @override
  void paint(Canvas canvas, Size size) {
    state.paintLinks(canvas, layout, cursor);
    final grow = tick.isAnimating
        ? 1 + 0.4 * (1 - (tick.value - 0.5).abs() * 2)
        : 1;
    ReticlePainter.paintAt(
      canvas,
      cursor,
      11.5 * grow,
      color: color,
      dot: dot,
      fill: fill,
    );
  }

  @override
  bool shouldRepaint(_CursorPainter old) => true;
}

/// Summary cards above the text: average, lowest, forks, tokens, info and
/// close. Loading, error and missing-data states use the same row.
class InspectionSummaryBar extends StatelessWidget {
  const InspectionSummaryBar({
    super.key,
    required this.controller,
    required this.onExit,
  });
  final AnswerInspectionController controller;
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final c = controller;
    final s = c.summary;
    Widget note(String text, {Widget? action}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s6),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.s8,
        children: [
          Text(text, style: TextStyles.caption1.copyWith(color: p.muted)),
          if (action != null) action,
        ],
      ),
    );
    final Widget content;
    if (c.loading) {
      content = note(l.inspectionLoading);
    } else if (c.failed) {
      content = note(
        l.inspectionReadFailed,
        action: TextButton(onPressed: c.load, child: Text(l.retry)),
      );
    } else if (!c.available) {
      content = note(switch (c.data.reason) {
        'not_supported' => l.inspectionUnsupported,
        'invalid_data' || 'incomplete' => l.inspectionUnverified,
        _ => l.inspectionNoData,
      });
    } else {
      final average = s.average!;
      final lowest = s.lowest == null ? null : c.spans[s.lowest!];
      content = Wrap(
        spacing: Space.s6,
        runSpacing: Space.s6,
        children: [
          _Stat(
            key: const Key('inspection-average'),
            label: l.inspectionAverage,
            value: Text(
              inspectionPercent(context, average),
              style: _value.copyWith(
                color: InspectionTones.grade(p, b, average),
              ),
            ),
            meter: average,
            meterColor: InspectionTones.grade(p, b, average),
          ),
          if (lowest != null)
            _Stat(
              key: const Key('inspection-lowest'),
              label: l.inspectionLowest,
              onTap: c.showLowest,
              value: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '“${lowest.text.trim()}” '),
                    TextSpan(
                      text: inspectionPercent(context, lowest.certainty!),
                      style: TextStyle(
                        color: InspectionTones.grade(p, b, lowest.certainty!),
                      ),
                    ),
                  ],
                ),
                style: _value.copyWith(color: p.text),
              ),
            ),
          _Stat(
            key: const Key('inspection-forks'),
            label: l.inspectionForks,
            onTap: s.forks.isEmpty ? null : c.nextFork,
            value: Text(
              '${s.forks.length}',
              style: _value.copyWith(color: InspectionTones.grid(b)),
            ),
          ),
          _Stat(
            label: l.inspectionTokens,
            value: Text('${s.tokens}', style: _value.copyWith(color: p.text)),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: content),
        Tooltip(
          message: l.inspectionInfo,
          child: Padding(
            padding: const EdgeInsets.all(Space.s6),
            child: Icon(AppIcons.info, size: IconSizes.small, color: p.muted),
          ),
        ),
        IconButton(
          key: const Key('inspection-exit'),
          tooltip: l.inspectionExit,
          icon: const Icon(AppIcons.close, size: IconSizes.small),
          onPressed: onExit,
        ),
      ],
    );
  }

  static final _value = TextStyles.body1Strong.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    super.key,
    required this.label,
    required this.value,
    this.meter,
    this.meterColor,
    this.onTap,
  });
  final String label;
  final Widget value;
  final double? meter;
  final Color? meterColor;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s10,
        vertical: Space.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyles.caption1.copyWith(color: p.muted)),
          const SizedBox(height: Space.s2),
          value,
          if (meter != null) ...[
            const SizedBox(height: Space.s4),
            SizedBox(
              width: 80,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.small),
                child: LinearProgressIndicator(
                  value: meter,
                  color: meterColor,
                  backgroundColor: p.divider,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Material(
      color: p.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: p.divider),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Short text of an option for chips and readouts: spaces and line breaks
/// stay visible as quotes would hide them.
String optionLabel(InspectionOption option) {
  final trimmed = option.text.trim();
  return trimmed.isEmpty ? '⏎' : trimmed;
}
