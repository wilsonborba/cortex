import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';

enum DemoKind { memory, fastWeb, deepWeb, thinking }

class _Script {
  const _Script(
    this.prompt,
    this.steps,
    this.answer, {
    this.sources = const [],
    this.memories = const [],
  });
  final String prompt;
  final List<String> steps;
  final String answer;
  final List<String> sources;
  final List<String> memories;
}

_Script _script(AppLocalizations l, DemoKind kind) => switch (kind) {
  DemoKind.memory => _Script(
    l.demoMemoryPrompt,
    [
      l.stepSecurity,
      l.stepMemorySearch,
      '${l.stepMemoriesFound}: 2',
      l.stepAnswer,
    ],
    l.demoMemoryAnswer,
    memories: const ['Usage balancer', 'Loyalty weight'],
  ),
  DemoKind.fastWeb => _Script(
    l.demoFastPrompt,
    [
      l.stepSecurity,
      l.stepWebSearch,
      '${l.stepPageRead}: 1 / 5',
      '${l.stepPageRead}: 5 / 5',
      l.stepAnswer,
    ],
    l.demoFastAnswer,
    sources: const ['blog.rust-lang.org', 'github.com/rust-lang/rust'],
  ),
  DemoKind.deepWeb => _Script(
    l.demoDeepPrompt,
    [
      l.stepSecurity,
      '${l.stepQueries}: 4',
      l.stepWebSearch,
      '${l.stepPageRead}: 3 / 10',
      '${l.stepPageRead}: 10 / 10',
      l.stepAnswer,
    ],
    l.demoDeepAnswer,
    sources: const ['sqlite.org', 'postgresql.org'],
  ),
  DemoKind.thinking => _Script(l.demoThinkPrompt, [
    l.stepSecurity,
    '${l.stepThinking}: plan',
    '${l.stepThinking}: work',
    '${l.stepThinking}: check',
    l.stepAnswer,
  ], l.demoThinkAnswer),
};

/// Scripted chat demo marked Example (24.B.2.a). No model call and no text box.
class ChatDemo extends StatefulWidget {
  const ChatDemo({
    super.key,
    this.stepDelay = const Duration(milliseconds: 450),
  });
  final Duration stepDelay;
  @override
  State<ChatDemo> createState() => _ChatDemoState();
}

class _ChatDemoState extends State<ChatDemo> {
  DemoKind _kind = DemoKind.memory;
  int _shown = 0;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null && _shown == 0) _play(_kind);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play(DemoKind kind) {
    _timer?.cancel();
    final total = _script(AppLocalizations.of(context), kind).steps.length + 1;
    setState(() {
      _kind = kind;
      _shown = 0;
    });
    // Reduce Motion: the end state at once, no step replay.
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) {
      setState(() => _shown = total);
      return;
    }
    _timer = Timer.periodic(widget.stepDelay, (t) {
      if (!mounted) return t.cancel();
      setState(() => _shown++);
      if (_shown >= total) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    return AppCard(
      key: const Key('chat-demo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(Radii.control),
                ),
                child: Text(
                  l.example,
                  style: TextStyles.label.copyWith(color: p.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.s12),
          Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              for (final k in DemoKind.values)
                AppChip(
                  key: Key('demo-${k.name}'),
                  label: _script(l, k).prompt,
                  selected: k == _kind,
                  onSelected: (_) => _play(k),
                ),
            ],
          ),
          const SizedBox(height: Space.s16),
          // IndexedStack measures every complete localized script. The card
          // keeps its final height while the selected transcript fades in place.
          IndexedStack(
            index: _kind.index,
            alignment: Alignment.topLeft,
            children: [
              for (final kind in DemoKind.values)
                _DemoTranscript(
                  script: _script(l, kind),
                  shown: kind == _kind ? _shown : 0,
                  active: kind == _kind,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoTranscript extends StatelessWidget {
  const _DemoTranscript({
    required this.script,
    required this.shown,
    required this.active,
  });
  final _Script script;
  final int shown;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final s = script;
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final done = shown > s.steps.length;
    Widget reveal(bool visible, Widget child) => ExcludeSemantics(
      excluding: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: Motion.of(context),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(Space.s12),
              decoration: BoxDecoration(
                color: p.background,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: Text(s.prompt, style: TextStyles.body),
            ),
          ),
          const SizedBox(height: Space.s12),
          for (final (i, step) in s.steps.indexed)
            reveal(
              i < shown,
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s4),
                child: Row(
                  children: [
                    Icon(
                      i == shown - 1 && !done
                          ? Icons.radio_button_checked
                          : Icons.check,
                      size: 14,
                      color: i == shown - 1 && !done ? p.accent : p.muted,
                    ),
                    const SizedBox(width: Space.s8),
                    Flexible(
                      child: Text(
                        step,
                        style: TextStyles.compact.copyWith(color: p.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          reveal(
            done,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.memories.isNotEmpty)
                  Wrap(
                    spacing: Space.s8,
                    children: [
                      for (final m in s.memories)
                        Chip(label: Text(m, style: TextStyles.label)),
                    ],
                  ),
                const SizedBox(height: Space.s8),
                Text(
                  s.answer,
                  key: active && done ? const Key('demo-answer') : null,
                  style: TextStyles.body,
                ),
                if (s.sources.isNotEmpty) ...[
                  const SizedBox(height: Space.s8),
                  Text(
                    l.sources,
                    style: TextStyles.label.copyWith(color: p.muted),
                  ),
                  for (final (i, src) in s.sources.indexed)
                    Text(
                      '${i + 1}. $src',
                      style: TextStyles.compact.copyWith(color: p.muted),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
