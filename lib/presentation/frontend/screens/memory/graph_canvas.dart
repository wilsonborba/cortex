import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';

/// Values approved in #55. Visual spacing uses the shared foundation scale.
abstract final class GraphTokens {
  static const ticks = 300, labelCharacters = 24;
  static const seedRadius = 10.0, linkDistance = 60.0, repulsion = 120.0;
  static const velocityDecay = .4, collisionPadding = 12.0;
  static const minRadius = 6.0, degreeRadius = 2.0, maxRadius = 18.0;
  // 0.25 clipped the 200-node fit at 390 px; see the #55 review note.
  static const minScale = .2, maxScale = 3.0, fitMaxScale = 1.5;
  static const fitFraction = .9, labelScale = .8, dimOpacity = .25;
  static const zoomStep = 1.25;
  static const hitRadius = 16.0, detailWidth = 360.0, wheelDivisor = 180.0;
  static const exampleRatio = .45, exampleMinHeight = 260.0;
}

/// Collapsing is a view operation. It never adds an edge to the API graph.
class GraphScene {
  GraphScene(this.data, [Set<String> expanded = const {}]) {
    final chatFor = <String, String>{};
    final types = {for (final n in data.nodes) n.id: n.type};
    for (final e in data.edges) {
      if (types[e.source] == 'memory' && types[e.target] == 'chat') {
        chatFor.putIfAbsent(e.source, () => e.target);
      } else if (types[e.target] == 'memory' && types[e.source] == 'chat') {
        chatFor.putIfAbsent(e.target, () => e.source);
      }
    }
    final groups = <(String, String), List<GraphNode>>{};
    for (final n in data.nodes) {
      final chat = chatFor[n.id];
      if (chat != null) groups.putIfAbsent((chat, n.label), () => []).add(n);
    }
    final aliases = <String, String>{};
    for (final group in groups.values) {
      if (group.length < 2 || expanded.contains(group.first.id)) continue;
      stacks[group.first.id] = group;
      for (final n in group.skip(1)) {
        aliases[n.id] = group.first.id;
      }
    }
    nodes = data.nodes.where((n) => !aliases.containsKey(n.id)).toList();
    final unique = <(String, String, String)>{};
    edges = [
      for (final e in data.edges)
        if (unique.add((
          aliases[e.source] ?? e.source,
          aliases[e.target] ?? e.target,
          e.type,
        )))
          GraphEdge(
            aliases[e.source] ?? e.source,
            aliases[e.target] ?? e.target,
            e.type,
          ),
    ];
    for (final e in edges) {
      neighbors.putIfAbsent(e.source, () => {}).add(e.target);
      neighbors.putIfAbsent(e.target, () => {}).add(e.source);
    }
  }
  final MemoryGraphData data;
  late final List<GraphNode> nodes;
  late final List<GraphEdge> edges;
  final stacks = <String, List<GraphNode>>{};
  final neighbors = <String, Set<String>>{};
  int degree(String id) => neighbors[id]?.length ?? 0;
  double radius(String id) => math.min(
    GraphTokens.maxRadius,
    GraphTokens.minRadius + GraphTokens.degreeRadius * math.sqrt(degree(id)),
  );
}

