import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../domain/models/conversation.dart';
import '../../../../domain/services/chat_service.dart';
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

  @override
  void initState() {
    super.initState();
    _conversationHandler = ConversationHandler(_chatService);
    _flowHandler = ChatFlowHandler(_chatService, _conversationHandler.selected);
    _conversationHandler.addListener(_onConversationChanged);
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

  void _onSelectConversation(String id) {
    _conversationHandler.select(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_conversationHandler, _flowHandler]),
      builder: (context, _) {
        final props = ChatScreenProps(
          conversations: _conversationHandler.conversations,
          selectedConversation: _flowHandler.conversation,
          isBusy: _flowHandler.isBusy,
          useMemory: _flowHandler.useMemory,
          onToggleMemory: _flowHandler.setUseMemory,
          onSelectConversation: _onSelectConversation,
          onSubmit: _onSubmit,
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
    required this.onSelectConversation,
    required this.onSubmit,
  });

  final List<Conversation> conversations;
  final Conversation selectedConversation;
  final bool isBusy;

  /// Whether the next [onSubmit] should route through cortex_api's native
  /// `/execute` with `capabilities.memory = true` instead of the streamed
  /// chat completion facade.
  final bool useMemory;
  final ValueChanged<bool> onToggleMemory;
  final ValueChanged<String> onSelectConversation;
  final ValueChanged<String> onSubmit;
}
