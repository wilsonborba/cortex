import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/attachment.dart';
import '../../../../domain/models/conversation.dart';
import '../../../../domain/services/chat_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/chat_flow_handler.dart';
import '../../handlers/conversation_handler.dart';
import 'desktop_chat_screen.dart';
import 'mobile_chat_screen.dart';

/// Responsive coordinator: picks the desktop split-view or the mobile
/// drawer layout depending on the available width, and owns the handlers
/// both layouts share.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  late final ConversationHandler _conversationHandler;
  late ChatFlowHandler _flowHandler;
  Object? _lastShownError;

  @override
  void initState() {
    super.initState();
    _conversationHandler = ConversationHandler(_chatService);
    _flowHandler = ChatFlowHandler(_chatService, _conversationHandler.selected);
    _conversationHandler.addListener(_onConversationChanged);
  }

  void _maybeShowError() {
    final error = _flowHandler.error;
    if (error == null || identical(error, _lastShownError)) return;
    _lastShownError = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSendMessage('$error'))),
      );
    });
  }

  void _onConversationChanged() {
    _flowHandler.switchConversation(_conversationHandler.selected);
  }

  @override
  void dispose() {
    _conversationHandler.removeListener(_onConversationChanged);
    _conversationHandler.dispose();
    _flowHandler.dispose();
    super.dispose();
  }

  Future<void> _onSubmit(String text) async {
    await _flowHandler.submit(text);
    _conversationHandler.refresh();
    setState(() {});
  }

  /// Sends a finished voice recording as its own message (issue #11: an
  /// actual playable voice message, not speech-to-text dictation), with no
  /// accompanying text.
  Future<void> _onSendVoiceMessage(ChatAttachment attachment) async {
    _flowHandler.addPendingAttachment(attachment);
    await _flowHandler.submit('');
    _conversationHandler.refresh();
    setState(() {});
  }

  Future<void> _onContinueGeneration(String replyMessageId) async {
    await _flowHandler.continueGeneration(replyMessageId);
    _conversationHandler.refresh();
    setState(() {});
  }

  void _onSelectConversation(String id) {
    _conversationHandler.select(id);
    setState(() {});
  }

  /// Starts a new incognito/temporary chat (issue #6): a brand-new,
  /// never-persisted conversation, not added to the sidebar list, with
  /// memory explicitly forced off for every message sent inside it.
  void _onStartIncognitoChat() {
    _flowHandler.startIncognitoConversation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_conversationHandler, _flowHandler]),
      builder: (context, _) {
        _maybeShowError();
        final props = ChatScreenProps(
          conversations: _conversationHandler.conversations,
          selectedConversation: _flowHandler.conversation,
          isBusy: _flowHandler.isBusy,
          useMemory: _flowHandler.useMemory,
          onToggleMemory: _flowHandler.setUseMemory,
          needsWeb: _flowHandler.needsWeb,
          onToggleNeedsWeb: _flowHandler.setNeedsWeb,
          pendingAttachments: _flowHandler.pendingAttachments,
          onAddAttachments: _flowHandler.addPendingAttachments,
          onRemoveAttachment: _flowHandler.removePendingAttachment,
          onStartIncognitoChat: _onStartIncognitoChat,
          onSelectConversation: _onSelectConversation,
          onNewConversation: () => _conversationHandler.createNew(),
          onClearAllConversations: () => _conversationHandler.clearAll(),
          onDeleteConversation: (id) => _conversationHandler.delete(id),
          onSubmit: _onSubmit,
          onSendVoiceMessage: _onSendVoiceMessage,
          draftText: _flowHandler.draftText,
          onDraftChanged: _flowHandler.updateDraft,
          onContinueGeneration: _onContinueGeneration,
          continuingMessageId: _flowHandler.continuingMessageId,
        );
        return Responsive.isMobile(context)
            ? MobileChatScreen(props: props)
            : DesktopChatScreen(props: props);
      },
    );
  }
}

/// Data and callbacks shared by both the desktop and mobile chat screens.
class ChatScreenProps {
  const ChatScreenProps({
    required this.conversations,
    required this.selectedConversation,
    required this.isBusy,
    required this.useMemory,
    required this.onToggleMemory,
    required this.needsWeb,
    required this.onToggleNeedsWeb,
    required this.pendingAttachments,
    required this.onAddAttachments,
    required this.onRemoveAttachment,
    required this.onStartIncognitoChat,
    required this.onSelectConversation,
    required this.onNewConversation,
    required this.onClearAllConversations,
    required this.onDeleteConversation,
    required this.onSubmit,
    required this.onSendVoiceMessage,
    required this.draftText,
    required this.onDraftChanged,
    required this.onContinueGeneration,
    required this.continuingMessageId,
  });

  final List<Conversation> conversations;
  final Conversation selectedConversation;
  final bool isBusy;
  final VoidCallback onNewConversation;
  final VoidCallback onClearAllConversations;
  final ValueChanged<String> onDeleteConversation;

  /// Whether the next [onSubmit] should route through cortex_api's native
  /// `/execute` with `capabilities.memory = true` instead of the streamed
  /// chat completion facade.
  final bool useMemory;
  final ValueChanged<bool> onToggleMemory;

  /// Whether the next [onSubmit] should set `needs_web`/`capabilities.web`
  /// (issue #6, web-search grounding).
  final bool needsWeb;
  final ValueChanged<bool> onToggleNeedsWeb;

  /// Files picked from the prompt dock's attach menu, waiting to be sent
  /// with the next [onSubmit] (issue #6).
  final List<ChatAttachment> pendingAttachments;
  final ValueChanged<List<ChatAttachment>> onAddAttachments;
  final ValueChanged<String> onRemoveAttachment;

  /// Starts a brand-new incognito/temporary conversation (issue #6): no
  /// persisted history, memory explicitly off.
  final VoidCallback onStartIncognitoChat;
  final ValueChanged<String> onSelectConversation;
  final ValueChanged<String> onSubmit;

  /// Sends a finished voice recording (issue #11) as its own message.
  final ValueChanged<ChatAttachment> onSendVoiceMessage;

  /// Current in-progress, unsent draft for [selectedConversation] (issue
  /// #7), restored from `DraftStore` and kept in sync as the user types.
  final String draftText;
  final ValueChanged<String> onDraftChanged;

  /// Retries the request behind an interrupted assistant reply (issue #7).
  /// Called with that message's id.
  final ValueChanged<String> onContinueGeneration;

  /// Id of the assistant message currently being retried via
  /// [onContinueGeneration], if any.
  final String? continuingMessageId;
}
