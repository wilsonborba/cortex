import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/browser_history_guard.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../dal/remote/cortex_api_adapter.dart';
import '../../../../domain/models/attachment.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_theme.dart';
import '../chat_screen/chat_screen.dart';
import 'memory_graph_layout.dart';
import 'memory_graph_node_widget.dart';
import 'memory_graph_painter.dart';

/// 2D interactive canvas of the caller's memory graph (Figma/Whimsical
/// style pan+zoom): fetches `GET /memory-graph`, lays it out client-side
/// with a small force-directed algorithm (see `computeForceDirectedLayout`),
/// then renders edges via a [CustomPainter] with node widgets stacked on
/// top, panned/zoomed through Flutter's own [InteractiveViewer] (drag to
/// pan, scroll wheel or pinch to zoom, no new package needed for either).
///
/// Tapping a memory/attachment/tag/entity/resource node fetches its context
/// (`GET /memory-graph/nodes/{id}/context`) and, if available, seeds a
/// brand-new draft [ChatScreen] conversation with it as a pending
/// attachment, so the user can ask a question grounded in that node without
/// the composer auto-sending anything. A `cluster` node (one conversation's
/// worth of memories/attachments, collapsed into a single card) has no
/// single memory's content to seed a conversation from, so tapping it
/// instead toggles that cluster's collapsed/expanded state (see
/// `_toggleCluster`).
///
/// Every node card is independently draggable (see `_onNodeDragUpdate`),
/// and cluster cards start collapsed by default: a first-time graph can
/// easily have dozens of individual memory/attachment cards, and hiding
/// them behind their conversation's cluster card until the user asks to see
/// them keeps the initial view legible (product call, see product owner
/// feedback). The "Reset positions" app bar action restores both the
/// original computed layout *and* this default collapsed state, since it is
/// meant to fully undo any manual rearranging back to the space-efficient
/// view the screen opens with (see `_resetLayout`).
class MemoryGraphScreen extends StatefulWidget {
  const MemoryGraphScreen({super.key, CortexApiAdapter? adapter}) : _adapter = adapter;

  final CortexApiAdapter? _adapter;

  @override
  State<MemoryGraphScreen> createState() => _MemoryGraphScreenState();
}

class _MemoryGraphScreenState extends State<MemoryGraphScreen> {
  late final CortexApiAdapter _adapter = widget._adapter ?? CortexApiAdapter();
  final _transformController = TransformationController();

  bool _loading = true;
  MemoryGraph _graph = MemoryGraph.empty;
  GraphLayout _layout = const GraphLayout(positions: [], canvasSize: math.Point(0, 0));
  String? _loadingNodeId;
  late final BrowserHistoryGuard _historyGuard;

  /// Ids of `cluster` nodes currently collapsed (their members hidden).
  /// Defaults to every cluster the graph has (see `_defaultCollapsedClusterIds`).
  Set<String> _collapsedClusterIds = {};

  /// Id of the node currently being dragged, if any. Also used to disable
  /// [InteractiveViewer]'s own pan gesture while a node drag is in progress,
  /// so the two gestures never fight over the same pointer (see
  /// `_buildCanvas`).
  String? _draggingNodeId;

  /// All cluster nodes start collapsed (see the class doc for why).
  Set<String> _defaultCollapsedClusterIds(MemoryGraph graph) {
    return {
      for (final node in graph.nodes)
        if (node.nodeType == MemoryGraphNodeType.cluster && node.clusterOf.isNotEmpty) node.id,
    };
  }

