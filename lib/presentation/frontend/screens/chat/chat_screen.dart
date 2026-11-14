import '../../theme/app_icons.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
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
    this.now,
  });
  final CortexApi api;
  final DetailsController details;
  final String? sessionId;
  final bool temporary;
  final DateTime Function()? now;

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
  final _title = TextEditingController();
  bool _editing = false;
  final _composer = GlobalKey<ComposerState>();
  bool _atBottom = true;
  bool _loadingOlder = false;
  final _newerSliver = GlobalKey();
  Exchange? _firstPageFirst;
  int _lastLength = 0;
  double? _viewportDimension;
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
    _title.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final bottom = _scroll.position.maxScrollExtent - _scroll.offset < 48;
    if (bottom != _atBottom) setState(() => _atBottom = bottom);
    if (_scroll.offset <= _scroll.position.minScrollExtent + Space.s48 &&
        chat.hasOlder) {
      _loadOlder();
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || chat.loadingOlder || !_scroll.hasClients) return;
    _loadingOlder = true;
    try {
      await chat.loadOlder();
    } finally {
      _loadingOlder = false;
    }
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
    if (chat.exchanges.isNotEmpty &&
        (_firstPageFirst == null ||
            !chat.exchanges.contains(_firstPageFirst))) {
      _firstPageFirst = chat.exchanges.first;
    }
    // Follow new text only when the user is at the bottom (30.9).
    final length = chat.exchanges.fold<int>(
      0,
      (n, e) => n + e.output.answer.length + e.output.lastEventId,
    );
    if (!_loadingOlder && _atBottom && length != _lastLength) {
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
                onTap: () =>
                    GoRouter.maybeOf(context)?.go('/v1/settings/memory/$id'),
                child: Text(title, style: TextStyles.body1),
              ),
            ),
        ],
      ),
    );
  }

  /// Rename in place in the header (#63): Enter saves, Escape cancels.
  void _rename() {
    _title.text = '${chat.chat?['title'] ?? ''}';
    _title.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _title.text.length,
    );
    setState(() => _editing = true);
  }

  Future<void> _saveTitle() async {
    final value = _title.text.trim();
    setState(() => _editing = false);
    if (value.isEmpty || value == '${chat.chat?['title'] ?? ''}') return;
    await runApiAction(context, () => chat.rename(value));
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

  int get _olderCount {
    final index = chat.exchanges.indexOf(_firstPageFirst!);
    return index < 0 ? 0 : index;
  }

  Widget _exchange(Exchange e, int index) {
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    return Padding(
      key: ValueKey('exchange-${e.inputId ?? e.output.outputId ?? index}'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Space.s16 : Space.s24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.chatColumnWidth),
          child: Padding(
            // Message gap 24 (#63).
            padding: EdgeInsets.only(
              top: e == _firstPageFirst || index == 0 ? Space.s24 : 0,
              bottom: index == _olderCount - 1 ? Space.s8 : Space.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UserMessage(exchange: e, compact: compact),
                const SizedBox(height: Space.s24),
                OutputBlock(
                  output: e.output,
                  now: widget.now,
                  onStopThinking: () =>
                      runApiAction(context, chat.stopThinking),
                  onMemories: _showMemories,
                  onRetry:
                      e.output.running || index != chat.exchanges.length - 1
                      ? null
                      : () => chat.send(e.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
        if (chat.reconnecting)
          OfflineBanner(
            key: const Key('reconnecting'),
            message: l.reconnecting,
          ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: Space.s16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.divider)),
          ),
          child: Row(
            children: [
              if (chat.temporary) ...[
                const Icon(AppIcons.temporaryChat, size: IconSizes.action),
                const SizedBox(width: Space.s8),
              ],
              Expanded(
                child: _editing
                    ? CallbackShortcuts(
                        bindings: {
                          const SingleActivator(
                            LogicalKeyboardKey.escape,
                          ): () =>
                              setState(() => _editing = false),
                        },
                        child: AppInput(
                          key: const Key('rename-title'),
                          controller: _title,
                          autofocus: true,
                          label: l.rename,
                          onSubmitted: (_) => _saveTitle(),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            key: const Key('chat-title'),
                            style: TextStyles.subtitle1.copyWith(color: p.text),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
              ),
              if (chat.chat?['memory_node_id'] case final String nodeId)
                IconButton(
                  key: const Key('show-in-memory-graph'),
                  tooltip: l.showInGraph,
                  onPressed: () => GoRouter.maybeOf(
                    context,
                  )?.go('/v1/settings/memory/${Uri.encodeComponent(nodeId)}'),
                  icon: const Icon(AppIcons.memory, size: IconSizes.action),
                ),
              if (!chat.isNew && !chat.temporary) ...[
                IconButton(
                  key: const Key('pin-chat'),
                  tooltip: chat.chat?['is_pinned'] == true ? l.unpin : l.pin,
                  isSelected: chat.chat?['is_pinned'] == true,
                  onPressed: () => runApiAction(context, chat.togglePin),
                  icon: Icon(
                    chat.chat?['is_pinned'] == true
                        ? AppIcons.pinSelected
                        : AppIcons.pin,
                    size: IconSizes.action,
                  ),
                ),
                FoundationFocus(
                  child: AppMenu<String>(
                    key: const Key('chat-actions'),
                    tooltip: l.menu,
                    icon: Icon(AppIcons.more, color: p.muted),
                    onSelected: (action) {
                      switch (action) {
                        case 'rename':
                          _rename();
                        case 'delete':
                          _delete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'rename', child: Text(l.rename)),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          l.delete,
                          style: TextStyle(color: p.dangerForeground),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Fixed at the top of the transcript while the temporary chat is open
        // (31.2, #63).
        if (chat.temporary)
          Padding(
            key: const Key('temporary-banner'),
            padding: const EdgeInsets.fromLTRB(
              Space.s16,
              Space.s8,
              Space.s16,
              0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Space.chatColumnWidth,
                ),
                child: NoticeLine(message: l.temporaryBanner),
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, limits) {
              double textHeight(String value, TextStyle style) {
                final painter =
                    TextPainter(
                      text: TextSpan(text: value, style: style),
                      maxLines: 1,
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                    )..layout(
                      maxWidth: (limits.maxWidth - Space.s32).clamp(
                        0,
                        double.infinity,
                      ),
                    );
                final height = painter.height;
                painter.dispose();
                return height;
              }

              // AI note under the composer (#64): one line; hidden at compact
              // width after the first message.
              final compactWidth =
                  SizeClass.of(MediaQuery.sizeOf(context).width) ==
                  SizeClass.compact;
              final showNote = !(compactWidth && chat.exchanges.isNotEmpty);
              final footerHeight = showNote
                  ? textHeight(l.aiNote, TextStyles.caption1) + Space.s8
                  : 0.0;
              final readingLine = textHeight(' ', TextStyles.body2);
              final composerMaxHeight =
                  (limits.maxHeight - footerHeight - readingLine)
                      .clamp(0, double.infinity)
                      .toDouble();
              return Column(
                children: [
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
                            child:
                                NotificationListener<ScrollMetricsNotification>(
                                  onNotification: (notification) {
                                    final changed =
                                        _viewportDimension !=
                                        notification.metrics.viewportDimension;
                                    _viewportDimension =
                                        notification.metrics.viewportDimension;
                                    if (changed && _atBottom) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            if (mounted && _atBottom) _jump();
                                          });
                                    }
                                    return false;
                                  },
                                  child: CustomScrollView(
                                    key: const Key('messages'),
                                    controller: _scroll,
                                    center: _newerSliver,
                                    slivers: [
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => _exchange(
                                            chat.exchanges[_olderCount -
                                                1 -
                                                index],
                                            _olderCount - 1 - index,
                                          ),
                                          childCount: _olderCount,
                                        ),
                                      ),
                                      SliverList(
                                        key: _newerSliver,
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) => _exchange(
                                            chat.exchanges[_olderCount + index],
                                            _olderCount + index,
                                          ),
                                          childCount:
                                              chat.exchanges.length -
                                              _olderCount,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                        if (!_atBottom)
                          Positioned(
                            bottom: Space.s16,
                            left: 0,
                            right: 0,
                            // Secondary icon button 32, circular, shadow8 (#63).
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: Shadows.shadow8(
                                    Theme.of(context).brightness,
                                  ),
                                ),
                                child: IconButton(
                                  key: const Key('jump-latest'),
                                  tooltip: l.jumpToLatest,
                                  style: IconButton.styleFrom(
                                    fixedSize: const Size.square(Space.s32),
                                    minimumSize: const Size.square(Space.s32),
                                    padding: EdgeInsets.zero,
                                    backgroundColor: p.background,
                                    side: BorderSide(color: p.stroke),
                                    shape: const CircleBorder(),
                                  ),
                                  icon: const Icon(
                                    AppIcons.jumpToLatest,
                                    size: IconSizes.action,
                                  ),
                                  onPressed: () {
                                    _jump();
                                    setState(() => _atBottom = true);
                                  },
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: composerMaxHeight),
                    child: Composer(
                      key: _composer,
                      chat: chat,
                      picker: widget.picker ?? pickFiles,
                    ),
                  ),
                  if (showNote)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Space.s16,
                        right: Space.s16,
                        bottom: Space.s8,
                      ),
                      child: Text(
                        l.aiNote,
                        key: const Key('composer-ai-note'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.caption1.copyWith(color: p.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            },
          ),
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
            constraints: const BoxConstraints(maxWidth: Space.chatColumnWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.chatGreeting,
                  style: TextStyles.title3,
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
                      OutlinedButton(
                        style: const ButtonStyle(
                          padding: WidgetStatePropertyAll(
                            EdgeInsets.all(Space.s12),
                          ),
                        ),
                        onPressed: () => onPrompt(prompt),
                        child: Text(prompt, textAlign: TextAlign.start),
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

/// User message (#63, Fluent Copilot "user message"): bubble on the right,
/// at most 80 percent wide, `surface`, radius 8, padding 8 x 12, `body2`.
/// The time (`caption1` `muted`) and Copy are under the bubble on the right;
/// they show on hover and focus, and always at compact width or without a
/// mouse.
class _UserMessage extends StatefulWidget {
  const _UserMessage({required this.exchange, required this.compact});
  final Exchange exchange;
  final bool compact;
  @override
  State<_UserMessage> createState() => _UserMessageState();
}

class _UserMessageState extends State<_UserMessage> {
  bool hovered = false, focused = false, touch = false;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final e = widget.exchange;
    final visible =
        widget.compact ||
        hovered ||
        focused ||
        touch ||
        !RendererBinding.instance.mouseTracker.mouseIsConnected;
    return MouseRegion(
      onEnter: (_) => setState(() {
        hovered = true;
        touch = false;
      }),
      onExit: (_) => setState(() => hovered = false),
      child: Listener(
        onPointerDown: (event) {
          if (event.kind == PointerDeviceKind.touch) {
            setState(() => touch = true);
          }
        },
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onFocusChange: (value) => setState(() => focused = value),
          child: LayoutBuilder(
            builder: (context, box) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: box.maxWidth * Space.userBubbleFraction,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s12,
                    vertical: Space.s8,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(Radii.dialog),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.text.isNotEmpty)
                        Text(
                          e.text,
                          style: TextStyles.body2.copyWith(color: p.text),
                        ),
                      for (final file in e.files)
                        Text(
                          file,
                          style: TextStyles.caption1.copyWith(color: p.muted),
                        ),
                    ],
                  ),
                ),
                Visibility(
                  visible: visible,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Padding(
                    padding: const EdgeInsets.only(top: Space.s4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (e.createdAt != null)
                          Flexible(
                            child: Text(
                              '${MaterialLocalizations.of(context).formatMediumDate(e.createdAt!.toLocal())} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(e.createdAt!.toLocal()), alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context))}',
                              key: ValueKey('message-time-${e.inputId}'),
                              style: TextStyles.caption1.copyWith(
                                color: p.muted,
                              ),
                            ),
                          ),
                        const SizedBox(width: Space.s4),
                        SelectionContainer.disabled(
                          child: CopyMessageButton(text: e.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
