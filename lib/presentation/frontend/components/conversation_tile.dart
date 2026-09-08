import 'package:flutter/material.dart';

import '../../../domain/models/conversation.dart';

/// Sidebar / drawer list item representing one conversation.
class ConversationTile extends StatefulWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    this.onRename,
    this.onTogglePin,
    this.onDelete,
  });

  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<String>? onRename;
  final VoidCallback? onTogglePin;
  final VoidCallback? onDelete;

  @override
  State<ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<ConversationTile> {
  bool _isHovered = false;

  void _showRenameDialog() {
    final scheme = Theme.of(context).colorScheme;
    final controller = TextEditingController(text: widget.conversation.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        title: const Text(
          'Rename Conversation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Enter conversation title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: scheme.primary),
            ),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              Navigator.of(ctx).pop();
              widget.onRename?.call(trimmed);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(ctx).pop();
                widget.onRename?.call(trimmed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        title: const Text(
          'Delete Conversation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.conversation.title}"? This cannot be undone.',
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: scheme.onSurface),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC53030),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = widget.isSelected;
    final conversation = widget.conversation;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? scheme.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? Border.all(color: scheme.outline.withValues(alpha: 0.3))
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  if (isSelected)
                    Container(
                      width: 3,
                      height: 16,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  if (conversation.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.push_pin_outlined,
                        size: 13,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  if (_isHovered || isSelected)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      splashRadius: 14,
                      icon: Icon(
                        Icons.more_horiz,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                      tooltip: 'Options',
                      onSelected: (action) {
                        if (action == 'rename') {
                          _showRenameDialog();
                        } else if (action == 'pin') {
                          widget.onTogglePin?.call();
                        } else if (action == 'delete') {
                          _showDeleteDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'rename',
                          height: 32,
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: scheme.onSurface),
                              const SizedBox(width: 8),
                              const Text('Rename', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pin',
                          height: 32,
                          child: Row(
                            children: [
                              Icon(
                                conversation.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin,
                                size: 14,
                                color: scheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                conversation.isPinned ? 'Unpin' : 'Pin',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'delete',
                          height: 32,
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline, size: 14, color: Color(0xFFE53E3E)),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(fontSize: 12, color: Color(0xFFE53E3E)),
                              ),
                            ],
                          ),
                        ),
                      ],
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