  @override
  void initState() {
    super.initState();
    // Web only (no-op elsewhere): this screen is reached via a plain
    // `Navigator.push`, which never touches the browser's own history
    // stack, so without this the browser's back button would navigate away
    // from the app entirely to whatever real page came before it, instead
    // of just closing this screen back to chat.
    _historyGuard = armBrowserHistoryGuard(
      onBack: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
    _load();
  }

  Future<void> _load() async {
    final graph = await _adapter.fetchMemoryGraph();
    if (!mounted) return;
    final resolved = graph ?? MemoryGraph.empty;
    setState(() {
      _graph = resolved;
      _layout = computeForceDirectedLayout(resolved);
      _collapsedClusterIds = _defaultCollapsedClusterIds(resolved);
      _loading = false;
    });
  }

  /// "Reset positions" app bar action: recomputes the original
  /// force-directed layout (undoing any manual dragging) and also restores
  /// the default collapsed state for every cluster, so the button returns
  /// the whole canvas to exactly what a fresh load would show rather than
  /// leaving stale manual expand/collapse choices mixed with fresh
  /// positions.
  void _resetLayout() {
    setState(() {
      _layout = computeForceDirectedLayout(_graph);
      _collapsedClusterIds = _defaultCollapsedClusterIds(_graph);
    });
  }

  void _toggleCluster(MemoryGraphNode node) {
    setState(() {
      if (!_collapsedClusterIds.remove(node.id)) {
        _collapsedClusterIds.add(node.id);
      }
    });
  }

  /// Ids of every node hidden because it belongs to a currently-collapsed
  /// cluster. Per the backend's data model, a memory/attachment belongs to
  /// at most one conversation cluster, so a node hidden by one collapsed
  /// cluster is simply hidden - no need to reconcile multiple clusters
  /// disagreeing about the same node.
  Set<String> _hiddenNodeIds() {
    final hidden = <String>{};
    for (final node in _graph.nodes) {
      if (node.nodeType == MemoryGraphNodeType.cluster && _collapsedClusterIds.contains(node.id)) {
        hidden.addAll(node.clusterOf);
      }
    }
    return hidden;
  }

  void _onNodeDragUpdate(PositionedGraphNode positioned, Offset localDelta) {
    setState(() {
      positioned.position = clampToCanvas(positioned.position + localDelta, _layout.canvasSize);
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = event.scrollDelta.dy;
    final scaleFactor = delta > 0 ? 0.92 : 1.08;
    final matrix = _transformController.value.clone();
    final localPosition = event.localPosition;
    // Zoom about the cursor position, not the canvas origin.
    matrix
      ..translateByDouble(localPosition.dx, localPosition.dy, 0, 1)
      ..scaleByDouble(scaleFactor, scaleFactor, scaleFactor, 1)
      ..translateByDouble(-localPosition.dx, -localPosition.dy, 0, 1);
    final newScale = matrix.getMaxScaleOnAxis();
    if (newScale < 0.15 || newScale > 4) return;
    _transformController.value = matrix;
  }

  Future<void> _onNodeTap(MemoryGraphNode node) async {
    // Cluster taps are routed to `_toggleCluster` instead (see the switch in
    // `_buildCanvas`); this guard is just defense in depth so a future
    // wiring mistake can't seed a conversation from a cluster, which has no
    // single memory's content to seed from.
    if (node.nodeType == MemoryGraphNodeType.cluster) {
      _toggleCluster(node);
      return;
    }
    if (_loadingNodeId != null) return;
    setState(() => _loadingNodeId = node.id);
    final nodeContext = await _adapter.fetchNodeContext(node.id);
    if (!mounted) return;
    setState(() => _loadingNodeId = null);

    final available = nodeContext?['available'] as bool? ?? (nodeContext != null);
    final content = nodeContext?['content'] as String?;
    if (nodeContext == null || !available || content == null || content.isEmpty) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.memoryGraphNoContextAvailable)),
      );
      return;
    }

