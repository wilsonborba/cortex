import '../../widgets/common/surfaces.dart';
import '../../theme/app_icons.dart';
import 'dart:math' as math;
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../domain/services/memory_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/states.dart';
import 'memory_card.dart';

/// Memory screen (issue #32): graph or list of the same nodes, and the card of
/// the node in the path /v1/memory/:node_id.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({
    super.key,
    required this.controller,
    this.nodeId,
    this.now,
  });
  final MemoryController controller;
  final String? nodeId;
  final DateTime Function()? now;
  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  MemoryController get memory => widget.controller;
  MemoryView get view => memory.view;

  @override
  void initState() {
    super.initState();
    memory.addListener(_changed);
    _refreshAfterBuild(refreshGraph: widget.nodeId == null);
  }

  @override
  void didUpdateWidget(MemoryScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      memory.addListener(_changed);
    }
    if (old.controller != widget.controller || old.nodeId != widget.nodeId) {
      _refreshAfterBuild(refreshGraph: old.controller != widget.controller);
    }
  }

  @override
  void dispose() {
    memory.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _refreshAfterBuild({bool refreshGraph = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if ((refreshGraph || memory.graph == null) && !memory.loading) {
        memory.load();
      }
      memory.open(widget.nodeId);
    });
  }

  void _go(String id) =>
      GoRouter.maybeOf(context)?.go('/v1/memory/${Uri.encodeComponent(id)}');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final graph = memory.graph;
    final Widget body;
    if (memory.error != null) {
      body = ErrorState(
        message: apiFailure(l, memory.error),
        retryLabel: l.retry,
        onRetry: memory.load,
      );
    } else if (graph == null) {
      body = const Center(child: SkeletonBox(width: 240));
    } else if (graph.nodes.isEmpty) {
      body = EmptyState(title: l.noMemories, icon: AppIcons.memory);
    } else {
      body = view == MemoryView.graph
          ? _GraphView(data: graph, selected: widget.nodeId, onTap: _go)
          : _ListView(data: graph, selected: widget.nodeId, onTap: _go);
    }
    final card = widget.nodeId == null
        ? null
        : memory.nodeLoading
        ? const SkeletonBox(width: 240)
        : memory.nodeError != null
        ? ErrorState(
            message: apiFailure(l, memory.nodeError),
            retryLabel: l.retry,
            onRetry: () => memory.open(widget.nodeId),
          )
        : memory.node?.node == null
        ? null
        : MemoryCard(data: memory.node!, onOpen: _go, now: widget.now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Space.s16,
            vertical: Space.s8,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Wrap(
            spacing: Space.s16,
            runSpacing: Space.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l.memory, style: TextStyles.subsection),
              SegmentedButton<MemoryView>(
                key: const Key('view-switch'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: MemoryView.graph,
                    label: Text(l.graphView),
                    icon: const Icon(AppIcons.memory, size: IconSizes.action),
                  ),
                  ButtonSegment(
                    value: MemoryView.list,
                    label: Text(l.listView),
                    icon: const Icon(AppIcons.list, size: IconSizes.action),
                  ),
                ],
                selected: {view},
                onSelectionChanged: (v) => memory.setView(v.first),
              ),
              _Picker(
                key: const Key('depth'),
                label: l.depthLabel,
                value: memory.depth,
                values: MemoryController.depths,
                onChanged: memory.setDepth,
              ),
              _Picker(
                key: const Key('limit'),
                label: l.limitLabel,
                value: memory.limit,
                values: MemoryController.limits,
                onChanged: memory.setLimit,
              ),
            ],
          ),
        ),
        if (graph?.truncated == true)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Space.s16,
              Space.s8,
              Space.s16,
              0,
            ),
            child: NoticeLine(
              key: const Key('truncated'),
              message: l.graphTruncated,
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) {
              if (card == null) return body;
              final pane = SingleChildScrollView(
                padding: const EdgeInsets.all(Space.s16),
                child: card,
              );
              // Compact width: the card above the graph; wide: side by side.
              if (box.maxWidth < 720) {
                return Column(
                  children: [
                    Flexible(child: pane),
                    Divider(height: 1, color: p.border),
                    Expanded(child: body),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: body),
                  Container(
                    width: 360,
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: p.border)),
                    ),
                    child: pane,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  final String label;
  final int value;
  final List<int> values;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Space.s4,
    runSpacing: Space.s4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$label:', style: TextStyles.compact),
      FoundationFocus(
        child: AppSelect<int>(
          value: value,
          underline: const SizedBox(),
          items: [
            for (final v in values)
              DropdownMenuItem(
                value: v,
                child: Text('$v', style: TextStyles.compact),
              ),
          ],
          onChanged: (v) => onChanged(v!),
        ),
      ),
    ],
  );
}

