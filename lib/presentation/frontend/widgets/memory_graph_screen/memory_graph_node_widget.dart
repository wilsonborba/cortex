import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/memory_graph.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_theme.dart';
import 'memory_graph_painter.dart';

/// A single node rendered on the graph canvas. Every [MemoryGraphNodeType]
/// gets its own card design (see the private `_*Card` widgets below) so a
/// node's kind is legible at a glance from its shape and content, not just an
/// icon/color hint. The full label/subtitle is always still available via
/// [Tooltip] (hover on web/desktop, long-press on touch, [Tooltip]'s own
/// default behavior) for anything truncated on the card itself.
///
/// The widget's outer size always matches
/// [MemoryGraphNodeStyle.sizeForType]: that is the single source of truth
/// also used by the layout margin and node-centering math in
/// `memory_graph_layout.dart`/`memory_graph_screen.dart`, so a card can never
/// be positioned as if it were a different size than it actually renders at.
class MemoryGraphNodeWidget extends StatelessWidget {
  const MemoryGraphNodeWidget({
    super.key,
    required this.node,
    required this.onTap,
    this.clusterCollapsed = false,
  });

  final MemoryGraphNode node;
  final VoidCallback onTap;

  /// Only meaningful for [MemoryGraphNodeType.cluster] nodes: whether this
  /// cluster's members are currently hidden, so `_ClusterCard` can show a
  /// clear expand/collapse indicator alongside its member count.
  final bool clusterCollapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final style = MemoryGraphNodeStyle.forType(node.nodeType, scheme);

    return SizedBox(
      width: style.size.width,
      height: style.size.height,
      child: Tooltip(
        message: node.subtitle?.isNotEmpty ?? false ? '${node.label}\n${node.subtitle}' : node.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              node.nodeType == MemoryGraphNodeType.tag ? style.size.height / 2 : AppTheme.cardRadius,
            ),
            onTap: onTap,
            child: switch (node.nodeType) {
              MemoryGraphNodeType.memory => _MemoryCard(node: node, style: style, scheme: scheme, l10n: l10n),
              MemoryGraphNodeType.attachment => _AttachmentCard(node: node, style: style, scheme: scheme, l10n: l10n),
              MemoryGraphNodeType.tag => _TagChip(node: node, style: style, scheme: scheme),
              MemoryGraphNodeType.entity => _EntityCard(node: node, style: style, scheme: scheme, l10n: l10n),
              MemoryGraphNodeType.resource => _ResourceCard(node: node, style: style, scheme: scheme, l10n: l10n),
              MemoryGraphNodeType.cluster => _ClusterCard(
                  node: node,
                  style: style,
                  scheme: scheme,
                  l10n: l10n,
                  collapsed: clusterCollapsed,
                ),
              MemoryGraphNodeType.unknown => _UnknownCard(node: node, style: style, scheme: scheme),
            },
          ),
        ),
      ),
    );
  }
}

/// `metadata['created_at']` (memory nodes only, as of the backend change
/// that added it) formatted as a short relative or absolute label. Absent or
/// unparseable metadata degrades to `null` (never a crash, never "null" on
/// screen), per the backend contract that only `memory` nodes carry it and
/// only "as of" this change, not retroactively.
String? _formatCreatedAt(AppLocalizations l10n, Map<String, dynamic> metadata) {
  final raw = metadata['created_at'];
  if (raw is! String || raw.isEmpty) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;

  final local = parsed.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inDays >= 7) return DateFormat('MMM d').format(local);
  if (diff.inDays >= 1) return l10n.memoryGraphTimeDaysAgo(diff.inDays);
  if (diff.inHours >= 1) return l10n.memoryGraphTimeHoursAgo(diff.inHours);
  if (diff.inMinutes >= 1) return l10n.memoryGraphTimeMinutesAgo(diff.inMinutes);
  return l10n.memoryGraphTimeJustNow;
}

/// Icon for an attachment's filename extension. Falls back to a generic
/// file icon for anything unrecognized (new/unknown extensions must never
/// crash or leave the card without an icon).
IconData _fileIconForFilename(String filename) {
  final dot = filename.lastIndexOf('.');
  final ext = dot == -1 || dot == filename.length - 1 ? '' : filename.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'doc':
    case 'docx':
    case 'rtf':
      return Icons.description_outlined;
    case 'wav':
    case 'mp3':
    case 'm4a':
    case 'aac':
    case 'ogg':
    case 'flac':
      return Icons.audiotrack_outlined;
    case 'mp4':
    case 'mov':
    case 'webm':
    case 'mkv':
      return Icons.videocam_outlined;
    case 'png':
    case 'jpg':
    case 'jpeg':
    case 'gif':
    case 'webp':
    case 'heic':
      return Icons.image_outlined;
    case 'txt':
    case 'md':
      return Icons.text_snippet_outlined;
    case 'csv':
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    case 'json':
    case 'xml':
    case 'yaml':
    case 'yml':
      return Icons.data_object_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

/// Small caps-style badge used across most card types to name the node's
/// kind (e.g. "MEMORY", "ATTACHMENT"), always in addition to the icon/shape,
/// never as the only type signal.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: color,
      ),
    );
  }
}

