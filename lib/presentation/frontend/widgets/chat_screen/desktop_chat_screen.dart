import 'package:flutter/material.dart';

import '../../../../domain/models/conversation.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_settings_sheet.dart';
import '../../components/conversation_tile.dart';
import '../../components/message_bubble.dart';
import '../../components/prompt_dock.dart';
import '../../components/scroll_to_bottom_button.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scroll.maybeAutoScroll(),
    );
    final props = widget.props;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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
                                tooltip: 'Collapse Sidebar',
                                icon: const Icon(Icons.keyboard_double_arrow_left_rounded, size: 18),
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
                                Expanded(
                                  child: Text(
                                    l10n.newConversation,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.onSurface.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '⌘N',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface.withValues(alpha: 0.5),
                                    ),
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
                                l10n.history.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: scheme.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                              InkWell(
                                onTap: _showClearAllConfirmation,
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
                        // User Profile Footer
                        Container(
                          padding: const EdgeInsets.all(12),
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
                                radius: 15,
                                backgroundColor: scheme.onSurface.withValues(alpha: 0.12),
                                child: Text(
                                  'W',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                                      'PRO ACCOUNT',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: scheme.onSurface.withValues(alpha: 0.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Settings',
                                icon: const Icon(Icons.settings_outlined, size: 17),
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
                      color: scheme.surface,
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
                            icon: const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18),
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
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: scheme.onSurface.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      'TIER 0',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                        color: scheme.onSurface.withValues(alpha: 0.65),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (props.selectedConversation.isEphemeral) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off_outlined,
                                  size: 13,
                                  color: scheme.onSurface.withValues(alpha: 0.8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.incognitoBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: props.onExitIncognitoChat,
                            icon: const Icon(Icons.close, size: 13),
                            label: Text(
                              l10n.exitIncognito,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ] else
                          IconButton(
                            tooltip: l10n.startIncognito,
                            icon: const Icon(Icons.visibility_off_outlined, size: 18),
                            onPressed: props.onStartIncognitoChat,
                          ),
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
                          onSendVoiceMessage: props.onSendVoiceMessage,
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
        onTap: () => props.onSelectConversation(conv.id),
        onRename: (newTitle) => props.onRenameConversation(conv.id, newTitle),
        onTogglePin: () => props.onTogglePinConversation(conv.id),
        onDelete: () => props.onDeleteConversation(conv.id),
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

    final suggestions = [
      {
        'tag': 'SYSTEM ANALYSIS',
        'title': 'Analyze system telemetry & bottlenecks',
        'subtitle': 'Identify latency bottlenecks and profile memory usage.',
        'icon': Icons.insights_rounded,
        'prompt': 'Analyze current system metrics and identify memory/latency bottlenecks.',
      },
      {
        'tag': 'ARCHITECTURE',
        'title': 'Explore distributed architecture tradeoffs',
        'subtitle': 'Compare streaming facades against batch execution models.',
        'icon': Icons.account_tree_outlined,
        'prompt': 'Explain the architectural tradeoffs between token streaming facades vs RPC execute.',
      },
      {
        'tag': 'PIPELINE CODE',
        'title': 'Draft an asynchronous API gateway',
        'subtitle': 'Build a resilient service with streaming SSE & health guards.',
        'icon': Icons.terminal_rounded,
        'prompt': 'Write a Python FastAPI service connecting to an isolated AI gateway with health checks.',
      },
    ];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
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
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.hub_rounded, size: 26),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'CORTEX WORKSPACE',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How can I help you today?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'High-precision reasoning, persistent context, and neural tools.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  for (final item in suggestions)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => props.onSubmit(item['prompt']! as String),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item['icon']! as IconData,
                                  size: 18,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          item['tag']! as String,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: scheme.onSurface.withValues(alpha: 0.45),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['title']! as String,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['subtitle']! as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurface.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: scheme.onSurface.withValues(alpha: 0.35),
                              ),
                            ],
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
