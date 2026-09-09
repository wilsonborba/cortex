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
/// Tapping a node fetches its context (`GET
/// /memory-graph/nodes/{id}/context`) and, if available, seeds a brand-new
/// draft [ChatScreen] conversation with it as a pending attachment, so the
/// user can ask a question grounded in that memory/tag/entity/resource
/// without the composer auto-sending anything.
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
      _loading = false;
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
    final positionById = {
      for (final p in _layout.positions) p.node.id: p.position,
    };

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: InteractiveViewer(
        transformationController: _transformController,
        constrained: false,
        minScale: 0.15,
        maxScale: 4,
        boundaryMargin: const EdgeInsets.all(400),
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
              for (final p in _layout.positions)
                // Center each card on its node's position using that exact
                // type's own known footprint (single source of truth:
                // `MemoryGraphNodeStyle.sizeForType`), never a fixed guessed
                // offset.
                Positioned(
                  left: p.position.dx - MemoryGraphNodeStyle.sizeForType(p.node.nodeType).width / 2,
                  top: p.position.dy - MemoryGraphNodeStyle.sizeForType(p.node.nodeType).height / 2,
                  child: MemoryGraphNodeWidget(
                    node: p.node,
                    onTap: () => _onNodeTap(p.node),
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
