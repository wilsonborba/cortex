import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import '../../theme/app_icons.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/services/chat_list_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';

String relativeTime(AppLocalizations l, String? iso, DateTime now) {
  final time = iso == null ? null : DateTime.tryParse(iso);
  if (time == null) return '';
  final d = now.difference(time.toLocal());
  if (d.inMinutes < 1) return l.justNow;
  if (d.inHours < 1) return l.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return l.hoursAgo(d.inHours);
  return l.daysAgo(d.inDays);
}

enum _Action { pin, rename, delete }

/// Rows in the API order (31.1): title, relative time, running indicator;
/// pin, rename and delete in a context menu.
class ChatList extends StatefulWidget {
  const ChatList({
    super.key,
    required this.controller,
    required this.location,
    this.now,
  });
  final ChatListController controller;
  final String location;
  final DateTime Function()? now;
  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  ChatListController get list => widget.controller;

  @override
  void initState() {
    super.initState();
    list.addListener(_changed);
    list.refresh();
  }

  @override
  void didUpdateWidget(ChatList old) {
    super.didUpdateWidget(old);
    // A new path can mean a new, renamed or deleted chat.
    if (old.location != widget.location) list.refresh();
  }

  @override
  void dispose() {
    list.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  Future<void> _act(_Action action, Map<String, dynamic> chat) async {
    final l = AppLocalizations.of(context);
    final id = '${chat['session_id']}';
    switch (action) {
      case _Action.pin:
        await runApiAction(context, () => list.togglePin(chat));
      case _Action.rename:
        final field = TextEditingController(text: '${chat['title']}');
        final ok = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(l.rename, style: TextStyles.subsection),
            content: AppInput(
              controller: field,
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
        if (ok == true && field.text.trim().isNotEmpty) {
          if (mounted) {
            await runApiAction(
              context,
              () => list.rename(id, field.text.trim()),
            );
          }
        }
      case _Action.delete:
        if (!mounted) return;
        if (!await showConfirmDialog(
          context,
          title: l.deleteChatTitle,
          message: l.deleteChatMessage,
          confirm: l.delete,
          cancel: l.cancel,
          destructive: true,
        )) {
          return;
        }
        await _delete(id);
    }
  }

  Future<void> _delete(String id) async {
    final l = AppLocalizations.of(context);
    final error = await list.delete(id);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(apiFailure(l, error)),
          action: SnackBarAction(label: l.retry, onPressed: () => _delete(id)),
        ),
      );
    } else if (widget.location.startsWith('/v1/chats/$id')) {
      GoRouter.maybeOf(context)?.go('/v1/chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final now = (widget.now ?? DateTime.now)();
    if (list.error != null && list.chats.isEmpty) {
      return ErrorState(
        message: apiFailure(l, list.error),
        retryLabel: l.retry,
        onRetry: list.refresh,
      );
    }
    if (list.chats.isEmpty) {
      return list.loading
          ? const Center(child: SkeletonBox(width: 160))
          : EmptyState(title: l.noChatsYet, icon: AppIcons.chats);
    }
    return ListView.builder(
      key: const Key('chat-list'),
      itemCount: list.chats.length + (list.error == null ? 0 : 1),
      itemBuilder: (_, i) {
        if (list.error != null) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.all(Space.s12),
              child: ErrorState(
                message: apiFailure(l, list.error),
                retryLabel: l.retry,
                onRetry: list.refresh,
              ),
            );
          }
          i--;
        }
        final chat = list.chats[i];
        final id = '${chat['session_id']}';
        final selected = widget.location.startsWith('/v1/chats/$id');
        return _HistoryRow(
          builder: (showActions) => FoundationFocus(
            child: ListTile(
              key: Key('chat-$id'),
              dense: true,
              selected: selected,
              selectedTileColor: p.raised,
              shape: Border(
                left: BorderSide(
                  color: selected ? p.brandForeground1 : Colors.transparent,
                  width: Controls.focusRing,
                ),
              ),
              leading: chat['is_pinned'] == true
                  ? Icon(AppIcons.pin, size: IconSizes.chip, color: p.muted)
                  : null,
              title: Text(
                '${chat['title']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.compact.copyWith(color: p.text),
              ),
              subtitle: Row(
                children: [
                  if (list.running.contains(id)) ...[
                    Semantics(
                      label: l.running,
                      child: Container(
                        key: Key('running-$id'),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: p.text,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: Space.s4),
                  ],
                  Text(
                    relativeTime(l, chat['updated_at'] as String?, now),
                    style: TextStyles.label.copyWith(color: p.muted),
                  ),
                ],
              ),
              onTap: () => GoRouter.maybeOf(context)?.go('/v1/chats/$id'),
              trailing: Visibility(
                visible: showActions,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: FoundationFocus(
                  child: AppMenu<_Action>(
                    key: Key('menu-$id'),
                    tooltip: l.chatActions,
                    icon: const Icon(AppIcons.more, size: IconSizes.action),
                    onSelected: (a) => _act(a, chat),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _Action.pin,
                        child: Text(
                          chat['is_pinned'] == true ? l.unpin : l.pin,
                        ),
                      ),
                      PopupMenuItem(
                        value: _Action.rename,
                        child: Text(l.rename),
                      ),
                      PopupMenuItem(
                        value: _Action.delete,
                        child: Text(
                          l.delete,
                          style: TextStyle(color: p.dangerForeground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatefulWidget {
  const _HistoryRow({required this.builder});
  final Widget Function(bool showActions) builder;
  @override
  State<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends State<_HistoryRow> {
  bool hovered = false, focused = false, touch = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() {
      hovered = true;
      touch = false;
    }),
    onExit: (_) => setState(() => hovered = false),
    child: Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.touch) setState(() => touch = true);
      },
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (value) => setState(() => focused = value),
        child: widget.builder(
          hovered ||
              focused ||
              touch ||
              !RendererBinding.instance.mouseTracker.mouseIsConnected,
        ),
      ),
    ),
  );
}
