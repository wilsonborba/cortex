import 'package:flutter/material.dart';

import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/prompt_dock.dart';
import '../../components/scroll_to_bottom_button.dart';
import '../../components/telemetry_panel.dart';
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
  final _scroll = StickyScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _showClearAllConfirmation() {
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
          'Delete All Conversations?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This action will permanently delete all session history and cached executions. This action cannot be undone.',
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
              widget.props.onClearAllConversations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC53030),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scroll.maybeAutoScroll(),
    );
    final props = widget.props;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            // Left Collapsible Sidebar
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _sidebarCollapsed ? 0 : 280,
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  right: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: _sidebarCollapsed
                  ? null
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sidebar Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          child: Row(
                            children: [
                              Image.asset(
                                'lib/presentation/assets/img/logo.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.hub, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CORTEX',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: 'Collapse Sidebar',
                                icon: const Icon(Icons.menu_open, size: 18),
                                onPressed: () =>
                                    setState(() => _sidebarCollapsed = true),
                              ),
                            ],
                          ),
                        ),
                        // + New Conversation Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: OutlinedButton(
                            onPressed: props.onNewConversation,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '+ New Conversation',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '⌘N',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // History header with Clear All button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HISTORY',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: scheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              InkWell(
                                onTap: _showClearAllConfirmation,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 13,
                                        color: scheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Clear All',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: scheme.onSurface.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Conversation List
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            itemCount: props.conversations.length,
                            itemBuilder: (context, index) {
                              final conversation = props.conversations[index];
                              return ConversationTile(
                                conversation: conversation,
                                isSelected: conversation.id ==
                                    props.selectedConversation.id,
                                onTap: () => props.onSelectConversation(
                                  conversation.id,
                                ),
                              );
                            },
                          ),
                        ),
                        // User Profile Footer
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: scheme.outline.withValues(alpha: 0.15),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: scheme.surfaceContainerHighest,
                                child: Text(
                                  'W',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Wilson Borba',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'PRO // ASODYA AUTH',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontFamily: 'monospace',
                                        color: scheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Settings',
                                icon: const Icon(Icons.settings_outlined, size: 16),
                                onPressed: () => AppSettingsSheet.show(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            // Right Main Chat Area
            Expanded(
              child: Column(
                children: [
                  // Top Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: scheme.outline.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (_sidebarCollapsed)
                          IconButton(
                            tooltip: 'Expand Sidebar',
                            icon: const Icon(Icons.menu, size: 18),
                            onPressed: () =>
                                setState(() => _sidebarCollapsed = false),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  props.selectedConversation.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  'TIER 0 // CORTEX-T0',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: scheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Start Incognito Chat',
                          icon: const Icon(Icons.visibility_off_outlined, size: 18),
                          onPressed: props.onStartIncognitoChat,
                        ),
                        const TelemetryPanelButton(),
                        IconButton(
                          tooltip: 'Settings',
                          icon: const Icon(Icons.tune_outlined, size: 18),
                          onPressed: () => AppSettingsSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 860),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (_scroll.handleNotification(notification)) {
                                  setState(() {});
                                }
                                return false;
                              },
                              child: ListView.builder(
                                controller: _scroll.controller,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                itemCount:
                                    props.selectedConversation.messages.length,
                                itemBuilder: (context, index) {
                                  final message = props
                                      .selectedConversation
                                      .messages[index];
                                  return MessageBubble(
                                    message: message,
                                    onContinueGeneration: () =>
                                        props.onContinueGeneration(message.id),
                                    isContinuingGeneration:
                                        props.continuingMessageId == message.id,
                                  );
                                },
                              ),
                            ),
                            if (!_scroll.isSticky)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ScrollToBottomButton(
                                  onPressed: () {
                                    _scroll.scrollToBottom();
                                    setState(() {});
                                  },
                                ),
                              ),
                          ],
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
                          useMemory: props.useMemory,
                          onToggleMemory: props.onToggleMemory,
                          needsWeb: props.needsWeb,
                          onToggleNeedsWeb: props.onToggleNeedsWeb,
                          pendingAttachments: props.pendingAttachments,
                          onAddAttachments: props.onAddAttachments,
                          onRemoveAttachment: props.onRemoveAttachment,
                          conversationId: props.selectedConversation.id,
                          draftText: props.draftText,
                          onDraftChanged: props.onDraftChanged,
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
