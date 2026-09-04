import 'package:flutter/material.dart';

import '../../../domain/models/attachment.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Horizontal strip of pending attachments shown above the prompt dock's
/// input field (issue #6): an image thumbnail for pictures, a file-name
/// chip for documents, each with a remove/cancel affordance before send.
class AttachmentPreviewStrip extends StatelessWidget {
  const AttachmentPreviewStrip({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<ChatAttachment> attachments;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              _AttachmentChip(
                attachment: attachment,
                backendGapTooltip: l10n.documentAttachmentBackendGap,
              ),
              Positioned(
                right: -6,
                top: -6,
                child: GestureDetector(
                  onTap: () => onRemove(attachment.id),
                  child: Tooltip(
                    message: l10n.removeAttachment,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: scheme.onSurface,
                      child: Icon(Icons.close, size: 12, color: scheme.surface),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.attachment, required this.backendGapTooltip});

  final ChatAttachment attachment;
  final String backendGapTooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (attachment.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          attachment.bytes,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 140,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 18, color: scheme.onSurface),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              attachment.filename,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          if (!attachment.isAcceptedByBackendToday)
            Tooltip(
              message: backendGapTooltip,
              child: Icon(Icons.info_outline, size: 14, color: scheme.error),
            ),
        ],
      ),
    );
  }
}
