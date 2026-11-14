import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../domain/services/memory_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';
import '../../widgets/common/states.dart';
import 'memory_card.dart';
import 'graph_canvas.dart';

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
  final canvas = GlobalKey<GraphCanvasState>();
  final expanded = <String>{};
  String query = '';
  @override
  void initState() {
    super.initState();
    memory.addListener(_changed);
    _refresh(true);
  }

  @override
  void didUpdateWidget(MemoryScreen old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      memory.addListener(_changed);
    }
    if (old.controller != widget.controller || old.nodeId != widget.nodeId) {
      _refresh(old.controller != widget.controller);
    }
  }

  void _refresh(bool fresh) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if ((fresh || memory.graph == null) && !memory.loading) memory.load();
      memory.open(widget.nodeId);
    });
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    memory.removeListener(_changed);
    super.dispose();
  }

  void _go(String id) =>
      GoRouter.maybeOf(context)?.go('/v1/memory/${Uri.encodeComponent(id)}');
  void _expand(String id) => setState(() => expanded.add(id));
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = Palette.from(context),
        graph = memory.graph;
    var scene = graph == null ? null : GraphScene(graph, expanded);
    if (scene != null && widget.nodeId != null) {
      for (final entry in scene.stacks.entries) {
        if (entry.value.any((node) => node.id == widget.nodeId)) {
          expanded.add(entry.key);
        }
      }
      scene = GraphScene(graph!, expanded);
    }
    final Widget body;
    if (graph == null) {
      body = memory.error == null
          ? const Center(child: SkeletonBox(width: Space.chatColumnWidth))
          : ErrorState(
              message: apiFailure(l, memory.error),
              retryLabel: l.retry,
              onRetry: memory.load,
            );
    } else if (graph.nodes.isEmpty) {
      body = EmptyState(title: l.noMemories, icon: AppIcons.memory);
    } else {
      body = IndexedStack(
        index: memory.view == MemoryView.graph ? 0 : 1,
        children: [
          GraphCanvas(
            key: canvas,
            data: graph,
            selected: widget.nodeId,
            onSelect: _go,
            query: query,
            expanded: expanded,
            onExpand: _expand,
          ),
          _NodeList(
            scene: scene!,
            selected: widget.nodeId,
            onTap: _go,
            onExpand: _expand,
            query: query,
          ),
        ],
      );
    }
    Widget? card;
    if (widget.nodeId != null) {
      final missing =
          graph != null && !graph.nodes.any((n) => n.id == widget.nodeId);
      card = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (missing) NoticeLine(message: l.graphMissingNode),
          if (memory.nodeLoading)
            const SkeletonBox(width: Space.chatColumnWidth)
          else if (memory.nodeError != null)
            ErrorState(
              message: apiFailure(l, memory.nodeError),
              retryLabel: l.retry,
              onRetry: () => memory.open(widget.nodeId),
            )
          else if (memory.node?.node != null)
            MemoryCard(data: memory.node!, onOpen: _go, now: widget.now)
          else if (!missing)
            Text(l.memoryNotFound, style: TextStyles.compact),
        ],
      );
    }
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
                    icon: const Icon(AppIcons.memory),
                  ),
                  ButtonSegment(
                    value: MemoryView.list,
                    label: Text(l.listView),
                    icon: const Icon(AppIcons.list),
                  ),
                ],
                selected: {memory.view},
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
              if (memory.loading)
                const Icon(AppIcons.loading, size: IconSizes.action),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.s8),
          child: TextField(
            key: const Key('graph-search'),
            decoration: InputDecoration(
              hintText: l.graphSearch,
              prefixIcon: const Icon(AppIcons.search, size: IconSizes.action),
            ),
            onChanged: (value) => setState(() => query = value),
            onSubmitted: (_) => canvas.currentState?.centerFirstMatch(),
          ),
        ),
        if (graph?.truncated == true)
          Padding(
            padding: const EdgeInsets.all(Space.s8),
            child: NoticeLine(
              key: const Key('truncated'),
              message: l.graphTruncated,
            ),
          ),
        if (graph != null && memory.error != null)
          Padding(
            padding: const EdgeInsets.all(Space.s8),
            child: Row(
              children: [
                Expanded(
                  child: NoticeLine(message: apiFailure(l, memory.error)),
                ),
                TextButton(onPressed: memory.load, child: Text(l.retry)),
              ],
            ),
          ),
        if (graph != null && graph.nodes.isNotEmpty && graph.edges.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.s8),
            child: NoticeLine(message: l.graphNoLinks),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final compact = SizeClass.of(box.maxWidth) != SizeClass.expanded;
              final pane = card == null
                  ? null
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(Space.s16),
                      child: card,
                    );
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: body),
                      if (!compact && pane != null)
                        Container(
                          width: GraphTokens.detailWidth,
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: p.border)),
                          ),
                          child: pane,
                        ),
                    ],
                  ),
                  if (compact && pane != null)
                    Positioned.fill(
                      child: Material(
                        color: p.background,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton.icon(
                                onPressed: () =>
                                    GoRouter.maybeOf(context)?.go('/v1/memory'),
                                icon: const Icon(
                                  AppIcons.back,
                                  size: IconSizes.action,
                                ),
                                label: Text(l.graphBack),
                              ),
                            ),
                            Expanded(child: pane),
                          ],
                        ),
                      ),
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

class _NodeList extends StatelessWidget {
  const _NodeList({
    required this.scene,
    required this.selected,
    required this.onTap,
    required this.onExpand,
    required this.query,
  });
  final GraphScene scene;
  final String? selected;
  final ValueChanged<String> onTap, onExpand;
  final String query;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = Palette.from(context),
        used = <String>{};
    final ordered = <GraphNode>[];
    for (final chat in scene.nodes.where((n) => n.type == 'chat')) {
      ordered.add(chat);
      used.add(chat.id);
      for (final n in scene.nodes) {
        if ((scene.neighbors[chat.id]?.contains(n.id) ?? false) &&
            used.add(n.id)) {
          ordered.add(n);
        }
      }
    }
    ordered.addAll(scene.nodes.where((n) => !used.contains(n.id)));
    final nodes = ordered
        .where((n) => n.label.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      key: const Key('memory-list'),
      padding: const EdgeInsets.all(Space.s8),
      itemCount: nodes.length,
      itemBuilder: (context, i) {
        final n = nodes[i],
            date = DateTime.tryParse(
              '${nodes[i].metadata['created_at']}',
            )?.toLocal(),
            count = scene.stacks[n.id]?.length;
        return FoundationFocus(
          child: ListTile(
            key: Key('list-node-${n.id}'),
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
              style: TextStyles.compact,
            ),
            subtitle: Text(
              [
                nodeTypeName(l, n.displayType),
                if (date != null)
                  MaterialLocalizations.of(context).formatShortDate(date),
              ].join(' · '),
              style: TextStyles.label.copyWith(color: p.muted),
            ),
            trailing: count == null
                ? null
                : Text('$count', style: TextStyles.label),
            onTap: () => count == null ? onTap(n.id) : onExpand(n.id),
          ),
        );
      },
    );
  }
}