/// Static d3-force method: phyllotaxis, links, pair repulsion, center, collide.
/// No timer runs after data loading. The arrays avoid allocations in pair loops.
Map<String, Offset> graphPositions(MemoryGraphData data) {
  final count = data.nodes.length;
  if (count == 0) return {};
  final indices = {for (final (i, n) in data.nodes.indexed) n.id: i};
  final edges = [
    for (final e in data.edges)
      if (indices.containsKey(e.source) && indices.containsKey(e.target))
        (indices[e.source]!, indices[e.target]!),
  ];
  final degree = List<int>.filled(count, 0);
  for (final (a, b) in edges) {
    degree[a]++;
    degree[b]++;
  }
  final x = Float64List(count), y = Float64List(count);
  final vx = Float64List(count), vy = Float64List(count);
  final radius = Float64List(count);
  for (var i = 0; i < count; i++) {
    final r = GraphTokens.seedRadius * math.sqrt(.5 + i);
    final angle = i * math.pi * (3 - math.sqrt(5));
    x[i] = r * math.cos(angle);
    y[i] = r * math.sin(angle);
    radius[i] =
        math.min(
          GraphTokens.maxRadius,
          GraphTokens.minRadius +
              GraphTokens.degreeRadius * math.sqrt(degree[i]),
        ) +
        GraphTokens.collisionPadding;
  }
  final decay = 1 - math.pow(.001, 1 / GraphTokens.ticks);
  var alpha = 1.0;
  for (var tick = 0; tick < GraphTokens.ticks; tick++) {
    alpha += -alpha * decay;
    for (final (a, b) in edges) {
      var dx = x[b] + vx[b] - x[a] - vx[a], dy = y[b] + vy[b] - y[a] - vy[a];
      final distance = math.max(.001, math.sqrt(dx * dx + dy * dy));
      final force =
          (distance - GraphTokens.linkDistance) /
          distance *
          alpha /
          math.min(degree[a], degree[b]);
      dx *= force;
      dy *= force;
      final bias = degree[a] / (degree[a] + degree[b]);
      vx[b] -= dx * bias;
      vy[b] -= dy * bias;
      vx[a] += dx * (1 - bias);
      vy[a] += dy * (1 - bias);
    }
    for (var a = 0; a < count; a++) {
      if (degree[a] == 0) continue;
      for (var b = a + 1; b < count; b++) {
        if (degree[b] == 0) continue;
        final dx = x[b] - x[a], dy = y[b] - y[a];
        final square = math.max(1.0, dx * dx + dy * dy);
        final force = GraphTokens.repulsion * alpha / square;
        vx[a] -= dx * force;
        vy[a] -= dy * force;
        vx[b] += dx * force;
        vy[b] += dy * force;
        final distance = math.sqrt(square),
            overlap = radius[a] + radius[b] - distance;
        if (overlap > 0) {
          final push = overlap / distance * .5;
          vx[a] -= dx * push;
          vy[a] -= dy * push;
          vx[b] += dx * push;
          vy[b] += dy * push;
        }
      }
    }
    var meanX = 0.0, meanY = 0.0, linked = 0;
    for (var i = 0; i < count; i++) {
      if (degree[i] == 0) continue;
      vx[i] *= 1 - GraphTokens.velocityDecay;
      vy[i] *= 1 - GraphTokens.velocityDecay;
      x[i] += vx[i];
      y[i] += vy[i];
      meanX += x[i];
      meanY += y[i];
      linked++;
    }
    if (linked > 0) {
      meanX /= linked;
      meanY /= linked;
      for (var i = 0; i < count; i++) {
        if (degree[i] > 0) {
          x[i] -= meanX;
          y[i] -= meanY;
        }
      }
    }
  }
  final columns = math.sqrt(degree.where((d) => d == 0).length).ceil();
  final linkedBottom = [
    for (var i = 0; i < count; i++)
      if (degree[i] > 0) y[i],
  ].fold(0.0, math.max);
  var loose = 0;
  for (var i = 0; i < count; i++) {
    if (degree[i] != 0) continue;
    // Grid cells leave room for a 24-character label and its local date.
    x[i] = (loose % columns - (columns - 1) / 2) * Space.s48 * 2;
    y[i] = linkedBottom + Space.s48 * 2 * (2 + loose ~/ columns);
    loose++;
  }
  return {for (var i = 0; i < count; i++) data.nodes[i].id: Offset(x[i], y[i])};
}

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({
    super.key,
    required this.data,
    required this.onSelect,
    this.selected,
    this.showControls = true,
    this.query = '',
    this.onExpand,
    this.expanded = const {},
  });
  final MemoryGraphData data;
  final bool showControls;
  final ValueChanged<String> onSelect;
  final String? selected;
  final String query;
  final ValueChanged<String>? onExpand;
  final Set<String> expanded;
  @override
  State<GraphCanvas> createState() => GraphCanvasState();
}

