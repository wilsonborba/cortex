import '../../theme/app_icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';

/// The six real stages of area 9 (24.B.2.c). The active stage moves every
/// [interval]; the loop is longer than 5 s, so it has Pause/Play (WCAG 2.2.2).
/// With Reduce Motion it is static with numbered stages.
class PipelineDiagram extends StatefulWidget {
  const PipelineDiagram({
    super.key,
    this.interval = const Duration(milliseconds: 1200),
  });
  final Duration interval;
  @override
  State<PipelineDiagram> createState() => _PipelineDiagramState();
}

class _PipelineDiagramState extends State<PipelineDiagram> {
  int _active = 0;
  bool _playing = true;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) == true;

  void _sync() {
    _timer?.cancel();
    if (_still || !_playing) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() => _active = (_active + 1) % 6);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final stages = [
      (l.stageAccept, l.stageAcceptText),
      (l.stageGather, l.stageGatherText),
      (l.stageAssemble, l.stageAssembleText),
      (l.stageThink, l.stageThinkText),
      (l.stageAnswer, l.stageAnswerText),
      (l.stageSave, l.stageSaveText),
    ];
    final still = _still;
    return Semantics(
      label: l.pipelineDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Space.s12,
            runSpacing: Space.s12,
            children: [
              for (final (i, (name, text)) in stages.indexed)
                AnimatedContainer(
                  duration: Motion.of(context),
                  curve: FoundationTokens.curve,
                  key: Key('stage-$i'),
                  width: 170,
                  padding: const EdgeInsets.all(Space.s12),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(
                      FoundationTokens.of(context).groupRadius,
                    ),
                    border: Border.all(
                      color: !still && i == _active ? p.text : p.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. $name', style: TextStyles.subsection),
                      const SizedBox(height: Space.s4),
                      Text(
                        text,
                        style: TextStyles.compact.copyWith(color: p.muted),
                      ),
                      if (i == 1) ...[
                        const SizedBox(height: Space.s8),
                        for (final part in [l.whatFiles, l.memory, l.webTitle])
                          Text(
                            '| $part',
                            style: TextStyles.label.copyWith(color: p.muted),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (!still)
            TextButton.icon(
              key: const Key('pipeline-toggle'),
              onPressed: () {
                setState(() => _playing = !_playing);
                _sync();
              },
              icon: Icon(_playing ? AppIcons.pause : AppIcons.play),
              label: Text(_playing ? l.pause : l.play),
            ),
        ],
      ),
    );
  }
}

/// The machines of 24.B.2.g, drawn in code.
class MachinesDiagram extends StatelessWidget {
  const MachinesDiagram({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    Widget box(String title, String text) => Container(
      width: 200,
      padding: const EdgeInsets.all(Space.s12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(
          FoundationTokens.of(context).groupRadius,
        ),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyles.label),
          Text(text, style: TextStyles.compact.copyWith(color: p.muted)),
        ],
      ),
    );
    return Semantics(
      label: l.machinesDescription,
      child: Wrap(
        spacing: Space.s12,
        runSpacing: Space.s12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          box('Cortex API', 'Rust, MSI'),
          Icon(AppIcons.next, color: p.muted),
          box('MSI GPU', 'Ollama, local LLM'),
          Icon(AppIcons.next, color: p.muted),
          box('Hippocampus', 'Rust, memory'),
          Icon(AppIcons.next, color: p.muted),
          box('Pong', 'Embeddings'),
          box('FSM', 'Files'),
          box('Database server', 'PostgreSQL, CouchDB, Redis'),
        ],
      ),
    );
  }
}

/// Memory scope tree: workspace, app, user (24.B.2.d).
class ScopeTree extends StatelessWidget {
  const ScopeTree({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    Widget row(int depth, IconData icon, String text) => Padding(
      padding: EdgeInsets.only(left: depth * 24.0, bottom: Space.s4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (depth > 0)
            Text(
              '|- ',
              style: TextStyles.compact.copyWith(
                color: p.muted,
                fontFamily: TextStyles.mono,
              ),
            ),
          Icon(icon, size: IconSizes.action, color: p.text),
          const SizedBox(width: Space.s8),
          Flexible(child: Text(text, style: TextStyles.compact)),
        ],
      ),
    );
    return Semantics(
      label: l.scopeDescription,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row(0, AppIcons.folder, 'workspace: cortex'),
          row(1, AppIcons.apps, 'app: cortex'),
          row(2, AppIcons.entity, 'user: x-uuid'),
          row(2, AppIcons.bot, 'no user: A2A'),
          row(1, AppIcons.apps, 'app: certifications'),
        ],
      ),
    );
  }
}

/// Example memory graph with graphview (marked Example, no personal data).
class ExampleGraph extends StatelessWidget {
  const ExampleGraph({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final graph = Graph();
    final labels = <String, String>{};
    Node n(String id, String label) {
      labels[id] = label;
      return Node.Id(id);
    }

    final m1 = n('m1', 'Memory: usage balancer'),
        m2 = n('m2', 'Memory: web modes');
    final t1 = n('t1', 'tag: cortex'),
        e1 = n('e1', 'entity: Ollama'),
        f1 = n('f1', 'file: plan.pdf');
    graph
      ..addEdge(m1, t1)
      ..addEdge(m2, t1)
      ..addEdge(m1, e1)
      ..addEdge(m2, f1);
    final config = FruchtermanReingoldAlgorithm(
      FruchtermanReingoldConfiguration(iterations: 300),
    );
    return Semantics(
      label: l.graphDescription,
      excludeSemantics: true,
      child: SizedBox(
        height: 260,
        child: InteractiveViewer(
          constrained: false,
          child: GraphView(
            graph: graph,
            algorithm: config,
            paint: Paint()
              ..color = p.muted
              ..strokeWidth = 1
              ..style = PaintingStyle.stroke,
            builder: (node) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s8,
                vertical: Space.s4,
              ),
              decoration: BoxDecoration(
                color: p.surface,
                border: Border.all(color: p.border),
                borderRadius: BorderRadius.circular(
                  FoundationTokens.of(context).controlRadius,
                ),
              ),
              child: Text(labels[node.key!.value]!, style: TextStyles.label),
            ),
          ),
        ),
      ),
    );
  }
}
