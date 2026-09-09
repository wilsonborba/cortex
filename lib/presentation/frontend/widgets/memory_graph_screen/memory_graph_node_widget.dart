import 'package:flutter/material.dart';

import '../../../../domain/models/memory_graph.dart';
import '../../components/app_theme.dart';
import 'memory_graph_painter.dart';

/// A single node rendered on the graph canvas: a small glass pill with an
/// icon (per [MemoryGraphNodeType]) and a truncated label. Full label is
/// shown via [Tooltip] (hover on web/desktop, long-press on touch, which is
/// [Tooltip]'s own default behavior).
class MemoryGraphNodeWidget extends StatelessWidget {
  const MemoryGraphNodeWidget({
    super.key,
    required this.node,
    required this.onTap,
    this.width = 150,
  });

  final MemoryGraphNode node;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = MemoryGraphNodeStyle.forType(node.nodeType, scheme);

    return SizedBox(
      width: width,
      child: Tooltip(
        message: node.subtitle?.isNotEmpty ?? false ? '${node.label}\n${node.subtitle}' : node.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: AppTheme.glassDecoration(
                context,
                radius: AppTheme.controlRadius,
                borderOpacity: 0.5,
                fillOpacity: 0.92,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon, size: 14, color: style.accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
