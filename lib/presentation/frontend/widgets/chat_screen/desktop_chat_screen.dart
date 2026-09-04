import 'package:flutter/material.dart';

import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/premium_hover_card.dart';
import '../../components/prompt_dock.dart';
import 'chat_screen.dart';

/// Desktop / wide-viewport layout: a collapsible master sidebar of
/// conversations next to a centered, max-width chat viewport with the
/// floating prompt dock anchored at the bottom.
class DesktopChatScreen extends StatefulWidget {
  const DesktopChatScreen({super.key, required this.props});

  final ChatScreenProps props;

  @override
  State<DesktopChatScreen> createState() => _DesktopChatScreenState();
}

class _DesktopChatScreenState extends State<DesktopChatScreen> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final props = widget.props;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _sidebarCollapsed ? 0 : 280,
              margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: _sidebarCollapsed
                  ? null
                  : PremiumHoverCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Cortex',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Collapse sidebar',
                                icon: const Icon(Icons.menu_open, size: 20),
                                onPressed: () =>
                                    setState(() => _sidebarCollapsed = true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: props.conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = props.conversations[index];
                                return ConversationTile(
                                  conversation: conversation,
                                  isSelected:
                                      conversation.id ==
                                      props.selectedConversation.id,
                                  onTap: () => props.onSelectConversation(
                                    conversation.id,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                    child: Row(
                      children: [
                        if (_sidebarCollapsed)
                          IconButton(
                            tooltip: 'Expand sidebar',
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                setState(() => _sidebarCollapsed = false),
                          ),
                        Expanded(
                          child: Text(
                            props.selectedConversation.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Toggle theme',
                          icon: const Icon(Icons.brightness_6_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          itemCount: props.selectedConversation.messages.length,
                          itemBuilder: (context, index) {
                            return MessageBubble(
                              message:
                                  props.selectedConversation.messages[index],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: PromptDock(
                          isBusy: props.isBusy,
                          onSubmit: props.onSubmit,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