/// **memory**: the keyword/snippet (`label`), a formatted `created_at` date
/// when present, and a memory-type indicator (icon + `subtitle`).
class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.node, required this.style, required this.scheme, required this.l10n});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatCreatedAt(l10n, node.metadata);
    final typeLabel = (node.subtitle?.isNotEmpty ?? false) ? node.subtitle! : l10n.memoryGraphTypeMemory;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(context, borderOpacity: 0.5, fillOpacity: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 14, color: style.accent),
              const SizedBox(width: 6),
              Expanded(child: _TypeBadge(text: typeLabel, color: style.accent)),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              node.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2, color: scheme.onSurface),
            ),
          ),
          if (dateLabel != null) ...[
            const SizedBox(height: 6),
            Text(
              dateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: scheme.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ],
      ),
    );
  }
}

/// **attachment**: filename prominent, an icon derived from its extension,
/// and an "attachment" badge (never the raw backend `subtitle` string
/// verbatim, which is just the literal, non-localized `"attachment"`).
class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({required this.node, required this.style, required this.scheme, required this.l10n});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.glassDecoration(context, borderOpacity: 0.5, fillOpacity: 0.92),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_fileIconForFilename(node.label), size: 26, color: style.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2, color: scheme.onSurface),
                ),
                const SizedBox(height: 5),
                _TypeBadge(text: l10n.memoryGraphTypeAttachment, color: style.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// **tag**: a compact chip for a short keyword, distinct from every denser
/// card (a stadium pill, centered content, no multi-row layout).
class _TagChip extends StatelessWidget {
  const _TagChip({required this.node, required this.style, required this.scheme});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: AppTheme.glassDecoration(
        context,
        radius: style.size.height / 2,
        borderOpacity: 0.55,
        fillOpacity: 0.92,
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 13, color: style.accent),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              node.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// **entity**: distinct from a tag chip (people/places/concepts get a denser
/// card with an `entity_type` label when `subtitle` carries one).
class _EntityCard extends StatelessWidget {
  const _EntityCard({required this.node, required this.style, required this.scheme, required this.l10n});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final typeLabel = (node.subtitle?.isNotEmpty ?? false) ? node.subtitle! : l10n.memoryGraphTypeEntity;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.glassDecoration(context, borderOpacity: 0.5, fillOpacity: 0.92),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(style.icon, size: 18, color: style.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 3),
                _TypeBadge(text: typeLabel, color: style.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// **resource**: `subtitle` (resource_type) as a small label plus the
/// resource's own `label`.
class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.node, required this.style, required this.scheme, required this.l10n});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final typeLabel = (node.subtitle?.isNotEmpty ?? false) ? node.subtitle! : l10n.memoryGraphTypeResource;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: AppTheme.glassDecoration(context, borderOpacity: 0.5, fillOpacity: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(style.icon, size: 14, color: style.accent),
              const SizedBox(width: 6),
              Expanded(child: _TypeBadge(text: typeLabel, color: style.accent)),
            ],
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              node.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.2, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

/// **cluster**: a "stack" motif (two faint offset layers behind the front
/// card) since a cluster collapses multiple nodes, plus the collapsed count
/// from `metadata.cluster_of` when available.
class _ClusterCard extends StatelessWidget {
  const _ClusterCard({
    required this.node,
    required this.style,
    required this.scheme,
    required this.l10n,
    required this.collapsed,
  });

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;
  final AppLocalizations l10n;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final count = node.clusterOf.length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 8,
          top: 8,
          right: 0,
          bottom: 0,
          child: Container(decoration: AppTheme.glassDecoration(context, borderOpacity: 0.25, fillOpacity: 0.45)),
        ),
        Positioned(
          left: 4,
          top: 4,
          right: 4,
          bottom: 4,
          child: Container(decoration: AppTheme.glassDecoration(context, borderOpacity: 0.35, fillOpacity: 0.65)),
        ),
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: AppTheme.glassDecoration(context, borderOpacity: 0.55, fillOpacity: 0.96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(style.icon, size: 15, color: style.accent),
                    const SizedBox(width: 6),
                    Expanded(child: _TypeBadge(text: l10n.memoryGraphTypeCluster, color: style.accent)),
                    if (count > 0)
                      Icon(
                        collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                        size: 16,
                        color: style.accent,
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Flexible(
                  child: Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.onSurface),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    collapsed ? l10n.memoryGraphClusterCount(count) : l10n.memoryGraphClusterExpandedCount(count),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: scheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// **unknown**: any node type this client doesn't recognize yet (lenient
/// backend contract, see `memory_graph.dart`). Small, generic, never crashes.
class _UnknownCard extends StatelessWidget {
  const _UnknownCard({required this.node, required this.style, required this.scheme});

  final MemoryGraphNode node;
  final MemoryGraphNodeStyle style;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: AppTheme.glassDecoration(context, borderOpacity: 0.5, fillOpacity: 0.92),
      alignment: Alignment.centerLeft,
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
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
