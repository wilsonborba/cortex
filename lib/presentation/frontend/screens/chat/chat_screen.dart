import '../../theme/app_icons.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/file_picker.dart';
import '../../../../dal/remote/cortex_api.dart';
import '../../../../domain/services/chat_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../shell/details_panel.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';
import 'composer.dart';
import 'output_block.dart';

/// Chat screen (issue #30): new chat, temporary chat or one saved chat.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.details,
    this.sessionId,
    this.temporary = false,
    this.controller,
    this.picker,
  });
  final CortexApi api;
  final DetailsController details;
  final String? sessionId;
  final bool temporary;

  /// Injected in tests.
  final ChatController? controller;

  /// File picker; the browser dialog by default.
  final Future<List<PickedFile>> Function()? picker;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController chat =
      widget.controller ??
      ChatController(
        api: widget.api,
        sessionId: widget.sessionId,
        temporary: widget.temporary,
      );
  final _scroll = ScrollController();
  final _composer = GlobalKey<ComposerState>();
  bool _atBottom = true;
  bool _preservingScroll = false;
  int _lastLength = 0;
  String? _navigated;

  @override
  void initState() {
    super.initState();
    chat.addListener(_changed);
    _scroll.addListener(_onScroll);
    chat.open();
  }

  @override
  void dispose() {
    chat.removeListener(_changed);
    if (widget.controller == null) chat.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bottom = _scroll.position.maxScrollExtent - _scroll.offset < 48;
    if (bottom != _atBottom) setState(() => _atBottom = bottom);
    if (_scroll.offset <= 0 && chat.hasOlder) _loadOlder();
  }

  Future<void> _loadOlder() async {
    if (_preservingScroll || chat.loadingOlder || !_scroll.hasClients) return;
    _preservingScroll = true;
    final extent = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset;
    await chat.loadOlder();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.jumpTo(
          (offset + _scroll.position.maxScrollExtent - extent).clamp(
            0,
            _scroll.position.maxScrollExtent,
          ),
        );
      }
      _preservingScroll = false;
    });
  }

  void _changed() {
    // A new permanent chat gets its path once the answer is done.
    final session = chat.sessionId;
    if (widget.sessionId == null &&
        !chat.temporary &&
        session != null &&
        chat.running == null &&
        _navigated == null &&
        chat.exchanges.isNotEmpty) {
      _navigated = session;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GoRouter.maybeOf(context)?.go('/v1/chats/$session');
      });
    }
    // Follow new text only when the user is at the bottom (30.9).
    final length = chat.exchanges.fold<int>(
      0,
      (n, e) => n + e.output.answer.length + e.output.lastEventId,
    );
    if (!_preservingScroll && _atBottom && length != _lastLength) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jump());
    }
    _lastLength = length;
    setState(() {});
  }

  void _jump() {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  void _showMemories(List<(String, String)> memories) {
    widget.details.show(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, title) in memories)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: AppCard(
                onTap: () => GoRouter.maybeOf(context)?.go('/v1/memory/$id'),
                child: Text(title, style: TextStyles.compact),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _rename() async {
    final controller = TextEditingController(
      text: '${chat.chat?['title'] ?? ''}',
    );
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.rename, style: TextStyles.subsection),
        content: AppInput(
          controller: controller,
          onSubmitted: (_) => Navigator.pop(c, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (mounted && ok == true && controller.text.trim().isNotEmpty) {
      await runApiAction(context, () => chat.rename(controller.text.trim()));
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    if (await showConfirmDialog(
      context,
      title: l.deleteChatTitle,
      message: l.deleteChatMessage,
      confirm: l.delete,
      cancel: l.cancel,
      destructive: true,
    )) {
      if (!mounted) return;
      await runApiAction(context, () async {
        await chat.delete();
        if (mounted) GoRouter.maybeOf(context)?.go('/v1/chats');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final title = chat.temporary
        ? l.temporaryChat
        : '${chat.chat?['title'] ?? (chat.isNew ? l.newChat : '')}';
    return Column(
      children: [
        // Fixed while the temporary chat is open (31.2).
        if (chat.temporary)
          Container(
            key: const Key('temporary-banner'),
            padding: const EdgeInsets.symmetric(
              horizontal: Space.s16,
              vertical: Space.s8,
            ),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: NoticeLine(
              message: l.temporaryBanner,
              kind: NoticeKind.warning,
            ),
          ),
        if (chat.reconnecting)
          OfflineBanner(
            key: const Key('reconnecting'),
            message: l.reconnecting,
          ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: Space.s16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  key: const Key('chat-title'),
                  style: TextStyles.compact.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!chat.isNew && !chat.temporary) ...[
                FoundationFocus(
                  child: AppMenu<String>(
                    key: const Key('chat-actions'),
                    tooltip: l.menu,
                    icon: Icon(AppIcons.more, color: p.muted),
                    onSelected: (action) {
                      switch (action) {
                        case 'rename':
                          _rename();
                        case 'pin':
                          runApiAction(context, chat.togglePin);
                        case 'delete':
                          _delete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'rename', child: Text(l.rename)),
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(
                          chat.chat?['is_pinned'] == true ? l.unpin : l.pin,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l.delete,
                          style: TextStyle(color: p.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              if (chat.loadError != null)
                ErrorState(
                  message: apiFailure(l, chat.loadError),
                  retryLabel: l.retry,
                  onRetry: chat.open,
                )
              else if (chat.loading && chat.exchanges.isEmpty)
                const Center(child: SkeletonBox(width: 240))
              else if (chat.exchanges.isEmpty)
                _Empty(
                  onPrompt: (prompt) =>
                      _composer.currentState?.text.text = prompt,
                )
              else
                SelectionArea(
                  child: ListView.builder(
                    key: const Key('messages'),
                    controller: _scroll,
                    padding: const EdgeInsets.all(Space.s24),
                    itemCount: chat.exchanges.length,
                    itemBuilder: (_, i) {
                      final e = chat.exchanges[i];
                      return Center(
                        key: ObjectKey(e),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: Space.s32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 560,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Space.s16,
                                      vertical: Space.s12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.surface,
                                      borderRadius: BorderRadius.circular(
                                        FoundationTokens.of(
                                          context,
                                        ).groupRadius,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (e.text.isNotEmpty)
                                          Text(e.text, style: TextStyles.body),
                                        const SizedBox(height: Space.s8),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (e.createdAt != null)
                                              Flexible(
                                                child: Text(
                                                  '${MaterialLocalizations.of(context).formatMediumDate(e.createdAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(e.createdAt!.toLocal()), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
                                                  key: ValueKey(
                                                    'message-time-${e.inputId}',
                                                  ),
                                                  style: TextStyles.label
                                                      .copyWith(color: p.muted),
                                                ),
                                              ),
                                            CopyMessageButton(text: e.text),
                                          ],
                                        ),
                                        for (final f in e.files)
                                          Text(
                                            f,
                                            style: TextStyles.label.copyWith(
                                              color: p.muted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: Space.s12),
                                OutputBlock(
                                  output: e.output,
                                  onStopThinking: () =>
                                      runApiAction(context, chat.stopThinking),
                                  onMemories: _showMemories,
                                  onRetry:
                                      e.output.running ||
                                          i != chat.exchanges.length - 1
                                      ? null
                                      : () => chat.send(e.text),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (!_atBottom)
                Positioned(
                  bottom: Space.s16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ActionChip(
                      key: const Key('jump-latest'),
                      avatar: const Icon(
                        AppIcons.jumpToLatest,
                        size: IconSizes.action,
                      ),
                      label: Text(l.jumpToLatest),
                      onPressed: () {
                        _jump();
                        setState(() => _atBottom = true);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        Composer(
          key: _composer,
          chat: chat,
          picker: widget.picker ?? pickFiles,
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onPrompt});
  final ValueChanged<String> onPrompt;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.chatGreeting,
                  style: TextStyles.section,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Space.s24),
                Wrap(
                  spacing: Space.s8,
                  runSpacing: Space.s8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final prompt in [
                      l.demoMemoryPrompt,
                      l.demoFastPrompt,
                      l.demoDeepPrompt,
                      l.demoThinkPrompt,
                    ])
                      ActionChip(
                        label: Text(prompt, style: TextStyles.label),
                        onPressed: () => onPrompt(prompt),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