    final title = nodeContext['title'] as String? ?? node.label;
    final attachment = ChatAttachment(
      id: 'memory-graph-${node.id}',
      filename: '$title.txt',
      mimeType: 'text/plain',
      bytes: utf8.encode(content),
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(initialAttachment: attachment)),
    );
  }

  @override
  void dispose() {
    _historyGuard.disarm();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    // Desktop relies on the browser's own back/forward buttons for
    // navigation (product feedback), so no in-app back arrow there; mobile
    // has no browser chrome, so it keeps Flutter's default auto-generated one.
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.memoryGraphTitle),
        automaticallyImplyLeading: isMobile,
        actions: [
          IconButton(
            tooltip: l10n.memoryGraphResetPositionsTooltip,
            icon: const Icon(Icons.restart_alt_rounded, size: 20),
            onPressed: _loading || _graph.nodes.isEmpty ? null : _resetLayout,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _graph.nodes.isEmpty
                ? _EmptyState(l10n: l10n)
                : _buildCanvas(scheme),
          ),
          if (!_loading && _graph.truncated)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _TruncatedBanner(text: l10n.memoryGraphTruncatedNotice),
            ),
        ],
      ),
    );
  }

  Widget _buildCanvas(ColorScheme scheme) {
    final width = _layout.canvasSize.x;
    final height = _layout.canvasSize.y;
    final hiddenIds = _hiddenNodeIds();
    final visiblePositions = [
      for (final p in _layout.positions)
        if (!hiddenIds.contains(p.node.id)) p,
    ];
    // Edges touching a hidden (collapsed-away) node are simply left out of
    // `positionById`, which `MemoryGraphEdgePainter` already treats as "skip
    // this edge" (see its `from == null || to == null` guard), so no
    // separate edge-filtering pass is needed.
    final positionById = {
      for (final p in visiblePositions) p.node.id: p.position,
    };

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: InteractiveViewer(
        transformationController: _transformController,
        constrained: false,
        minScale: 0.15,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(400),
        // Disabled while a node is being dragged so the pan gesture and the
        // node-drag gesture never compete for the same pointer in the
        // gesture arena (see `_onNodeDragUpdate`/the `Listener` below).
        panEnabled: _draggingNodeId == null,
        child: SizedBox(
          width: width,
          height: height,
          // `Clip.none`: the layout already reserves a margin (see
          // `computeForceDirectedLayout`) so no card sits near the canvas
          // edge, this is just an extra safety net against the Stack's
          // default hard clip cutting a card in half (the prior reported bug).
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: MemoryGraphEdgePainter(
                    edges: _graph.edges,
                    positionById: positionById,
                    lineColor: scheme.outline.withValues(alpha: 0.6),
                  ),
                ),
              ),
              for (final p in visiblePositions)
                // Center each card on its node's position using that exact
                // type's own known footprint (single source of truth:
                // `MemoryGraphNodeStyle.sizeForType`), never a fixed guessed
                // offset.
                Positioned(
                  left: p.position.dx - MemoryGraphNodeStyle.sizeForType(p.node.nodeType).width / 2,
                  top: p.position.dy - MemoryGraphNodeStyle.sizeForType(p.node.nodeType).height / 2,
                  // A raw `Listener`, not a `GestureDetector`/`Draggable`:
                  // pointer callbacks on a `Listener` fire unconditionally
                  // (it never enters the gesture arena), so this drag never
                  // fights `InteractiveViewer`'s own pan recognizer for the
                  // same pointer - we just disable that recognizer for the
                  // duration via `panEnabled` above. This also makes
                  // dragging lag-free: position updates directly from raw
                  // pointer deltas, no recognizer resolution delay.
                  child: Listener(
                    onPointerDown: (_) => setState(() => _draggingNodeId = p.node.id),
                    onPointerMove: (event) {
                      if (_draggingNodeId != p.node.id) return;
                      _onNodeDragUpdate(p, event.localDelta);
                    },
                    onPointerUp: (_) => setState(() => _draggingNodeId = null),
                    onPointerCancel: (_) => setState(() => _draggingNodeId = null),
                    child: MemoryGraphNodeWidget(
                      node: p.node,
                      clusterCollapsed: _collapsedClusterIds.contains(p.node.id),
                      onTap: () => _onNodeTap(p.node),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Small, scoped empty-state card, never a full-screen replacement
    // widget (prior product correction on record).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_outlined, size: 28, color: scheme.onSurface.withValues(alpha: 0.6)),
              const SizedBox(height: 10),
              Text(
                l10n.memoryGraphEmptyTitle,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.memoryGraphEmptyBody,
                style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.65)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruncatedBanner extends StatelessWidget {
  const _TruncatedBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: AppTheme.glassDecoration(context, radius: AppTheme.controlRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: scheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.75)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
