import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../chat/chat_list.dart';

IconData nodeIcon(String type) => switch (type) {
  'memory' => Icons.lightbulb_outline,
  'tag' => Icons.sell_outlined,
  'persona' => Icons.person_outline,
  'entity' => Icons.category_outlined,
  _ => Icons.description_outlined,
};

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return parts.take(2).map((w) => w.characters.first.toUpperCase()).join();
}

/// A readable card for one node (32.3); the id only under Details.
class MemoryCard extends StatelessWidget {
  const MemoryCard({super.key, required this.data, this.onOpen, this.now});
  final MemoryGraphData data;
  final ValueChanged<String>? onOpen;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final node = data.node!;
    final m = node.metadata;
    final linked = data.linked(node.id);
    final files = linked.where((n) => n.type == 'file').toList();
    final personas = linked.where((n) => n.displayType == 'persona').toList();
    final tags = linked.where((n) => n.type == 'tag').toList();
    final memories = linked.where((n) => n.type == 'memory').toList();
    final summary = '${m['summary'] ?? ''}'.trim();
    final title = '${m['title'] ?? ''}'.trim().isNotEmpty
        ? '${m['title']}'
        : summary.isNotEmpty
        ? summary.split('\n').first
        : node.label.trim().isNotEmpty && node.label != node.id
        ? node.label
        : nodeTypeName(l, node.displayType);
    final (typeIcon, typeName) = node.type != 'memory'
        ? (nodeIcon(node.displayType), nodeTypeName(l, node.displayType))
        : m['memory_type'] == 'file'
        ? (Icons.description_outlined, l.typeFile)
        : m['memory_type'] == 'episodic'
        ? (Icons.chat_bubble_outline, l.typeChat)
        : (Icons.sticky_note_2_outlined, l.typeNote);
    final created = '${m['created_at'] ?? ''}';
    final meta = TextStyles.label.copyWith(color: p.muted);
    Widget section(String label, List<Widget> children) => children.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: Space.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: meta),
                const SizedBox(height: Space.s4),
                Wrap(
                  spacing: Space.s8,
                  runSpacing: Space.s8,
                  children: children,
                ),
              ],
            ),
          );
    return Column(
      key: const Key('memory-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, key: const Key('card-title'), style: TextStyles.subsection),
        const SizedBox(height: Space.s8),
        Wrap(
          spacing: Space.s12,
          runSpacing: Space.s4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(typeIcon, size: 16, color: p.muted),
                const SizedBox(width: Space.s4),
                Text(typeName, key: const Key('card-type'), style: meta),
              ],
            ),
            if (m['app_id'] != null)
              Text('${m['app_id']}', key: const Key('card-app'), style: meta),
            if (created.isNotEmpty)
              Tooltip(
                message:
                    DateTime.tryParse(created)?.toLocal().toString() ?? created,
                child: Text(
                  relativeTime(l, created, (now ?? DateTime.now)()),
                  key: const Key('card-date'),
                  style: meta,
                ),
              ),
            if (m['status'] == 'superseded')
              Container(
                key: const Key('card-superseded'),
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: p.border),
                  borderRadius: BorderRadius.circular(Radii.control),
                ),
                child: Text(l.superseded, style: meta),
              ),
          ],
        ),
        if (summary.isNotEmpty) ...[
          const SizedBox(height: Space.s12),
          Text(
            summary,
            key: const Key('card-summary'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.compact,
          ),
        ],
        section(l.legendTag, [
          for (final t in tags)
            Text(
              '#${t.label}',
              style: TextStyles.label.copyWith(
                fontFamily: TextStyles.mono,
                color: p.text,
              ),
            ),
        ]),
        section(l.linkedPersonas, [
          for (final persona in personas)
            ActionChip(
              avatar: ExcludeSemantics(
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: p.surface,
                  child: Text(
                    initials(persona.label),
                    style: TextStyles.label.copyWith(color: p.text),
                  ),
                ),
              ),
              label: Text(
                persona.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.compact.copyWith(color: p.text),
              ),
              onPressed: () => onOpen?.call(persona.id),
            ),
        ]),
        section(l.linkedFiles, [
          for (final f in files)
            ActionChip(
              avatar: const Icon(Icons.description_outlined, size: 16),
              label: Text(f.label, style: TextStyles.label),
              onPressed: () => onOpen?.call(f.id),
            ),
        ]),
        section(l.linkedMemories, [
          for (final n in memories)
            ActionChip(
              avatar: const Icon(Icons.lightbulb_outline, size: 16),
              label: Text(
                n.label,
                style: TextStyles.label,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: () => onOpen?.call(n.id),
            ),
        ]),
        const SizedBox(height: Space.s12),
        ExpansionTile(
          key: const Key('card-details'),
          tilePadding: EdgeInsets.zero,
          title: Text(l.detailsLabel, style: meta),
          children: [
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    node.id,
                    style: TextStyles.label.copyWith(
                      fontFamily: TextStyles.mono,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('copy-id'),
                  tooltip: l.copy,
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: node.id));
                    ScaffoldMessenger.maybeOf(
                      context,
                    )?.showSnackBar(SnackBar(content: Text(l.copied)));
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

String nodeTypeName(AppLocalizations l, String type) => switch (type) {
  'memory' => l.legendMemory,
  'tag' => l.legendTag,
  'persona' => l.legendPersona,
  'entity' => l.legendEntity,
  _ => l.legendFile,
};