class GraphCanvasState extends State<GraphCanvas> {
  final transform = TransformationController();
  final focus = FocusNode();
  late Map<String, Offset> positions;
  late GraphScene scene;
  final labels = <String, TextPainter>{}, dates = <String, TextPainter>{};
  String? hover, keyboard, dragging;
  Size viewport = Size.zero;
  Rect bounds = Rect.zero;

  bool _fitted = false, _normalized = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    positions = graphPositions(widget.data);
    scene = GraphScene(widget.data, widget.expanded);
    _fitted = false;
    _normalized = false;
  }

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) &&
        !_sameTopology(oldWidget.data, widget.data)) {
      _load();
    } else {
      scene = GraphScene(widget.data, widget.expanded);
    }
  }

  bool _sameTopology(MemoryGraphData a, MemoryGraphData b) =>
      a.nodes.length == b.nodes.length &&
      a.edges.length == b.edges.length &&
      a.nodes.indexed.every((e) => e.$2.id == b.nodes[e.$1].id) &&
      a.edges.indexed.every(
        (e) =>
            e.$2.source == b.edges[e.$1].source &&
            e.$2.target == b.edges[e.$1].target &&
            e.$2.type == b.edges[e.$1].type,
      );
  @override
  void dispose() {
    transform.dispose();
    focus.dispose();
    super.dispose();
  }

  double _fitScale(Rect b) =>
      (math.min(viewport.width / b.width, viewport.height / b.height) *
              GraphTokens.fitFraction)
          .clamp(GraphTokens.minScale, GraphTokens.fitMaxScale);

  void fit() {
    if (viewport.isEmpty || bounds.isEmpty) return;
    final b = bounds, scale = _fitScale(bounds);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        (viewport.width - b.width * scale) / 2 - b.left * scale,
        (viewport.height - b.height * scale) / 2 - b.top * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  void centerFirstMatch() {
    final n = scene.nodes
        .where(
          (n) => n.label.toLowerCase().contains(widget.query.toLowerCase()),
        )
        .firstOrNull;
    if (n == null) return;
    final point = positions[n.id]!, scale = transform.value.getMaxScaleOnAxis();
    transform.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - point.dx * scale,
        viewport.height / 2 - point.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
    setState(() => keyboard = n.id);
  }

  void zoom(double factor, [Offset? anchor]) {
    final old = transform.value.getMaxScaleOnAxis();
    final scale = (old * factor).clamp(
      GraphTokens.minScale,
      GraphTokens.maxScale,
    );
    final point = anchor ?? viewport.center(Offset.zero),
        before = transform.toScene(point);
    transform.value = Matrix4.identity()
      ..translateByDouble(
        point.dx - before.dx * scale,
        point.dy - before.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  String? _hit(Offset point) {
    final scale = transform.value.getMaxScaleOnAxis(),
        local = transform.toScene(point);
    String? nearest;
    var distance = GraphTokens.hitRadius;
    for (final n in scene.nodes) {
      final d = (positions[n.id]! - local).distance * scale;
      if (d <= distance) {
        nearest = n.id;
        distance = d;
      }
    }
    return nearest;
  }

  void _select(String id) {
    if (scene.stacks.containsKey(id) && widget.onExpand != null) {
      widget.onExpand!(id);
      return;
    }
    widget.onSelect(id);
  }

  KeyEventResult _key(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.tab) {
      final index = scene.nodes.indexWhere((n) => n.id == keyboard);
      final next = index + (HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
      if (next < 0 || next >= scene.nodes.length) return KeyEventResult.ignored;
      setState(() => keyboard = scene.nodes[next].id);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter && keyboard != null) {
      _select(keyboard!);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add) {
      zoom(GraphTokens.zoomStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      zoom(1 / GraphTokens.zoomStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit0) {
      fit();
      return KeyEventResult.handled;
    }
    final delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => const Offset(Space.s24, 0),
      LogicalKeyboardKey.arrowRight => const Offset(-Space.s24, 0),
      LogicalKeyboardKey.arrowUp => const Offset(0, Space.s24),
      LogicalKeyboardKey.arrowDown => const Offset(0, -Space.s24),
      _ => null,
    };
    if (delta != null) {
      final matrix = transform.value.clone();
      matrix.setTranslationRaw(
        matrix.storage[12] + delta.dx,
        matrix.storage[13] + delta.dy,
        0,
      );
      transform.value = matrix;
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _measure(BuildContext context) {
    final p = Palette.from(context);
    labels.clear();
    dates.clear();
    Rect? content;
    final locale = Localizations.localeOf(context);
    for (final n in scene.nodes) {
      final chars = n.label.characters;
      final text = chars.length > GraphTokens.labelCharacters
          ? '${chars.take(GraphTokens.labelCharacters - 1).toString()}…'
          : n.label;
      TextPainter measure(String text, Color color) => TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyles.caption1.copyWith(color: color),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final label = measure(text, p.text);
      labels[n.id] = label;
      final date = DateTime.tryParse('${n.metadata['created_at']}')?.toLocal();
      if (n.type == 'memory' && date != null) {
        dates[n.id] = measure(
          MaterialLocalizations.of(context).formatShortDate(date),
          p.muted,
        );
      }
      final width = math.max(label.width, dates[n.id]?.width ?? 0),
          r = scene.radius(n.id);
      final point = positions[n.id]!;
      final rect = Rect.fromLTRB(
        point.dx - math.max(r, width / 2),
        point.dy - r,
        point.dx + math.max(r, width / 2),
        point.dy + r + Space.s4 + label.height + (dates[n.id]?.height ?? 0),
      );
      content = content?.expandToInclude(rect) ?? rect;
    }
    bounds = content ?? Rect.zero;
    if (!_normalized && !bounds.isEmpty) {
      final offset = -bounds.topLeft + const Offset(Space.s24, Space.s24);
      positions = {
        for (final entry in positions.entries) entry.key: entry.value + offset,
      };
      bounds = bounds.shift(offset);
      _normalized = true;
    }
    // Depend on locale even when no date exists. Text styles and scale are measured each build.
    assert(locale.languageCode.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = Palette.from(context);
    _measure(context);
    return Column(
      children: [
        if (widget.showControls)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(Space.s8),
              child: Material(
                color: p.raised,
                borderRadius: BorderRadius.circular(
                  FoundationTokens.of(context).controlRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l.graphZoomIn,
                      onPressed: () => zoom(GraphTokens.zoomStep),
                      icon: const Icon(AppIcons.zoomIn, size: IconSizes.action),
                    ),
                    IconButton(
                      tooltip: l.graphZoomOut,
                      onPressed: () => zoom(1 / GraphTokens.zoomStep),
                      icon: const Icon(
                        AppIcons.zoomOut,
                        size: IconSizes.action,
                      ),
                    ),
                    IconButton(
                      tooltip: l.graphFit,
                      onPressed: fit,
                      icon: const Icon(AppIcons.fit, size: IconSizes.action),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              viewport = box.biggest;
              if (!_fitted) {
                _fitted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) fit();
                });
              }
              return Stack(
                children: [
                  Positioned.fill(
                    child: FoundationFocus(
                      child: Focus(
                        focusNode: focus,
                        onKeyEvent: _key,
                        child: MouseRegion(
                          cursor: hover == null
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          onHover: (e) {
                            final id = _hit(e.localPosition);
                            if (id != hover) setState(() => hover = id);
                          },
                          onExit: (_) => setState(() => hover = null),
                          child: Listener(
                            onPointerDown: (e) {
                              focus.requestFocus();
                              setState(() => dragging = _hit(e.localPosition));
                            },
                            onPointerMove: (e) {
                              if (dragging != null) {
                                setState(
                                  () => positions[dragging!] =
                                      positions[dragging!]! +
                                      e.delta /
                                          transform.value.getMaxScaleOnAxis(),
                                );
                              }
                            },
                            onPointerUp: (_) => setState(() => dragging = null),
                            onPointerCancel: (_) =>
                                setState(() => dragging = null),
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent) {
                                GestureBinding.instance.pointerSignalResolver
                                    .register(event, (e) {
                                      zoom(
                                        math.exp(
                                          -event.scrollDelta.dy /
                                              GraphTokens.wheelDivisor,
                                        ),
                                        event.localPosition,
                                      );
                                    });
                              }
                            },
                            child: GestureDetector(
                              onTapUp: (e) {
                                final id = _hit(e.localPosition);
                                if (id != null) _select(id);
                              },
                              child: InteractiveViewer(
                                key: const Key('memory-graph'),
                                transformationController: transform,
                                constrained: false,
                                panEnabled: dragging == null,
                                scaleEnabled: dragging == null,
                                minScale: GraphTokens.minScale,
                                maxScale: GraphTokens.maxScale,
                                boundaryMargin: EdgeInsets.symmetric(
                                  horizontal: viewport.width / 2,
                                  vertical: viewport.height / 2,
                                ),
                                child: AnimatedBuilder(
                                  animation: transform,
                                  builder: (context, _) => RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size(
                                        math.max(
                                          viewport.width,
                                          bounds.right + Space.s24,
                                        ),
                                        math.max(
                                          viewport.height,
                                          bounds.bottom + Space.s24,
                                        ),
                                      ),
                                      painter: _GraphPainter(
                                        scene: scene,
                                        positions: positions,
                                        labels: labels,
                                        dates: dates,
                                        palette: p,
                                        selected: widget.selected,
                                        hover: hover ?? keyboard,
                                        query: widget.query,
                                        scale: transform.value
                                            .getMaxScaleOnAxis(),
                                        onSelect: _select,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(Space.s8),
          child: GraphLegend(
            hasEntities: widget.data.nodes.any(
              (n) => n.displayType == 'entity',
            ),
          ),
        ),
      ],
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({
    required this.scene,
    required this.positions,
    required this.labels,
    required this.dates,
    required this.palette,
    required this.selected,
    required this.hover,
    required this.query,
    required this.scale,
    required this.onSelect,
  });
  final GraphScene scene;
  final Map<String, Offset> positions;
  final Map<String, TextPainter> labels, dates;
  final Palette palette;
  final String? selected, hover;
  final String query;
  final double scale;
  final ValueChanged<String> onSelect;
  bool _near(String id, String? focus) =>
      id == focus || (scene.neighbors[focus]?.contains(id) ?? false);
  double _opacity(GraphNode n) =>
      ((hover != null && !_near(n.id, hover)) ||
          (query.isNotEmpty &&
              !n.label.toLowerCase().contains(query.toLowerCase())))
      ? GraphTokens.dimOpacity
      : 1;
  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in scene.edges) {
      final active = edge.source == selected || edge.target == selected;
      final dim =
          hover != null &&
          !_near(edge.source, hover) &&
          !_near(edge.target, hover);
      canvas.drawLine(
        positions[edge.source]!,
        positions[edge.target]!,
        Paint()
          ..color = (active ? palette.text : palette.stroke).withValues(
            alpha: dim ? GraphTokens.dimOpacity : 1,
          )
          ..strokeWidth = Controls.border,
      );
    }
    final showLabels = <String>{}, occupied = <Rect>[];
    final priority = [
      ...scene.nodes.where((n) => n.id == selected || n.id == hover),
      ...scene.nodes.where((n) => n.id != selected && n.id != hover),
    ];
    for (final n in priority) {
      if (scale < GraphTokens.labelScale &&
          !_near(n.id, selected) &&
          !_near(n.id, hover)) {
        continue;
      }
      final label = labels[n.id]!,
          date = dates[n.id],
          point = positions[n.id]!,
          radius = scene.radius(n.id);
      final width = math.max(label.width, date?.width ?? 0);
      final rect = Rect.fromLTWH(
        point.dx - width / 2,
        point.dy + radius + Space.s4,
        width,
        label.height + (date?.height ?? 0),
      ).inflate(Space.s4);
      final focus = n.id == selected || n.id == hover;
      if (!focus &&
          (occupied.any((other) => other.overlaps(rect)) ||
              scene.nodes.any(
                (other) =>
                    other.id != n.id &&
                    Rect.fromCircle(
                      center: positions[other.id]!,
                      radius: scene.radius(other.id),
                    ).overlaps(rect),
              ))) {
        continue;
      }
      showLabels.add(n.id);
      occupied.add(rect);
    }
    for (final n in scene.nodes) {
      final pos = positions[n.id]!,
          r = scene.radius(n.id),
          opacity = _opacity(n);
      final fill = Paint()..color = palette.surface.withValues(alpha: opacity);
      canvas.drawCircle(pos, r, fill);
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = (n.id == selected ? palette.brandStroke1 : palette.muted)
              .withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = n.id == selected
              ? Controls.focusRing
              : Controls.border,
      );
      final icon = nodeIcon(n.displayType);
      final text = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: math.min(IconSizes.chip, r * GraphTokens.degreeRadius),
            color: palette.text.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, pos - Offset(text.width / 2, text.height / 2));
      final count = scene.stacks[n.id]?.length;
      if (count != null) {
        final badge = TextPainter(
          text: TextSpan(
            text: '$count',
            style: TextStyles.caption1.copyWith(color: palette.text),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final point = pos + Offset(r, -r);
        canvas.drawCircle(
          point,
          math.max(badge.width, badge.height) / 2 + Space.s4,
          fill,
        );
        badge.paint(canvas, point - Offset(badge.width / 2, badge.height / 2));
      }
    }
    // Text remains separate from the circles and never changes their positions.
    for (final n in scene.nodes) {
      final pos = positions[n.id]!,
          r = scene.radius(n.id),
          opacity = _opacity(n);
      if (showLabels.contains(n.id)) {
        final label = labels[n.id]!, date = dates[n.id];
        canvas.saveLayer(
          Rect.fromLTRB(
            pos.dx - label.width,
            pos.dy - r,
            pos.dx + label.width,
            pos.dy + r + Space.s4 + label.height + (date?.height ?? 0),
          ),
          // A layer paint uses only the alpha of the color.
          Paint()..color = palette.text.withValues(alpha: opacity),
        );
        label.paint(canvas, pos + Offset(-label.width / 2, r + Space.s4));
        date?.paint(
          canvas,
          pos + Offset(-date.width / 2, r + Space.s4 + label.height),
        );
        canvas.restore();
      }
    }
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder =>
      (size) => [
        for (final n in scene.nodes)
          CustomPainterSemantics(
            rect: Rect.fromCircle(
              center: positions[n.id]!,
              radius: GraphTokens.hitRadius,
            ),
            properties: SemanticsProperties(
              label: n.label,
              button: true,
              selected: n.id == selected,
              onTap: () => onSelect(n.id),
              textDirection: TextDirection.ltr,
            ),
          ),
      ];
  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
  @override
  bool shouldRebuildSemantics(covariant _GraphPainter old) => true;
}

IconData nodeIcon(String type) => switch (type) {
  'memory' => AppIcons.document,
  'chat' => AppIcons.chats,
  'tag' => AppIcons.tag,
  'persona' => AppIcons.entity,
  'entity' => AppIcons.category,
  _ => AppIcons.file,
};

String nodeTypeName(AppLocalizations l, String type) => switch (type) {
  'memory' => l.legendMemory,
  'chat' => l.typeChat,
  'tag' => l.legendTag,
  'persona' => l.legendPersona,
  'entity' => l.legendEntity,
  _ => l.legendFile,
};

class GraphLegend extends StatelessWidget {
  const GraphLegend({super.key, required this.hasEntities});
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
          'chat',
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
                style: TextStyles.caption1.copyWith(color: p.muted),
              ),
            ],
          ),
      ],
    );
  }
}
