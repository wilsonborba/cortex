import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/models/chat_message.dart';
import 'audio_message_player.dart';
import 'code_block_view.dart';
import 'continue_generation_chip.dart';
import 'sources_card.dart';

/// Renders a single [ChatMessage] as a markdown bubble, aligned right for
/// the user and left for the assistant/system. When the message carries
/// [ChatMessage.sources] (a web-search-grounded reply, issue #6), an
/// expandable "Sources (N)" card is rendered underneath it. Fenced code
/// blocks are rendered via [CodeBlockElementBuilder] with a copy toolbar
/// (issue #7). When [ChatMessage.interrupted] is set (a dropped SSE
/// connection left this reply partial, issue #7), a
/// [ContinueGenerationChip] is rendered underneath it and [onContinueGeneration]
/// is called when the user taps it.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onContinueGeneration,
    this.isContinuingGeneration = false,
  });

  final ChatMessage message;

  /// Called with [message.id] when the user taps the "Continue generation"
  /// chip. Only rendered when [message.interrupted] is true.
  final VoidCallback? onContinueGeneration;

  /// Whether a continue-generation retry for this exact message is
  /// currently in flight, disables/shows a spinner on the chip.
  final bool isContinuingGeneration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.role == MessageRole.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bubbleBg = isUser
        ? (isDark ? const Color(0xFF181B22) : const Color(0xFFE2E2E7))
        : (isDark ? const Color(0xFF111318) : const Color(0xFFFFFFFF));
    final textColor = scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'lib/presentation/assets/img/logo.png',
                      width: 16,
                      height: 16,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.hub, size: 14),
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Role and Timestamp Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
                      child: Text(
                        isUser
                            ? 'WILSON // USER'
                            : 'CORTEX.AI // MODEL-01',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.outline.withValues(
                            alpha: isDark ? 0.35 : 0.6,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.attachments.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: message.content.trim().isEmpty ? 0 : 8,
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: message.attachments
                                    .map((a) => _MessageAttachment(attachment: a))
                                    .toList(),
                              ),
                            ),
                          if (message.content.trim().isNotEmpty)
                            MarkdownBody(
                              data: message.content,
                              selectable: true,
                              builders: {'pre': CodeBlockElementBuilder()},
                              styleSheet: MarkdownStyleSheet(
                                p: TextStyle(
                                  color: textColor,
                                  height: 1.5,
                                  fontSize: 13.5,
                                ),
                                code: TextStyle(
                                  color: textColor,
                                  fontFamily: 'monospace',
                                  backgroundColor:
                                      scheme.onSurface.withValues(alpha: 0.08),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isUser && message.sources.isNotEmpty)
                      SourcesCard(sources: message.sources),
                    if (!isUser &&
                        message.interrupted &&
                        onContinueGeneration != null)
                      ContinueGenerationChip(
                        onPressed: onContinueGeneration!,
                        isBusy: isContinuingGeneration,
                      ),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Text(
                    'W',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One attachment rendered inline in a sent/received bubble (issue #11):
/// a thumbnail for an image, an interactive player for a voice message, or
/// a filename chip for anything else.
class _MessageAttachment extends StatelessWidget {
  const _MessageAttachment({required this.attachment});

  final ChatAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.isAudio) {
      return AudioMessagePlayer(attachment: attachment);
    }
    if (attachment.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          attachment.bytes,
          width: 160,
          height: 160,
          fit: BoxFit.cover,
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined, size: 16, color: scheme.onSurface),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
