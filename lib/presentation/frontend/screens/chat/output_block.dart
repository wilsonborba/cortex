import '../../theme/app_icons.dart';
import 'dart:async';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/models/output.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../theme/theme.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import 'step_text.dart';
import '../../widgets/common/toast.dart';

/// The security block number (area 9.5): shown with a shield icon, no emoji (C1).
const securityBlock = 1014;

/// One output (30.5): status line, stages, thinking, answer, sources, memories,
/// notices, error and the stats line.
class OutputBlock extends StatefulWidget {
  const OutputBlock({
    super.key,
    required this.output,
    this.onStopThinking,
    this.onRetry,
    this.onMemories,
    this.now,
  });
  final OutputView output;
  final DateTime Function()? now;
  final VoidCallback? onStopThinking;
  final VoidCallback? onRetry;
  final ValueChanged<List<(String, String)>>? onMemories;
  @override
  State<OutputBlock> createState() => _OutputBlockState();
}

class _OutputBlockState extends State<OutputBlock> {
  DateTime _now() => widget.now?.call() ?? DateTime.now();
  bool _stages = false;
  bool _thinking = false;
  Timer? _clock;
  String? _lastStatus;
  String _announcement = '';
  DateTime? _thinkingStarted;
  int _thoughtSeconds = 0;
  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  /// Title shortened to 30 characters for a source tag (#63).
  static String _short(String title) =>
      title.characters.length <= 30 ? title : '${title.characters.take(29)}…';

