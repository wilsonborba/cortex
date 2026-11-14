import '../../theme/app_icons.dart';
import 'dart:async';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/models/output.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
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
  bool _hovered = false, _focused = false, _touch = false;
  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final o = widget.output;
    final elapsed = _now().difference(o.started).inSeconds;
    if (o.running && _clock == null) {
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
    final statusText =
        '${o.step == null ? l.steps_queue_wait : stepText(l, o.step!, o.stepParams, o.progress)} · ${l.elapsed(elapsed)}${o.expectedMs == null ? '' : ' · ${l.usuallyAbout((o.expectedMs! / 1000).round())}'}';
    return Focus(
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: (_) => setState(() {
          _hovered = true;
          _touch = false;
        }),
        onExit: (_) => setState(() => _hovered = false),
        child: Listener(
          onPointerDown: (event) {
            if (event.kind == PointerDeviceKind.touch) {
              setState(() => _touch = true);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                container: true,
                liveRegion: true,
                label: _announcement,
                child: const SizedBox.shrink(),
              ),
              if (o.running)
                SelectionContainer.disabled(
                  child: FoundationFocus(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('status-line'),
                        onTap: () => setState(() => _stages = !_stages),
                        child: SizedBox(
                          height: Space.s24,
                          child: Tooltip(
                            message: statusText,
                            child: Row(
                              children: [
                                const AppSpinner(),
                                const SizedBox(width: Space.s8),
                                Expanded(
                                  child: Text(
                                    statusText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.compact.copyWith(
                                      color: p.muted,
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
                ),
              if (_stages && o.stages.isNotEmpty)
                Padding(
                  key: const Key('stage-timeline'),
                  padding: const EdgeInsets.only(bottom: Space.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final s in o.stages)
                        Text(
                          '${stageText(l, s.name)}  ${stageStatus(l, s.status)}  ${s.timeMs} ms',
                          style: TextStyles.label.copyWith(
                            color: p.muted,
                            fontFamily: TextStyles.mono,
                          ),
                        ),
                    ],
                  ),
                ),
              if (o.thinking.isNotEmpty || o.thinkingRuns)
                _thinkingSection(l, p, o),
              if (o.answer.isNotEmpty) _Answer(text: o.answer.toString()),
              if (o.sources.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s12),
                  child: Wrap(
                    spacing: Space.s8,
                    runSpacing: Space.s8,
                    children: [
                      for (final (index, (title, url)) in o.sources.indexed)
                        SelectionContainer.disabled(
                          child: ActionChip(
                            visualDensity: Controls.tagDensity,
                            avatar: const Icon(AppIcons.web),
                            label: Text(
                              '[${index + 1}] $title · ${Uri.tryParse(url)?.host ?? url}',
                              overflow: TextOverflow.ellipsis,
                            ),
                            onPressed: () => launchUrl(
                              Uri.parse(url),
                              webOnlyWindowName: '_blank',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (o.memories.isNotEmpty)
                SelectionContainer.disabled(
                  child: TextButton.icon(
                    key: const Key('used-memories'),
                    onPressed: () => widget.onMemories?.call(o.memories),
                    icon: const Icon(AppIcons.memory, size: IconSizes.action),
                    label: Text(l.usedMemories(o.memories.length)),
                  ),
                ),
              for (final (number, _) in o.notices)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s4),
                  child: NoticeLine(
                    message: processMessage(l, number),
                    kind: NoticeKind.warning,
                  ),
                ),
              if (o.errorNumber != null || o.status == 'failed')
                Padding(
                  padding: const EdgeInsets.only(top: Space.s12),
                  child: Row(
                    children: [
                      Icon(
                        o.errorNumber == securityBlock
                            ? AppIcons.securityBlock
                            : AppIcons.error,
                        color: p.dangerForeground,
                        size: IconSizes.action,
                      ),
                      const SizedBox(width: Space.s8),
                      Flexible(
                        child: Text(
                          processMessage(l, o.errorNumber),
                          key: const Key('output-error'),
                          style: TextStyles.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              if (o.status == 'cancelled') NoticeLine(message: l.cancelledLine),
              if (!o.running)
                Visibility(
                  visible:
                      _hovered ||
                      _focused ||
                      _touch ||
                      !RendererBinding.instance.mouseTracker.mouseIsConnected,
                  maintainSize: true,
                  maintainState: true,
                  maintainAnimation: true,
                  child: SelectionContainer.disabled(
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.s12),
                      child: Row(
                        children: [
                          CopyMessageButton(text: o.answer.toString()),
                          if (widget.onRetry != null &&
                              o.errorNumber != securityBlock)
                            TextButton.icon(
                              onPressed: widget.onRetry,
                              icon: const Icon(AppIcons.retry),
                              label: Text(l.retry),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!o.running && o.totalMs != null)
                Padding(
                  padding: const EdgeInsets.only(top: Space.s4),
                  child: Text(
                    l.statsLine(
                      TimeOfDay.fromDateTime(
                        o.started.toLocal(),
                      ).format(context),
                      (o.totalMs! / 1000).toStringAsFixed(1),
                      o.inputTokens ?? 0,
                      o.outputTokens ?? 0,
                    ),
                    key: const Key('stats-line'),
                    style: TextStyles.label.copyWith(
                      color: p.muted,
                      fontFamily: TextStyles.mono,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thinkingSection(AppLocalizations l, Palette p, OutputView o) {
    return Container(
      key: const Key('thinking-section'),
      margin: const EdgeInsets.only(bottom: Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                o.thinkingRuns
                    ? '${l.thinkingSection} · ${l.elapsed(_thoughtSeconds)}'
                    : o.stages.any((stage) => stage.name == 'think')
                    ? l.thoughtFor(_thoughtSeconds)
                    : l.thinkingSection,
                style: TextStyles.label,
              ),
              if (o.thinkingRuns && widget.onStopThinking != null)
                TextButton(
                  key: const Key('stop-thinking'),
                  onPressed: widget.onStopThinking,
                  child: Text(l.stopThinking),
                ),
              IconButton(
                tooltip: _thinking ? l.collapseThinking : l.expandThinking,
                icon: Icon(
                  _thinking ? AppIcons.collapse : AppIcons.expand,
                  size: IconSizes.action,
                ),
                onPressed: () => setState(() => _thinking = !_thinking),
              ),
            ],
          ),
          if (_thinking)
            for (final t in o.thinking) ...[
              Text(
                '${thinkingRole(l, t.role)} · ${l.roundN(t.round)}',
                style: TextStyles.label.copyWith(color: p.muted),
              ),
              Text(t.text, style: TextStyles.compact.copyWith(color: p.muted)),
              const SizedBox(height: Space.s8),
            ],
        ],
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
      styleSheet: MarkdownStyleSheet(
        a: TextStyles.body.copyWith(
          color: p.text,
          decoration: TextDecoration.underline,
        ),
        p: TextStyles.body.copyWith(color: p.text),
        code: TextStyles.compact.copyWith(
          fontFamily: TextStyles.mono,
          color: p.text,
        ),
        codeblockDecoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(
            FoundationTokens.of(context).controlRadius,
          ),
        ),
        tableColumnWidth: const IntrinsicColumnWidth(),
        h1: TextStyles.section,
        h2: TextStyles.subsection,
        h3: TextStyles.body.copyWith(fontWeight: FontWeight.w600),
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
    final code = element.textContent;
    final l = AppLocalizations.of(context);
    final language =
        element.children
            ?.whereType<md.Element>()
            .firstOrNull
            ?.attributes['class']
            ?.replaceFirst('language-', '') ??
        l.codeLabel;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: Space.s12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(
          FoundationTokens.of(context).groupRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionContainer.disabled(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      language,
                      style: TextStyles.label.copyWith(color: p.muted),
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
            child: Text(
              code,
              style: TextStyles.compact.copyWith(
                fontFamily: TextStyles.mono,
                color: p.text,
              ),
            ),
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
        icon: Icon(
          copied ? AppIcons.copied : AppIcons.copy,
          size: IconSizes.action,
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
