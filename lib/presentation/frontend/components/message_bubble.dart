import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../domain/models/chat_message.dart';
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

    final bubbleColor = isUser
        ? scheme.onSurface.withValues(alpha: 0.92)
        : scheme.surface.withValues(alpha: 0.6);
    final textColor = isUser ? scheme.surface : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: scheme.onSurface.withValues(alpha: 0.10),
                      ),
              ),
              child: MarkdownBody(
                data: message.content,
                selectable: true,
                builders: {'pre': CodeBlockElementBuilder()},
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: textColor, height: 1.4),
                  code: TextStyle(
                    color: textColor,
                    backgroundColor: textColor.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            if (!isUser && message.sources.isNotEmpty)
              SourcesCard(sources: message.sources),
            if (!isUser && message.interrupted && onContinueGeneration != null)
              ContinueGenerationChip(
                onPressed: onContinueGeneration!,
                isBusy: isContinuingGeneration,
              ),
          ],
        ),
      ),
    );
  }
}
