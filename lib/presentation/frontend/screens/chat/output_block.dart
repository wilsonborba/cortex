import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/models/output.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import 'step_text.dart';

/// The security block number (area 9.5): shown with a Material icon, no emoji (C1).
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
  });
  final OutputView output;
  final VoidCallback? onStopThinking;
  final VoidCallback? onRetry;
  final ValueChanged<List<(String, String)>>? onMemories;
  @override
  State<OutputBlock> createState() => _OutputBlockState();
}

class _OutputBlockState extends State<OutputBlock> {
  bool _stages = false;
  bool _thinking = true;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final o = widget.output;
    final elapsed = DateTime.now().difference(o.started).inSeconds;
    final total = o.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (o.running)
          InkWell(
            key: const Key('status-line'),
            onTap: () => setState(() => _stages = !_stages),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: Space.s8,
                    runSpacing: Space.s4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 12,
                        child: MediaQuery.disableAnimationsOf(context)
                            ? const Icon(Icons.hourglass_empty, size: 12)
                            : CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: p.muted,
                              ),
                      ),
                      const SizedBox(width: Space.s8),
                      Text(
                        o.step == null
                            ? l.steps_queue_wait
                            : stepText(l, o.step!, o.stepParams, o.progress),
                        style: TextStyles.compact.copyWith(color: p.muted),
                      ),
                      const SizedBox(width: Space.s8),
                      Text(
                        l.elapsed(elapsed),
                        style: TextStyles.label.copyWith(color: p.muted),
                      ),
                      if (o.expectedMs != null) ...[
                        const SizedBox(width: Space.s8),
                        Text(
                          l.usuallyAbout((o.expectedMs! / 1000).round()),
                          style: TextStyles.label.copyWith(color: p.muted),
                        ),
                      ],
                    ],
                  ),
                  if (total != null && total.length == 2 && total[1] > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.s4),
                      child: LinearProgressIndicator(
                        value: total[0] / total[1],
                        color: p.text,
                        backgroundColor: p.border,
                        minHeight: 2,
                      ),
                    ),
                ],
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
        if (o.thinking.isNotEmpty) _thinkingSection(l, p, o),
        if (o.answer.isNotEmpty) _Answer(text: o.answer.toString()),
        if (o.sources.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: Wrap(
              spacing: Space.s8,
              runSpacing: Space.s8,
              children: [
                for (final (title, url) in o.sources)
                  ActionChip(
                    avatar: const Icon(Icons.public, size: 16),
                    label: Text(
                      '$title · ${Uri.tryParse(url)?.host ?? url}',
                      style: TextStyles.label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () =>
                        launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
                  ),
              ],
            ),
          ),
        if (o.memories.isNotEmpty)
          TextButton.icon(
            key: const Key('used-memories'),
            onPressed: () => widget.onMemories?.call(o.memories),
            icon: const Icon(Icons.hub_outlined, size: 16),
            label: Text(l.usedMemories(o.memories.length)),
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
            padding: const EdgeInsets.only(top: Space.s8),
            child: Row(
              children: [
                Icon(
                  o.errorNumber == securityBlock
                      ? Icons.gpp_bad_outlined
                      : Icons.error_outline,
                  color: p.danger,
                  size: 18,
                ),
                const SizedBox(width: Space.s8),
                Flexible(
                  child: Text(
                    processMessage(l, o.errorNumber),
                    key: const Key('output-error'),
                    style: TextStyles.compact,
                  ),
                ),
                if (widget.onRetry != null &&
                    o.errorNumber != securityBlock) ...[
                  const SizedBox(width: Space.s8),
                  AppButton(
                    label: l.retry,
                    icon: Icons.refresh,
                    onPressed: widget.onRetry,
                  ),
                ],
              ],
            ),
          ),
        if (o.status == 'cancelled') NoticeLine(message: l.cancelledLine),
        if (!o.running && o.totalMs != null)
          Padding(
            padding: const EdgeInsets.only(top: Space.s4),
            child: Text(
              l.statsLine(
                TimeOfDay.fromDateTime(o.started).format(context),
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
    );
  }

  Widget _thinkingSection(AppLocalizations l, Palette p, OutputView o) {
    return Container(
      key: const Key('thinking-section'),
      margin: const EdgeInsets.only(bottom: Space.s8),
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.thinkingSection, style: TextStyles.label),
              if (o.thinkingRuns && widget.onStopThinking != null)
                TextButton(
                  key: const Key('stop-thinking'),
                  onPressed: widget.onStopThinking,
                  child: Text(l.stopThinking),
                ),
              IconButton(
                tooltip: _thinking ? l.collapseThinking : l.expandThinking,
                icon: Icon(
                  _thinking ? Icons.expand_less : Icons.expand_more,
                  size: 18,
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
    final p = Palette.of(Theme.of(context).brightness);
    return MarkdownBody(
      key: const Key('answer'),
      data: text,
      selectable: true,
      onTapLink: (_, href, _) => href == null
          ? null
          : launchUrl(Uri.parse(href), webOnlyWindowName: '_blank'),
      styleSheet: MarkdownStyleSheet(
        p: TextStyles.body.copyWith(color: p.text),
        code: TextStyles.compact.copyWith(
          fontFamily: TextStyles.mono,
          color: p.text,
        ),
        codeblockDecoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.border),
          borderRadius: BorderRadius.circular(Radii.control),
        ),
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
    final code = element.textContent.trimRight();
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: Space.s8),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.border),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              Space.s12,
              Space.s12,
              Space.s48,
              Space.s12,
            ),
            child: Text(
              code,
              style: TextStyles.compact.copyWith(
                fontFamily: TextStyles.mono,
                color: p.text,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              tooltip: l.copy,
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.maybeOf(
                  context,
                )?.showSnackBar(SnackBar(content: Text(l.copied)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
