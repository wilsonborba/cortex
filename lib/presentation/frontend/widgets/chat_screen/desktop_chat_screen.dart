import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/premium_hover_card.dart';
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

  @override
  Widget build(BuildContext context) {
    // Runs after every rebuild, including ones triggered by a growing
    // streamed token or a brand-new message, so the list keeps sticking to
    // the bottom while sticky, and does nothing once the user has
    // scrolled away (see StickyScrollController.maybeAutoScroll).
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scroll.maybeAutoScroll(),
    );
    final props = widget.props;
    final l10n = AppLocalizations.of(context);

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
                                  l10n.appTitle,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.collapseSidebar,
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
                            tooltip: l10n.expandSidebar,
                            icon: const Icon(Icons.menu),
                            onPressed: () =>
                                setState(() => _sidebarCollapsed = false),
                          ),
                        if (props.selectedConversation.isEphemeral)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Tooltip(
                              message: l10n.incognitoModeSubtitle,
                              child: const Icon(
                                Icons.visibility_off_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            props.selectedConversation.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.newIncognitoChat,
                          icon: const Icon(Icons.visibility_off_outlined),
                          onPressed: props.onStartIncognitoChat,
                        ),
                        const TelemetryPanelButton(),
                        IconButton(
                          tooltip: l10n.openSettings,
                          icon: const Icon(Icons.settings_outlined),
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