  /// The one wait indicator of a running answer (#63, Fluent wait rules):
  /// nothing under 1 s; a pulsing dot while thinking; a 2 px progress bar
  /// with the label above and the status below when the total is known;
  /// else a 16 px spinner with the "-ing" label.
  Widget _waitStatus(
    AppLocalizations l,
    Palette p,
    OutputView o,
    int elapsedMs,
  ) {
    if (elapsedMs < 1000) return const SizedBox.shrink();
    final seconds = elapsedMs ~/ 1000;
    final label = o.step != null
        ? stepText(l, o.step!, o.stepParams, o.progress)
        : o.thinkingRuns
        ? l.thinkingSection
        : l.steps_queue_wait;
    final status = [
      l.elapsed(seconds),
      if (o.expectedMs != null) l.usuallyAbout((o.expectedMs! / 1000).round()),
    ].join(' · ');
    final progress = o.progress;
    final known =
        !o.thinkingRuns &&
        progress != null &&
        progress.length == 2 &&
        progress[1] > 0;
    final muted = TextStyles.caption1.copyWith(color: p.muted);
    final Widget content;
    if (known) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.body1.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s4),
          AppProgressBar(value: (progress[0] / progress[1]).clamp(0, 1)),
          const SizedBox(height: Space.s4),
          Text(status, style: muted),
        ],
      );
    } else {
      content = SizedBox(
        height: Space.s24,
        child: Row(
          children: [
            if (o.thinkingRuns) const PulsingDot() else const AppSpinner(),
            const SizedBox(width: Space.s8),
            Flexible(
              child: Text(
                '$label …',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.body1.copyWith(color: p.text2),
              ),
            ),
            const SizedBox(width: Space.s8),
            Flexible(
              child: Text(
                status,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ],
        ),
      );
    }
    return SelectionContainer.disabled(
      child: FoundationFocus(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('status-line'),
            borderRadius: BorderRadius.circular(Radii.control),
            onTap: () => setState(() => _stages = !_stages),
            child: Tooltip(message: '$label · $status', child: content),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final o = widget.output;
    final elapsedMs = _now().difference(o.started).inMilliseconds;
    if (o.running && _clock == null) {
      // The first tick at 1 s shows the indicator (no indicator before 1 s).
      _clock = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!o.running) {
      _clock?.cancel();
      _clock = null;
    }
    final state = '${o.status}:${o.errorNumber}';
    if (_lastStatus != state) {
      _announcement = o.running
          ? l.answerStarted
          : o.status == 'failed'
          ? processMessage(l, o.errorNumber)
          : o.status == 'cancelled'
          ? l.cancelledLine
          : l.answerComplete;
      _lastStatus = state;
    }
    if (o.thinkingRuns) {
      _thinkingStarted ??= _now();
      _thoughtSeconds = _now().difference(_thinkingStarted!).inSeconds;
    } else {
      final stage = o.stages
          .where((stage) => stage.name == 'think')
          .firstOrNull;
      if (stage != null) _thoughtSeconds = (stage.timeMs / 1000).round();
    }
    final canRetry = widget.onRetry != null && o.errorNumber != securityBlock;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen readers hear the status changes, not each token (polite).
        Semantics(
          container: true,
          liveRegion: true,
          label: _announcement,
          child: const SizedBox.shrink(),
        ),
        if (o.running)
          Padding(
            padding: EdgeInsets.only(bottom: elapsedMs < 1000 ? 0 : Space.s8),
            child: _waitStatus(l, p, o, elapsedMs),
          ),
        if (_stages && o.stages.isNotEmpty)
          Padding(
            key: const Key('stage-timeline'),
            padding: const EdgeInsets.only(top: Space.s4, bottom: Space.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in o.stages)
                  Text(
                    '${stageText(l, s.name)}  ${stageStatus(l, s.status)}  ${s.timeMs} ms',
                    style: TextStyles.caption1.copyWith(
                      color: p.muted,
                      fontFamily: TextStyles.mono,
                    ),
                  ),
              ],
            ),
          ),
        if (o.thinking.isNotEmpty || o.thinkingRuns) _thinkingSection(l, p, o),
        if (o.answer.isNotEmpty) _Answer(text: o.answer.toString()),
        if (o.sources.isNotEmpty)
          Padding(
            key: const Key('sources'),
            padding: const EdgeInsets.only(top: Space.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.sources,
                  style: TextStyles.caption1Strong.copyWith(color: p.text2),
                ),
                const SizedBox(height: Space.s4),
                Wrap(
                  spacing: Space.s8,
                  runSpacing: Space.s8,
                  children: [
                    for (final (index, (title, url)) in o.sources.indexed)
                      SelectionContainer.disabled(
                        child: Tooltip(
                          message: title,
                          child: ActionChip(
                            visualDensity: Controls.tagDensity,
                            label: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${index + 1}  ${_short(title)}  ',
                                  ),
                                  TextSpan(
                                    text: Uri.tryParse(url)?.host ?? url,
                                    style: TextStyles.caption1.copyWith(
                                      color: p.muted,
                                    ),
                                  ),
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: Space.s4),
                                      child: Icon(
                                        AppIcons.externalLink,
                                        size: IconSizes.small,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => launchUrl(
                              Uri.parse(url),
                              webOnlyWindowName: '_blank',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (o.memories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: SelectionContainer.disabled(
              child: AppButton(
                key: const Key('used-memories'),
                kind: ButtonKind.subtle,
                size: ButtonSize.small,
                icon: AppIcons.memory,
                label: l.usedMemories(o.memories.length),
                onPressed: () => widget.onMemories?.call(o.memories),
              ),
            ),
          ),
        for (final (number, _) in o.notices)
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: NoticeLine(
              message: processMessage(l, number),
              kind: NoticeKind.warning,
            ),
          ),
        if (o.errorNumber != null || o.status == 'failed')
          Padding(
            padding: const EdgeInsets.only(top: Space.s12),
            child: SelectionContainer.disabled(
              child: MessageBar(
                key: const Key('output-error'),
                message: processMessage(l, o.errorNumber),
                kind: NoticeKind.error,
                icon: o.errorNumber == securityBlock
                    ? AppIcons.securityBlock
                    : null,
                actionLabel: canRetry ? l.retry : null,
                onAction: canRetry ? widget.onRetry : null,
              ),
            ),
          ),
        if (o.status == 'cancelled')
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: NoticeLine(message: l.cancelledLine),
          ),
        if (!o.running) ...[
          // Action row (#63): subtle 24 icon buttons with tooltips.
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: SelectionContainer.disabled(
              child: Row(
                children: [
                  CopyMessageButton(text: o.answer.toString()),
                  if (canRetry)
                    IconButton(
                      key: const Key('retry-output'),
                      tooltip: l.retry,
                      style: _smallIcon,
                      icon: const Icon(AppIcons.retry, size: IconSizes.small),
                      onPressed: widget.onRetry,
                    ),
                ],
              ),
            ),
          ),
          if (o.totalMs != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.s4),
              child: Text(
                l.statsLine(
                  TimeOfDay.fromDateTime(o.started.toLocal()).format(context),
                  (o.totalMs! / 1000).toStringAsFixed(1),
                  o.inputTokens ?? 0,
                  o.outputTokens ?? 0,
                ),
                key: const Key('stats-line'),
                style: TextStyles.caption1.copyWith(color: p.muted),
              ),
            ),
          if (o.answer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.s2),
              child: Text(
                l.aiNote,
                key: const Key('ai-note'),
                style: TextStyles.caption1.copyWith(color: p.muted),
              ),
            ),
        ],
      ],
    );
  }

  /// Thinking as a Fluent accordion (#63): a 32 px header (`body1Strong`,
  /// 16 px chevron that turns 180 degrees in 200 ms) and a body in `body1`
  /// `muted` with a 2 px `divider` line on the left and padding 8 x 12.
  Widget _thinkingSection(AppLocalizations l, Palette p, OutputView o) {
    final title = o.thinkingRuns
        ? '${l.thinkingSection} · ${l.elapsed(_thoughtSeconds)}'
        : o.stages.any((stage) => stage.name == 'think')
        ? l.thoughtFor(_thoughtSeconds)
        : l.thinkingSection;
    final duration = FoundationTokens.of(
      context,
    ).duration(context, MotionDurations.normal);
    return Container(
      key: const Key('thinking-section'),
      margin: const EdgeInsets.only(top: Space.s4, bottom: Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                button: true,
                expanded: _thinking,
                child: InkWell(
                  key: const Key('thinking-toggle'),
                  borderRadius: BorderRadius.circular(Radii.control),
                  onTap: () => setState(() => _thinking = !_thinking),
                  child: Tooltip(
                    message: _thinking ? l.collapseThinking : l.expandThinking,
                    child: SizedBox(
                      height: Space.s32,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedRotation(
                              turns: _thinking ? 0.5 : 0,
                              duration: duration,
                              curve: MotionCurves.easyEase,
                              child: Icon(
                                AppIcons.expand,
                                size: IconSizes.small,
                                color: p.text2,
                              ),
                            ),
                            const SizedBox(width: Space.s8),
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.body1Strong.copyWith(
                                  color: p.text,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (o.thinkingRuns && widget.onStopThinking != null) ...[
                AppButton(
                  key: const Key('stop-thinking'),
                  kind: ButtonKind.subtle,
                  size: ButtonSize.small,
                  label: l.stopThinking,
                  onPressed: widget.onStopThinking,
                ),
              ],
            ],
          ),
          if (_thinking)
            Container(
              key: const Key('thinking-body'),
              margin: const EdgeInsets.only(left: Space.s10),
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s12,
                vertical: Space.s8,
              ),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: p.divider, width: Strokes.thick),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final t in o.thinking) ...[
                    Text(
                      '${thinkingRole(l, t.role)} · ${l.roundN(t.round)}',
                      style: TextStyles.caption1Strong.copyWith(color: p.muted),
                    ),
                    Text(
                      t.text,
                      style: TextStyles.body1.copyWith(color: p.muted),
                    ),
                    const SizedBox(height: Space.s8),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Subtle 24 px icon button of the answer action row and the code block.
final _smallIcon = IconButton.styleFrom(
  padding: EdgeInsets.zero,
  fixedSize: const Size.square(Space.s24),
  minimumSize: const Size.square(Space.s24),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
);

/// Thinking indicator (#63): an 8 px `muted` dot, opacity 0.4 to 1 in a 1 s
/// loop with easyEase. Static with Reduce Motion.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key});
  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (reduce) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat(reverse: true);
    }
    final dot = Container(
      key: const Key('thinking-dot'),
      width: Space.s8,
      height: Space.s8,
      decoration: BoxDecoration(color: p.muted, shape: BoxShape.circle),
    );
    return SizedBox.square(
      dimension: Space.s16,
      child: Center(
        child: reduce
            ? dot
            : FadeTransition(
                opacity: Tween(begin: 0.4, end: 1.0).animate(
                  CurvedAnimation(
                    parent: controller,
                    curve: MotionCurves.easyEase,
                  ),
                ),
                child: dot,
              ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return MarkdownBody(
      key: const Key('answer'),
      data: text,
      selectable: false,
      onTapLink: (_, href, _) => href == null
          ? null
          : launchUrl(Uri.parse(href), webOnlyWindowName: '_blank'),
      // Answer text `body2`; headings h1 `subtitle1`, h2 `subtitle2`, h3
      // `body1Strong`; neutral underlined links; 8 px between list items (#63).
      styleSheet: MarkdownStyleSheet(
        a: TextStyles.body2.copyWith(
          color: p.text,
          decoration: TextDecoration.underline,
        ),
        p: TextStyles.body2.copyWith(color: p.text),
        listBullet: TextStyles.body2.copyWith(color: p.text),
        blockSpacing: Space.s8,
        code: TextStyles.code.copyWith(color: p.text),
        // The code block builder draws its own frame.
        codeblockDecoration: const BoxDecoration(),
        codeblockPadding: EdgeInsets.zero,
        tableColumnWidth: const IntrinsicColumnWidth(),
        h1: TextStyles.subtitle1.copyWith(color: p.text),
        h2: TextStyles.subtitle2.copyWith(color: p.text),
        h3: TextStyles.body1Strong.copyWith(color: p.text),
      ),
      builders: {'pre': _CodeBlock(p)},
    );
  }
}

/// Code block in mono with Copy (30.5.c).
class _CodeBlock extends MarkdownElementBuilder {
  _CodeBlock(this.p);
  final Palette p;
  @override
  bool isBlockElement() => true;
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    // Markdown keeps the last line break of a fenced block; drop it.
    final code = element.textContent.replaceFirst(RegExp(r'\n$'), '');
    final l = AppLocalizations.of(context);
    final language =
        element.children
            ?.whereType<md.Element>()
            .firstOrNull
            ?.attributes['class']
            ?.replaceFirst('language-', '') ??
        l.codeLabel;
    // Code block (#63): `surface`, radius 4, 1 px `divider`, a 32 px header
    // with the language and a subtle copy button, mono 14/20, padding 12.
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: Space.s12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.divider),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionContainer.disabled(
            child: Container(
              height: Space.s32,
              padding: const EdgeInsets.only(left: Space.s12, right: Space.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      language,
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                  ),
                  CopyMessageButton(text: code),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(Space.s12),
            child: Text(code, style: TextStyles.code.copyWith(color: p.text)),
          ),
        ],
      ),
    );
  }
}

/// Full-message copy stays available with keyboard and touch input.
class CopyMessageButton extends StatefulWidget {
  const CopyMessageButton({super.key, required this.text});
  final String text;
  @override
  State<CopyMessageButton> createState() => _CopyMessageButtonState();
}

class _CopyMessageButtonState extends State<CopyMessageButton> {
  bool copied = false;
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      liveRegion: copied,
      child: IconButton(
        tooltip: copied ? l.copied : l.copy,
        style: _smallIcon,
        icon: Icon(
          copied ? AppIcons.copied : AppIcons.copy,
          size: IconSizes.small,
        ),
        onPressed: widget.text.isEmpty
            ? null
            : () async {
                try {
                  await Clipboard.setData(ClipboardData(text: widget.text));
                } catch (_) {
                  if (!context.mounted) return;
                  showToast(
                    context,
                    message: l.copyFailed,
                    kind: NoticeKind.error,
                  );
                  return;
                }
                if (!mounted) return;
                setState(() => copied = true);
                timer?.cancel();
                timer = Timer(const Duration(seconds: 2), () {
                  if (mounted) setState(() => copied = false);
                });
              },
      ),
    );
  }
}
