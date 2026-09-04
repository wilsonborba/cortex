import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../domain/models/chat_message.dart';

/// Renders a single [ChatMessage] as a markdown bubble, aligned right for
/// the user and left for the assistant/system.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

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
        child: Container(
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
                : Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
          ),
          child: MarkdownBody(
            data: message.content,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: textColor, height: 1.4),
              code: TextStyle(
                color: textColor,
                backgroundColor: textColor.withValues(alpha: 0.08),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
