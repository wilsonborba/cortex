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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.isSelected;
    final conversation = widget.conversation;

    final selectedBg = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.95)
        : scheme.primary.withValues(alpha: 0.08);
    final hoverBg = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : scheme.primary.withValues(alpha: 0.04);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBg
              : (_isHovered ? hoverBg : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.6),
                  width: 1,
                )
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    conversation.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: isSelected
                        ? scheme.primary
                        : scheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        letterSpacing: -0.1,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? scheme.onSurface
                            : scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  // Always present (not gated on hover): on a touch device
                  // (phone/tablet) there is no hover state at all, so a
                  // hover-only menu button is permanently invisible and
                  // unreachable for any conversation that isn't already the
                  // selected one -- this was the actual cause of "delete
                  // individual conversation doesn't work" on mobile (Clear
                  // All is a separate affordance elsewhere, unaffected).
                  // Faded when neither hovered nor selected on pointer
                  // devices to keep the same restrained look there.
                  Opacity(
                    opacity: (_isHovered || isSelected) ? 1.0 : 0.55,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      splashRadius: 14,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        size: 16,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      tooltip: 'Options',
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.6),
                        ),
                      ),
                      color: scheme.surface,
                      elevation: 8,
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
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 15, color: scheme.onSurface),
                              const SizedBox(width: 10),
                              const Text('Rename', style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'pin',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(
                                conversation.isPinned
                                    ? Icons.push_pin_outlined
                                    : Icons.push_pin_rounded,
                                size: 15,
                                color: scheme.onSurface,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                conversation.isPinned ? 'Unpin' : 'Pin',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        PopupMenuItem(
                          value: 'delete',
                          height: 36,
                          child: Row(
                            children: const [
                              Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFE53E3E)),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(fontSize: 13, color: Color(0xFFE53E3E), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
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