/// The legend: the 4 node types with their icons.
class _Legend extends StatelessWidget {
  const _Legend({required this.hasEntities});
  final bool hasEntities;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Wrap(
      key: const Key('legend'),
      spacing: Space.s12,
      children: [
        for (final type in [
          'memory',
          'tag',
          'persona',
          'file',
          if (hasEntities) 'entity',
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(nodeIcon(type), size: IconSizes.chip, color: p.muted),
              const SizedBox(width: Space.s4),
              Text(
                nodeTypeName(l, type),
                style: TextStyles.label.copyWith(color: p.muted),
              ),
            ],
          ),
      ],
    );
  }
}

/// Pan and zoom graph (32.1); a node tap opens its path.
class _GraphView extends StatefulWidget {
  const _GraphView({
    required this.data,
    required this.selected,
    required this.onTap,
  });
  final MemoryGraphData data;
  final String? selected;
  final ValueChanged<String> onTap;
  @override
  State<_GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<_GraphView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: Duration.zero,
  );
  final _transform = TransformationController();
  final _canvasKey = GlobalKey();
  Size? _viewport;
  bool _fitPending = true;
  final selected = ValueNotifier<String?>(null);
  late Widget canvas;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildGraph();
  }

  @override
  void didUpdateWidget(_GraphView old) {
    super.didUpdateWidget(old);
    selected.value = widget.selected;
    if (!identical(old.data, widget.data)) _buildGraph();
  }

  @override
  void dispose() {
    selected.dispose();
    _motion.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _buildGraph() {
    selected.value = widget.selected;
    final p = Palette.from(context);
    final graph = Graph();
    final nodes = {for (final n in widget.data.nodes) n.id: n};
    // Deterministic starting positions also separate isolated memories.
    for (final (i, n) in widget.data.nodes.indexed) {
      final angle = i * math.pi * 2 / nodes.length;
      final node = Node.Id(n.id);
      // A zero origin lets graphview initialize its rectangle cache after
      // measuring node dimensions; the other seeds remain deterministic.
      node.position = i == 0
          ? Offset.zero
          : Offset(math.cos(angle) * 160, math.sin(angle) * 160);
      graph.addNode(node);
    }
    for (final edge in widget.data.edges) {
      if (nodes.containsKey(edge.source) && nodes.containsKey(edge.target)) {
        graph.addEdge(
          graph.getNodeUsingId(edge.source),
          graph.getNodeUsingId(edge.target),
        );
      }
    }
    _fitPending = true;
    canvas = GraphViewWidget(
      key: _canvasKey,
      nodeAnimationController: _motion,
      enableAnimation: false,
      paint: Paint()
        ..color = p.border
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      delegate: _MemoryGraphDelegate(
        graph: graph,
        algorithm: _MemoryLayout(),
        builder: (node) {
          final item = nodes[node.key!.value]!;
          return ValueListenableBuilder<String?>(
            valueListenable: selected,
            builder: (context, focus, _) {
              final on = item.id == focus;
              return Semantics(
                button: true,
                selected: on,
                label: item.label,
                child: Tooltip(
                  message: item.label,
                  child: FoundationFocus(
                    child: InkWell(
                      key: Key('graph-node-${item.id}'),
                      onTap: () => widget.onTap(item.id),
                      borderRadius: BorderRadius.circular(
                        FoundationTokens.of(context).controlRadius,
                      ),
                      child: SizedBox(
                        width: 132,
                        child: Padding(
                          padding: const EdgeInsets.all(Space.s8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: Motion.of(context),
                                curve: FoundationTokens.curve,
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.surface,
                                  border: Border.all(
                                    color: on ? p.accent : p.muted,
                                    width: on
                                        ? Controls.focusRing
                                        : Controls.border,
                                  ),
                                ),
                                child: Icon(
                                  nodeIcon(item.displayType),
                                  size: IconSizes.chip,
                                  color: p.text,
                                ),
                              ),
                              const SizedBox(height: Space.s8),
                              Text(
                                item.label,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.label,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, box) {
              final viewport = Size(box.maxWidth, box.maxHeight);
              if (_fitPending || _viewport != viewport) {
                _fitPending = false;
                _viewport = viewport;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final render = _canvasKey.currentContext?.findRenderObject();
                  if (render is! RenderBox ||
                      !render.hasSize ||
                      render.size.isEmpty) {
                    return;
                  }
                  final scale = math
                      .min(
                        (viewport.width - 48) / render.size.width,
                        (viewport.height - 64) / render.size.height,
                      )
                      .clamp(0.01, 1.0);
                  _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
                    ..setTranslationRaw(
                      (viewport.width - render.size.width * scale) / 2,
                      (viewport.height - render.size.height * scale) / 2,
                      0,
                    );
                });
              }
              return Semantics(
                key: const Key('memory-graph'),
                label: l.memoryGraphDescription,
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(1000),
                  minScale: 0.01,
                  maxScale: 3,
                  child: canvas,
                ),
              );
            },
          ),
        ),
        Positioned(
          left: Space.s16,
          bottom: Space.s16,
          child: _Legend(
            hasEntities: widget.data.nodes.any(
              (n) => n.displayType == 'entity',
            ),
          ),
        ),
      ],
    );
  }
}

/// The same nodes as a list (32.2), the accessible view.
class _ListView extends StatelessWidget {
  const _ListView({
    required this.data,
    required this.selected,
    required this.onTap,
  });
  final MemoryGraphData data;
  final String? selected;
  final ValueChanged<String> onTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return ListView.builder(
      key: const Key('memory-list'),
      padding: const EdgeInsets.all(Space.s8),
      itemCount: data.nodes.length,
      itemBuilder: (_, i) {
        final n = data.nodes[i];
        return FoundationFocus(
          child: ListTile(
            key: Key('list-node-${n.id}'),
            dense: true,
            selected: n.id == selected,
            selectedTileColor: p.raised,
            leading: Icon(
              nodeIcon(n.displayType),
              size: IconSizes.action,
              color: p.muted,
            ),
            title: Text(
              n.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.compact.copyWith(color: p.text),
            ),
            subtitle: Text(
              nodeTypeName(l, n.displayType),
              style: TextStyles.label.copyWith(color: p.muted),
            ),
            onTap: () => onTap(n.id),
          ),
        );
      },
    );
  }
}

/// graphview 1.5.1 derives visible nodes from edges, losing isolated memories.
/// The scoped API result already defines the complete set of visible nodes.
class _MemoryGraphDelegate extends GraphChildDelegate {
  _MemoryGraphDelegate({
    required super.graph,
    required super.algorithm,
    required super.builder,
  }) : super(controller: null);
  @override
  Graph getVisibleGraphOnly() => graph;
}

/// Retain the first isolated component, including a graph with just one node.
class _MemoryLayout extends FruchtermanReingoldAlgorithm {
  _MemoryLayout()
    : super(
        FruchtermanReingoldConfiguration(iterations: 300, shuffleNodes: false),
      );
  @override
  void combineSingleNodeCluster(List<NodeCluster> clusters) {
    NodeCluster? first;
    for (final cluster in clusters) {
      if (cluster.size() != 1) continue;
      if (first == null) {
        first = cluster;
      } else {
        first.concat(cluster);
      }
    }
    clusters.removeWhere(
      (cluster) => cluster.size() == 1 && !identical(cluster, first),
    );
  }
}
