import 'package:flutter/material.dart';

import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/prompt_dock.dart';
import '../../components/scroll_to_bottom_button.dart';
import '../../components/telemetry_panel.dart';
import 'chat_screen.dart';

/// Mobile / narrow-viewport layout: a single chat view with a sliding
/// drawer for the conversation list and a bottom sheet for session
/// settings. `resizeToAvoidBottomInset` keeps the prompt dock above the
/// virtual keyboard instead of letting it get covered.
class MobileChatScreen extends StatefulWidget {
  const MobileChatScreen({super.key, required this.props});

  final ChatScreenProps props;

  @override
  State<MobileChatScreen> createState() => _MobileChatScreenState();
}

class _MobileChatScreenState extends State<MobileChatScreen> {
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
    final props = widget.props;
    final scheme = Theme.of(context).colorScheme;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scroll.maybeAutoScroll(),
    );

    return Scaffold(
      backgroundColor: scheme.surface,
      resizeToAvoidBottomInset: true,
      drawerScrimColor: Colors.black.withValues(alpha: 0.4),
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (props.selectedConversation.isEphemeral)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: 'Incognito',
                  child: const Icon(Icons.visibility_off_outlined, size: 16),
                ),
              ),
            Flexible(
              child: Text(
                props.selectedConversation.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Incognito',
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
      drawer: Drawer(
        backgroundColor: scheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drawer Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Image.asset(
                      'lib/presentation/assets/img/logo.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.hub, size: 18),
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
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // + New Conversation Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    props.onNewConversation();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('+ New Conversation'),
                ),
              ),
              const SizedBox(height: 12),
              // History Section Header with Clear All
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
                      onTap: () {
                        Navigator.of(context).pop();
                        _showClearAllConfirmation();
                      },
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
                      onTap: () {
                        props.onSelectConversation(conversation.id);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
                        horizontal: 12,
                        vertical: 12,
                      ),
                      itemCount: props.selectedConversation.messages.length,
                      itemBuilder: (context, index) {
                        final message =
                            props.selectedConversation.messages[index];
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
                      padding: const EdgeInsets.only(bottom: 8),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
          ],
        ),
      ),
    );
  }
}
