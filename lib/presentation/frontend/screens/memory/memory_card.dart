import '../../theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/models/memory_graph.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../chat/chat_list.dart';
import '../../widgets/common/toast.dart';
import '../../widgets/common/states.dart' show NoticeKind;

IconData nodeIcon(String type) => switch (type) {
  'memory' => AppIcons.document,
  'chat' => AppIcons.chats,
  'tag' => AppIcons.tag,
  'persona' => AppIcons.entity,
  'entity' => AppIcons.category,
  _ => AppIcons.file,
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
    final p = Palette.from(context);
    final node = data.node!;
    final m = node.metadata;
    final linked = data.linked(node.id);
    final files = linked.where((n) => n.type == 'file').toList();
    final personas = linked.where((n) => n.displayType == 'persona').toList();
    final tags = linked.where((n) => n.type == 'tag').toList();
    final memories = linked.where((n) => n.type == 'memory').toList();
    final chats = [
      if (node.type == 'chat') node,
      ...linked.where((n) => n.type == 'chat'),
    ];
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
        ? (AppIcons.file, l.typeFile)
        : m['memory_type'] == 'episodic'
        ? (AppIcons.chats, l.typeChat)
        : (AppIcons.document, l.typeNote);
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
                Icon(typeIcon, size: IconSizes.action, color: p.muted),
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
                  borderRadius: BorderRadius.circular(
                    FoundationTokens.of(context).controlRadius,
                  ),
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
              visualDensity: Controls.tagDensity,
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
              ),
              onPressed: () => onOpen?.call(persona.id),
            ),
        ]),
        section(l.linkedFiles, [
          for (final f in files)
            ActionChip(
              visualDensity: Controls.tagDensity,
              avatar: const Icon(AppIcons.file),
              label: Text(f.label),
              onPressed: () => onOpen?.call(f.id),
            ),
        ]),
        section(l.linkedMemories, [
          for (final n in memories)
            ActionChip(
              visualDensity: Controls.tagDensity,
              avatar: const Icon(AppIcons.note),
              label: Text(n.label, overflow: TextOverflow.ellipsis),
              onPressed: () => onOpen?.call(n.id),
            ),
        ]),
        for (final chat in chats)
          if (chat.metadata['source_system'] == 'cortex' &&
              chat.metadata['external_id'] is String)
            TextButton.icon(
              onPressed: () => GoRouter.maybeOf(context)?.go(
                '/v1/chats/${Uri.encodeComponent(chat.metadata['external_id'])}',
              ),
              icon: const Icon(AppIcons.chats, size: IconSizes.action),
              label: Text(l.openChat),
            ),
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
                  icon: const Icon(AppIcons.copy, size: IconSizes.action),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: node.id));
                    showToast(
                      context,
                      message: l.copied,
                      kind: NoticeKind.success,
                    );
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
                style: TextStyles.label.copyWith(color: p.muted),
              ),
            ],
          ),
      ],
    );
  }
}
