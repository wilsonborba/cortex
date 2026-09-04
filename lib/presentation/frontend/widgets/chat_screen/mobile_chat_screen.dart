import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/prompt_dock.dart';
import '../../components/telemetry_panel.dart';
import '../../components/tier_badge.dart';
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _openSessionSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TierBadge(),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.memoryRecallTitle),
                  subtitle: Text(l10n.memoryRecallSubtitle),
                  value: widget.props.useMemory,
                  onChanged: widget.props.onToggleMemory,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.webBrowsingTitle),
                  subtitle: Text(l10n.webBrowsingSubtitle),
                  value: false,
                  onChanged: null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final l10n = AppLocalizations.of(context);
    _scrollToBottom();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          props.selectedConversation.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const TelemetryPanelButton(),
          IconButton(
            tooltip: l10n.openSettings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => AppSettingsSheet.show(context),
          ),
          IconButton(
            tooltip: l10n.sessionOptions,
            icon: const Icon(Icons.tune),
            onPressed: _openSessionSheet,
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.appTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: props.conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = props.conversations[index];
                    return ConversationTile(
                      conversation: conversation,
                      isSelected:
                          conversation.id == props.selectedConversation.id,
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
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: props.selectedConversation.messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(
                    message: props.selectedConversation.messages[index],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: PromptDock(
                isBusy: props.isBusy,
                onSubmit: props.onSubmit,
                useMemory: props.useMemory,
                onToggleMemory: props.onToggleMemory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
