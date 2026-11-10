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
    _refreshAfterBuild();
  }

  @override
  void didUpdateWidget(MemoryScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      memory.addListener(_changed);
    }
    if (old.controller != widget.controller || old.nodeId != widget.nodeId) {
      _refreshAfterBuild();
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

  void _refreshAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (memory.graph == null && !memory.loading) memory.load();
      memory.open(widget.nodeId);
    });
  }

  void _go(String id) =>
      GoRouter.maybeOf(context)?.go('/v1/memory/${Uri.encodeComponent(id)}');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
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
      body = EmptyState(title: l.noMemories, icon: Icons.hub_outlined);
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
                    icon: const Icon(Icons.hub_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: MemoryView.list,
                    label: Text(l.listView),
                    icon: const Icon(Icons.list, size: 16),
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
      DropdownButton<int>(
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
    final p = Palette.of(Theme.of(context).brightness);
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
              Icon(nodeIcon(type), size: 14, color: p.muted),
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
class _GraphView extends StatelessWidget {
  const _GraphView({
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
    final p = Palette.of(Theme.of(context).brightness);
    final graph = Graph();
    final nodes = {for (final n in data.nodes) n.id: n};
    for (final n in data.nodes) {
      graph.addNode(Node.Id(n.id));
    }
    for (final e in data.edges) {
      if (nodes.containsKey(e.source) && nodes.containsKey(e.target)) {
        graph.addEdge(
          graph.getNodeUsingId(e.source),
          graph.getNodeUsingId(e.target),
        );
      }
    }
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            label: l.memoryGraphDescription,
            child: InteractiveViewer(
              key: const Key('memory-graph'),
              constrained: false,
              boundaryMargin: const EdgeInsets.all(400),
              minScale: 0.2,
              maxScale: 3,
              child: GraphView(
                graph: graph,
                algorithm: FruchtermanReingoldAlgorithm(
                  FruchtermanReingoldConfiguration(iterations: 300),
                ),
                paint: Paint()
                  ..color = p.border
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (node) {
                  final n = nodes[node.key!.value]!;
                  final on = n.id == selected;
                  return InkWell(
                    key: Key('graph-node-${n.id}'),
                    onTap: () => onTap(n.id),
                    borderRadius: BorderRadius.circular(Radii.control),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.s8,
                        vertical: Space.s4,
                      ),
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border.all(
                          color: on ? p.text : p.border,
                          width: on ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            nodeIcon(n.displayType),
                            size: 14,
                            color: p.muted,
                          ),
                          const SizedBox(width: Space.s4),
                          Flexible(
                            child: Text(
                              n.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.label,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Positioned(
          left: Space.s16,
          bottom: Space.s16,
          child: _Legend(
            hasEntities: data.nodes.any((node) => node.displayType == 'entity'),
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
    final p = Palette.of(Theme.of(context).brightness);
    return ListView.builder(
      key: const Key('memory-list'),
      padding: const EdgeInsets.all(Space.s8),
      itemCount: data.nodes.length,
      itemBuilder: (_, i) {
        final n = data.nodes[i];
        return ListTile(
          key: Key('list-node-${n.id}'),
          dense: true,
          selected: n.id == selected,
          selectedTileColor: p.accent.withValues(alpha: 0.12),
          leading: Icon(nodeIcon(n.displayType), size: 18, color: p.muted),
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
        );
      },
    );
  }
}
