import 'package:flutter/material.dart';

import '../../../../core/settings.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../domain/models/conversation.dart';
import '../../../../domain/services/chat_export_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/prompt_dock.dart';
import '../../components/scroll_to_bottom_button.dart';
import '../memory_graph_screen/memory_graph_screen.dart';
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
  static const _exportService = ChatExportService();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _exportConversation(Conversation conversation) {
    downloadTextFile(
      filename: _exportService.suggestedFilename(conversation),
      content: _exportService.buildMarkdown(conversation),
    );
  }

  void _showClearAllConfirmation() {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        title: Text(
          l10n.clearAllTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.clearAllConfirmation,
          style: TextStyle(
            fontSize: 13,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.cancel,
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
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
          if (props.selectedConversation.isEphemeral)
            IconButton(
              tooltip: l10n.exitIncognito,
              icon: const Icon(Icons.close, size: 18),
              onPressed: props.onExitIncognitoChat,
            )
          else
            IconButton(
              tooltip: l10n.startIncognito,
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              onPressed: props.onStartIncognitoChat,
            ),
          if (props.selectedConversation.messages.isNotEmpty)
            IconButton(
              tooltip: l10n.exportChatTooltip,
              icon: const Icon(Icons.download_outlined, size: 18),
              onPressed: () => _exportConversation(props.selectedConversation),
            ),
          IconButton(
            tooltip: l10n.memoryGraphTooltip,
            icon: const Icon(Icons.hub_outlined, size: 18),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MemoryGraphScreen()),
            ),
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Image.asset(
                          'lib/presentation/assets/img/logo.png',
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.hub, size: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'CORTEX',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
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
                    backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    side: BorderSide(
                      color: scheme.outline.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: scheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        l10n.newConversation,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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
                      l10n.history.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: scheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        _showClearAllConfirmation();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 13,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.clearAll,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
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
              // Conversation List with date grouping
              Expanded(
                child: _buildGroupedConversationList(context, props, scheme),
              ),
              // Build/deploy timestamp, same spot & style certifications
              // shows it in, so it's visible without opening Settings.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    'Cortex ${AppSettings.buildVersion}',
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
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
              child: props.selectedConversation.messages.isEmpty
                  ? _buildEmptyState(context, props, scheme)
                  : Stack(
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
                              final messages = props.selectedConversation.messages;
                              final message = messages[index];
                              return MessageBubble(
                                message: message,
                                onContinueGeneration: () =>
                                    props.onContinueGeneration(message.id),
                                isContinuingGeneration:
                                    props.continuingMessageId == message.id,
                                isDelivered: index < messages.length - 1 || !props.isBusy,
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
                onSendVoiceMessage: props.onSendVoiceMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedConversationList(
    BuildContext context,
    ChatScreenProps props,
    ColorScheme scheme,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = todayStart.subtract(const Duration(days: 7));

    final pinned = props.conversations.where((c) => c.isPinned).toList();
    final unpinned = props.conversations.where((c) => !c.isPinned).toList();

    final today = unpinned.where((c) => c.updatedAt.isAfter(todayStart)).toList();
    final prev7Days = unpinned
        .where((c) =>
            c.updatedAt.isBefore(todayStart) &&
            c.updatedAt.isAfter(sevenDaysAgo))
        .toList();
    final older =
        unpinned.where((c) => c.updatedAt.isBefore(sevenDaysAgo)).toList();

    Widget buildSectionHeader(String label) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: scheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    Widget buildTile(Conversation conv) {
      return ConversationTile(
        conversation: conv,
        isSelected: conv.id == props.selectedConversation.id,
        onTap: () {
          props.onSelectConversation(conv.id);
          Navigator.of(context).pop();
        },
        onRename: (newTitle) => props.onRenameConversation(conv.id, newTitle),
        onTogglePin: () => props.onTogglePinConversation(conv.id),
        onDelete: () => props.onDeleteConversation(conv.id),
      );
    }

    if (props.conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context).noConversationsYetTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      children: [
        if (pinned.isNotEmpty) ...[
          buildSectionHeader('PINNED'),
          ...pinned.map(buildTile),
        ],
        if (today.isNotEmpty) ...[
          buildSectionHeader('TODAY'),
          ...today.map(buildTile),
        ],
        if (prev7Days.isNotEmpty) ...[
          buildSectionHeader('PREVIOUS 7 DAYS'),
          ...prev7Days.map(buildTile),
        ],
        if (older.isNotEmpty) ...[
          buildSectionHeader('OLDER'),
          ...older.map(buildTile),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ChatScreenProps props,
    ColorScheme scheme,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141416) : const Color(0xFFFFFFFF);

    final l10n = AppLocalizations.of(context);
    final suggestions = [
      {
        'tag': l10n.suggestionSystemTag,
        'title': l10n.suggestionSystemTitle,
        'icon': Icons.insights_rounded,
        'prompt': l10n.suggestionSystemPrompt,
      },
      {
        'tag': l10n.suggestionArchitectureTag,
        'title': l10n.suggestionArchitectureTitle,
        'icon': Icons.account_tree_outlined,
        'prompt': l10n.suggestionArchitecturePrompt,
      },
      {
        'tag': l10n.suggestionPipelineTag,
        'title': l10n.suggestionPipelineTitle,
        'icon': Icons.terminal_rounded,
        'prompt': l10n.suggestionPipelinePrompt,
      },
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1E) : const Color(0xFFEDEDF2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.4),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'lib/presentation/assets/img/logo.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, size: 22),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'CORTEX WORKSPACE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.3,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'High-precision reasoning & neural tools.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                for (final item in suggestions)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => props.onSubmit(item['prompt']! as String),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item['icon']! as IconData,
                                size: 16,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['tag']! as String,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                      color: scheme.onSurface.withValues(alpha: 0.45),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['title']! as String,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: scheme.onSurface.withValues(alpha: 0.35),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
