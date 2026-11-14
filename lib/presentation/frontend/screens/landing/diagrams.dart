import '../../theme/app_icons.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'dart:math' as math;
import '../../../../domain/models/memory_graph.dart';
import '../memory/graph_canvas.dart';
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
                  curve: FoundationTokens.hoverCurve,
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

/// The public example uses the same fitted canvas with synthetic localised data.
class ExampleGraph extends StatelessWidget {
  const ExampleGraph({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = MemoryGraphData(
      [
        GraphNode('example-chat', 'chat', l.exampleChat, const {}),
        GraphNode('example-one', 'memory', l.exampleMemoryOne, const {}),
        GraphNode('example-two', 'memory', l.exampleMemoryTwo, const {}),
        GraphNode('example-tag', 'tag', l.exampleTag, const {}),
        GraphNode('example-file', 'file', l.exampleFile, const {}),
        GraphNode('example-project', 'entity', l.exampleEntity, const {}),
      ],
      const [
        GraphEdge('example-one', 'example-chat', 'created_in'),
        GraphEdge('example-two', 'example-chat', 'created_in'),
        GraphEdge('example-one', 'example-tag', 'tagged_with'),
        GraphEdge('example-two', 'example-file', 'references'),
        GraphEdge('example-one', 'example-project', 'mentions'),
      ],
      false,
      null,
    );
    return Semantics(
      label: l.graphDescription,
      child: LayoutBuilder(
        builder: (context, box) => SizedBox(
          height: math.max(
            GraphTokens.exampleMinHeight,
            box.maxWidth * GraphTokens.exampleRatio,
          ),
          child: GraphCanvas(data: data, showControls: false, onSelect: (_) {}),
        ),
      ),
    );
  }
}

/// Engineering diagram frame (#70): the neutral dark canvas `#1C1C1E`,
/// radius 8, a subtle 1 px border, and the Fluent dark palette inside for
/// high contrast text in both themes.
class DiagramCanvas extends StatelessWidget {
  const DiagramCanvas({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: cortexTheme(Brightness.dark),
    child: Builder(
      builder: (context) => Container(
        key: const Key('diagram-canvas'),
        width: double.infinity,
        padding: const EdgeInsets.all(Space.s24),
        decoration: BoxDecoration(
          color: DiagramPalette.canvas,
          borderRadius: BorderRadius.circular(Radii.dialog),
          border: Border.all(color: Palette.from(context).divider),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: Palette.from(context).text),
          child: IconTheme.merge(
            data: IconThemeData(color: Palette.from(context).text),
            child: child,
          ),
        ),
      ),
    ),
  );
}
