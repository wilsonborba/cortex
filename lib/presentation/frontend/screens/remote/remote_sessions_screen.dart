import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_picker.dart';
import '../../../../core/utils/remote_image_picker.dart';
import '../../../../domain/models/api.dart';
import '../../../../domain/models/remote_cli.dart';
import '../../../../domain/services/remote_cli_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';

typedef RemoteImagePicker = Future<List<PickedFile>> Function();

class RemoteSessionsScreen extends StatefulWidget {
  const RemoteSessionsScreen({
    super.key,
    required this.controller,
    this.imagePicker,
  });
  final RemoteCliController controller;
  final RemoteImagePicker? imagePicker;

  @override
  State<RemoteSessionsScreen> createState() => _RemoteSessionsScreenState();
}

class _RemoteSessionsScreenState extends State<RemoteSessionsScreen> {
  final prompt = TextEditingController();
  final _promptFocus = FocusNode();
  final _turnScrollController = ScrollController();
  int _scrollInteractionGeneration = 0;
  bool selectingImage = false;

  RemoteCliController get remote => widget.controller;

  @override
  void initState() {
    super.initState();
    remote.addListener(_changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) remote.refreshSessions();
    });
  }

  @override
  void didUpdateWidget(RemoteSessionsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    remote.removeListener(_changed);
    _promptFocus.dispose();
    _turnScrollController.dispose();
    unawaited(remote.closeSession(clearSessions: true));
    prompt.dispose();
    super.dispose();
  }

  void _changed() {
    final followTail = _nearLatest;
    if (!mounted) return;
    setState(() {});
    if (followTail) _scrollToLatest();
  }

  bool get _nearLatest =>
      !_turnScrollController.hasClients ||
      _turnScrollController.position.maxScrollExtent -
              _turnScrollController.position.pixels <=
          96;

  void _scrollToLatest() {
    final interactionGeneration = _scrollInteractionGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_turnScrollController.hasClients) return;
      if (_scrollInteractionGeneration != interactionGeneration) return;
      _turnScrollController.animateTo(
        _turnScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openSession(RemoteCliSession session) async {
    await remote.openSession(session);
    _scrollToLatest();
  }

  String _errorText(AppLocalizations l) =>
      remote.failure is RemoteCliFailure &&
          (remote.failure! as RemoteCliFailure).expired
      ? l.remoteSessionExpired
      : l.remoteRequestFailed;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 850;
    final active = remote.activeSession;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 320, child: _sessionList(context, compact: true)),
          VerticalDivider(width: 1, color: Palette.from(context).divider),
          Expanded(
            child: active == null
                ? _emptyDetail(context)
                : _sessionDetail(context, active, showBack: false),
          ),
        ],
      );
    }
    return active == null
        ? _sessionList(context, compact: false)
        : _sessionDetail(context, active, showBack: true);
  }

  Widget _sessionList(BuildContext context, {required bool compact}) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? Space.s16 : Space.s20,
            Space.s16,
            compact ? Space.s8 : Space.s20,
            Space.s12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.remoteSessionsTitle,
                      style: TextStyles.subtitle1.copyWith(color: p.text),
                    ),
                    const SizedBox(height: Space.s4),
                    Text(
                      l.remoteSessionsDescription,
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l.remoteRefresh,
                onPressed: remote.loadingSessions
                    ? null
                    : remote.refreshSessions,
                icon: const Icon(AppIcons.retry),
              ),
            ],
          ),
        ),
        if (remote.failure != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s16),
            child: ErrorState(
              message: _errorText(l),
              retryLabel: l.retry,
              onRetry: remote.refreshSessions,
            ),
          ),
        if (remote.loadingSessions && remote.sessions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(Space.s16),
            child: LinearProgressIndicator(),
          ),
        if (!remote.loadingSessions && remote.sessions.isEmpty)
          Expanded(
            child: EmptyState(
              title: l.remoteNoSessionsTitle,
              message: l.remoteNoSessionsBody,
              icon: AppIcons.systemTheme,
            ),
          ),
        if (remote.sessions.isNotEmpty)
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                Space.s12,
                0,
                Space.s12,
                Space.s16,
              ),
              itemCount: remote.sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.s8),
              itemBuilder: (context, index) {
                final session = remote.sessions[index];
                final selected = remote.activeSession?.id == session.id;
                return _SessionTile(
                  session: session,
                  selected: selected,
                  onTap: () => _openSession(session),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _emptyDetail(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyState(
      title: l.remoteSelectSessionTitle,
      message: l.remoteSelectSessionBody,
      icon: AppIcons.systemTheme,
    );
  }

  Widget _sessionDetail(
    BuildContext context,
    RemoteCliSession session, {
    required bool showBack,
  }) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s16,
            Space.s12,
            Space.s16,
            Space.s8,
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  tooltip: l.remoteBackToSessions,
                  onPressed: remote.closeSession,
                  icon: const Icon(AppIcons.back),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.subtitle1.copyWith(color: p.text),
                    ),
                    Text(
                      '${session.platform} · ${l.remoteLastSeen(DateFormat.yMMMd(l.localeName).add_Hm().format(session.lastSeen.toLocal()))}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              _OnlineBadge(online: session.online),
            ],
          ),
        ),
        if (!session.online) _Notice(text: l.remoteOffline, warning: true),
        if (remote.reconnecting) _Notice(text: l.remoteReconnecting),
        if (remote.streamExpired)
          _Notice(text: l.remoteSessionExpired, warning: true),
        if (remote.failure != null && !remote.streamExpired)
          _Notice(text: _errorText(l), warning: true),
        if (remote.commandStatus != RemoteCliCommandStatus.none)
          _Notice(text: _commandStatusText(l, remote.commandStatus)),
        if (remote.turns.isEmpty)
          Expanded(
            child: EmptyState(
              title: l.remoteNoEvents,
              icon: AppIcons.systemTheme,
            ),
          )
        else
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (_) {
                _scrollInteractionGeneration++;
                return false;
              },
              child: ListView(
                key: const Key('remote-event-list'),
                controller: _turnScrollController,
                padding: const EdgeInsets.fromLTRB(
                  Space.s16,
                  Space.s8,
                  Space.s16,
                  Space.s16,
                ),
                children: [
                  for (final turn in remote.turns)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: Space.chatColumnWidth,
                        ),
                        child: _TurnCard(
                          key: ValueKey('remote-turn-${turn.key}'),
                          turn: turn,
                          controller: remote,
                          sessionId: session.id,
                          epoch: remote.operationEpoch,
                          approvalRequests: remote.approvalRequests,
                          answeringApprovals: remote.answeringApprovals,
                          answerApproval: remote.answerApproval,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        _composer(context, session),
      ],
    );
  }

  String _commandStatusText(
    AppLocalizations l,
    RemoteCliCommandStatus status,
  ) => switch (status) {
    RemoteCliCommandStatus.none => '',
    RemoteCliCommandStatus.promptSent => l.remotePromptSent,
    RemoteCliCommandStatus.promptQueuedOffline => l.remotePromptQueued,
    RemoteCliCommandStatus.commandExpired => l.remoteCommandExpired,
    RemoteCliCommandStatus.cancelPending => l.remoteCancelPending,
    RemoteCliCommandStatus.cancelled => l.remoteCancelled,
    RemoteCliCommandStatus.turnFailed => l.remoteTurnFailed,
    RemoteCliCommandStatus.turnIncomplete => l.remoteTurnIncomplete,
  };

  Widget _composer(BuildContext context, RemoteCliSession session) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final hasText = prompt.text.trim().isNotEmpty;
    final canSend =
        hasText &&
        !remote.streamExpired &&
        !remote.sendingPrompt &&
        !remote.promptAwaitingStart &&
        !remote.turnRunning;
    final canCancel = remote.turnRunning && !remote.cancelQueued;
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Space.s12,
          Space.s8,
          Space.s12,
          Space.s12,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.chatColumnWidth),
          child: Container(
            key: const Key('remote-composer-surface'),
            decoration: BoxDecoration(
              color: p.raised,
              borderRadius: BorderRadius.circular(Radii.dialog),
              border: Border.all(color: p.stroke, width: Controls.border),
              boxShadow: Shadows.shadow4(Theme.of(context).brightness),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Radii.dialog - Controls.border,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.s12,
                      vertical: Space.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (remote.attachments.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Space.s8),
                            child: Wrap(
                              spacing: Space.s8,
                              runSpacing: Space.s8,
                              children: [
                                for (final file in remote.attachments)
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 320,
                                    ),
                                    child: InputChip(
                                      avatar: const Icon(
                                        AppIcons.attach,
                                        size: IconSizes.action,
                                      ),
                                      label: Text(
                                        file.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onDeleted: () =>
                                          remote.removeAttachment(file),
                                      deleteButtonTooltipMessage: l
                                          .remoteRemoveAttachment(file.name),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        TextField(
                          key: const Key('remote-prompt'),
                          controller: prompt,
                          focusNode: _promptFocus,
                          minLines: 1,
                          maxLines: Controls.composerMaxLines,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.newline,
                          style: TextStyles.body2.copyWith(color: p.text),
                          decoration: InputDecoration(
                            hintText: l.remotePromptHint,
                            hintStyle: TextStyles.body2.copyWith(
                              color: p.muted,
                            ),
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: Space.s6,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: Theme.of(
                              context,
                            ).inputDecorationTheme.focusedBorder,
                          ),
                        ),
                        const SizedBox(height: Space.s4),
                        Row(
                          children: [
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: IconButton(
                                tooltip: l.remoteAttachImage,
                                onPressed: selectingImage ? null : _pickImages,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 44,
                                  height: 44,
                                ),
                                icon: selectingImage
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(AppIcons.attach),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: Tooltip(
                                message: remote.turnRunning
                                    ? l.remoteCancelTurn
                                    : l.remoteSendPrompt,
                                child: Semantics(
                                  button: true,
                                  enabled: canCancel || canSend,
                                  label: remote.turnRunning
                                      ? l.remoteCancelTurn
                                      : l.remoteSendPrompt,
                                  excludeSemantics: true,
                                  child: FilledButton(
                                    key: const Key('remote-send'),
                                    onPressed: canCancel
                                        ? remote.cancel
                                        : canSend
                                        ? () async {
                                            final value = prompt.text;
                                            final sessionId = session.id;
                                            final epoch = remote.operationEpoch;
                                            final sending = remote.sendPrompt(
                                              value,
                                            );
                                            _scrollToLatest();
                                            final sent = await sending;
                                            if (sent &&
                                                mounted &&
                                                prompt.text == value &&
                                                remote.isCurrentSession(
                                                  sessionId,
                                                  epoch,
                                                )) {
                                              prompt.clear();
                                              setState(() {});
                                            }
                                          }
                                        : null,
                                    style:
                                        buttonStyle(
                                          p,
                                          remote.turnRunning
                                              ? ButtonAppearance.secondary
                                              : ButtonAppearance.primary,
                                          size: ButtonSize.small,
                                        ).copyWith(
                                          minimumSize:
                                              const WidgetStatePropertyAll(
                                                Size.square(44),
                                              ),
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.zero,
                                          ),
                                        ),
                                    child:
                                        remote.sendingPrompt ||
                                            remote.promptAwaitingStart ||
                                            (remote.turnRunning &&
                                                remote.cancelQueued)
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            remote.turnRunning
                                                ? AppIcons.stop
                                                : AppIcons.send,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    final selectedSession = remote.activeSession;
    if (selectedSession == null) return;
    final epoch = remote.operationEpoch;
    setState(() => selectingImage = true);
    try {
      final selected = await (widget.imagePicker ?? pickRemoteImages)();
      for (final PickedFile file in selected) {
        if (!remote.isCurrentSession(selectedSession.id, epoch)) return;
        await remote.attachImage(
          name: file.name,
          bytes: file.bytes,
          contentType: file.contentType,
        );
      }
    } finally {
      if (mounted) setState(() => selectingImage = false);
    }
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
  });
  final RemoteCliSession session;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Material(
      color: selected ? p.selected : p.surface,
      borderRadius: BorderRadius.circular(Radii.control),
      child: InkWell(
        key: Key('remote-session-${session.id}'),
        borderRadius: BorderRadius.circular(Radii.control),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Space.s12),
          child: Row(
            children: [
              Icon(AppIcons.systemTheme, color: p.text2),
              const SizedBox(width: Space.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.body1Strong.copyWith(color: p.text),
                    ),
                    Text(
                      session.platform,
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                    Text(
                      l.remoteLastSeen(
                        DateFormat.yMMMd(
                          l.localeName,
                        ).add_Hm().format(session.lastSeen.toLocal()),
                      ),
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Space.s8),
              _OnlineBadge(online: session.online),
            ],
          ),
        ),
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({
    super.key,
    required this.turn,
    required this.controller,
    required this.sessionId,
    required this.epoch,
    required this.approvalRequests,
    required this.answeringApprovals,
    required this.answerApproval,
  });

  final RemoteCliTurn turn;
  final RemoteCliController controller;
  final String sessionId;
  final int epoch;
  final List<RemoteCliEvent> approvalRequests;
  final Set<String> answeringApprovals;
  final Future<void> Function(String, {required bool approved}) answerApproval;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final approvals = approvalRequests
        .where((event) => turn.events.any((item) => item.id == event.id))
        .toList(growable: false);
    final status = switch (turn.status) {
      RemoteCliTurnStatus.queued => l.remotePromptQueued,
      RemoteCliTurnStatus.awaitingResponse => l.remoteTurnWaiting,
      RemoteCliTurnStatus.running => l.remoteTurnRunning,
      RemoteCliTurnStatus.complete => l.remoteTurnComplete,
      RemoteCliTurnStatus.incomplete => l.remoteTurnIncomplete,
      RemoteCliTurnStatus.failed => l.remoteTurnFailed,
      RemoteCliTurnStatus.cancelled => l.remoteCancelled,
    };
    return Padding(
      key: Key('remote-turn-card-${turn.key}'),
      padding: const EdgeInsets.only(bottom: Space.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (turn.prompt.isNotEmpty) ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: LayoutBuilder(
                builder: (context, constraints) => Container(
                  key: Key('remote-user-prompt-${turn.key}'),
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * Space.userBubbleFraction,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s12,
                    vertical: Space.s8,
                  ),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(Radii.dialog),
                  ),
                  child: SelectableText(
                    turn.prompt,
                    style: TextStyles.body2.copyWith(color: p.text),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.s12),
          ],
          Row(
            children: [
              if (turn.status == RemoteCliTurnStatus.running ||
                  turn.status == RemoteCliTurnStatus.awaitingResponse)
                Padding(
                  padding: const EdgeInsets.only(right: Space.s8),
                  child: SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.muted,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: Space.s8),
                  child: Icon(
                    turn.status == RemoteCliTurnStatus.failed
                        ? AppIcons.warning
                        : AppIcons.bot,
                    size: IconSizes.action,
                    color: turn.status == RemoteCliTurnStatus.failed
                        ? p.warningForeground
                        : p.muted,
                  ),
                ),
              Flexible(
                child: Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
              ),
            ],
          ),
          for (final event in turn.events)
            if (event.kind == 'progress')
              _EventLine(
                text: _progressText(l, event),
                icon: AppIcons.activity,
              ),
          if (turn.answer.isNotEmpty) ...[
            const SizedBox(height: Space.s8),
            SelectableText(
              turn.answer,
              style: TextStyles.body1.copyWith(color: p.text),
            ),
          ],
          for (final event in turn.events.where(
            (event) => event.kind == 'artifact',
          ))
            _ArtifactPreview(
              key: ValueKey('remote-artifact-$sessionId-${event.id}'),
              event: event,
              controller: controller,
              sessionId: sessionId,
              epoch: epoch,
            ),
          for (final event in approvals)
            _ApprovalCard(
              event: event,
              busy: answeringApprovals.contains(
                '${event.payload['approval_id']}',
              ),
              onAnswer: (approved) => answerApproval(
                '${event.payload['approval_id']}',
                approved: approved,
              ),
            ),
        ],
      ),
    );
  }

  String _progressText(AppLocalizations l, RemoteCliEvent event) {
    final payload = event.payload;
    final message = payload['message'];
    if (message is String && message.isNotEmpty) return message;
    final status = payload['status'];
    if (status is String) {
      switch (status) {
        case 'command_received':
          return l.remoteProgressCommandReceived;
        case 'cancelled':
          return l.remoteProgressActionCancelled;
        case 'cancel_requested':
          return l.remoteProgressCancelRequested;
        case 'cancel_failed':
          return l.remoteProgressCancelFailed;
        case 'cancel_pending':
          return l.remoteProgressCancelPending;
      }
    }
    for (final key in ['stage', 'step', 'event']) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) return value;
    }
    final notice = payload['notice_number'];
    if (notice is int) return l.remoteTurnProgressNotice(notice);
    return '';
  }
}

class _ArtifactPreview extends StatefulWidget {
  const _ArtifactPreview({
    super.key,
    required this.event,
    required this.controller,
    required this.sessionId,
    required this.epoch,
  });

  final RemoteCliEvent event;
  final RemoteCliController controller;
  final String sessionId;
  final int epoch;

  @override
  State<_ArtifactPreview> createState() => _ArtifactPreviewState();
}

class _ArtifactPreviewState extends State<_ArtifactPreview> {
  bool _expanded = false;
  bool _loading = false;
  bool _unavailable = false;
  bool _tooLarge = false;
  bool _notImage = false;
  Object? _error;
  Uint8List? _bytes;

  String get _fileId => '${widget.event.payload['file_id'] ?? ''}';
  String get _name => '${widget.event.payload['name'] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(AppIcons.file),
          title: Text(l.remoteArtifact(_name)),
          trailing: _fileId.isEmpty
              ? ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    l.remoteArtifactMissingFile,
                    style: TextStyles.caption1.copyWith(color: p.muted),
                  ),
                )
              : MediaQuery.sizeOf(context).width < 600
              ? IconButton(
                  key: Key('remote-artifact-preview-$_fileId'),
                  tooltip: l.remoteArtifactPreview,
                  onPressed: _loading ? null : _togglePreview,
                  icon: Icon(_expanded ? AppIcons.collapse : AppIcons.expand),
                )
              : TextButton.icon(
                  key: Key('remote-artifact-preview-$_fileId'),
                  onPressed: _loading ? null : _togglePreview,
                  icon: Icon(_expanded ? AppIcons.collapse : AppIcons.expand),
                  label: Text(l.remoteArtifactPreview),
                ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s8),
            child: _previewBody(context),
          ),
      ],
    );
  }

  Widget _previewBody(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_unavailable) return Text(l.remoteArtifactExpired);
    if (_tooLarge) return Text(l.remoteArtifactTooLarge);
    if (_notImage) return Text(l.remoteArtifactNotImage);
    if (_error != null) return Text(l.remoteRequestFailed);
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.control),
            child: Image.memory(
              bytes,
              key: Key('remote-artifact-image-$_fileId'),
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Padding(
                padding: const EdgeInsets.all(Space.s12),
                child: Text(l.remoteArtifactNotImage),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: l.remoteArtifactExpand,
          onPressed: () => _showExpanded(context, bytes),
          icon: Icon(AppIcons.fit, color: p.text2),
        ),
      ],
    );
  }

  Future<void> _togglePreview() async {
    if (_expanded) {
      setState(() {
        _expanded = false;
        _bytes = null;
      });
      return;
    }
    setState(() => _expanded = true);
    if (_bytes != null || _loading || _unavailable || _notImage || _tooLarge) {
      return;
    }
    setState(() => _loading = true);
    try {
      final content = await widget.controller.artifactImage(
        _fileId,
        sessionId: widget.sessionId,
        epoch: widget.epoch,
      );
      if (!mounted) return;
      if (content == null) {
        setState(() => _unavailable = true);
        return;
      }
      final signature = _imageType(content.bytes);
      if (signature == null || signature != content.contentType) {
        setState(() => _notImage = true);
        return;
      }
      setState(() => _bytes = Uint8List.fromList(content.bytes));
    } catch (error) {
      if (!mounted) return;
      if (error is ApiError &&
          (error.status == 404 || error.status == 401 || error.status == 403)) {
        setState(() => _unavailable = true);
      } else if (error is ApiError && error.status == 413) {
        setState(() => _tooLarge = true);
      } else {
        setState(() => _error = error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _imageType(List<int> bytes) {
    bool starts(List<int> prefix) =>
        bytes.length >= prefix.length &&
        List<int>.generate(prefix.length, (index) => bytes[index]).toString() ==
            prefix.toString();
    if (starts(const [137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
    if (starts(const [255, 216, 255])) return 'image/jpeg';
    if (starts(const [71, 73, 70, 56, 55, 97]) ||
        starts(const [71, 73, 70, 56, 57, 97])) {
      return 'image/gif';
    }
    return bytes.length >= 12 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP'
        ? 'image/webp'
        : null;
  }

  void _showExpanded(BuildContext context, Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(Space.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(AppIcons.close),
                ),
              ),
              Flexible(
                child: InteractiveViewer(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Text(
                      AppLocalizations.of(context).remoteArtifactNotImage,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.online});
  final bool online;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final color = online ? p.successForeground : p.muted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s8,
        vertical: Space.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(Radii.circular),
      ),
      child: Text(
        online ? l.remoteOnline : l.remoteOffline,
        style: TextStyles.caption1Strong.copyWith(color: color),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.warning = false});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final color = warning ? p.warningForeground : p.text2;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Space.s16,
        vertical: Space.s4,
      ),
      padding: const EdgeInsets.all(Space.s8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Text(text, style: TextStyles.caption1.copyWith(color: color)),
    );
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: IconSizes.action, color: p.muted),
          const SizedBox(width: Space.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyles.caption1.copyWith(color: p.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.event,
    required this.busy,
    required this.onAnswer,
  });
  final RemoteCliEvent event;
  final bool busy;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final detail =
        event.payload['description'] ?? event.payload['action'] ?? '';
    return Card(
      margin: const EdgeInsets.only(top: Space.s8),
      color: p.surface,
      child: Padding(
        padding: const EdgeInsets.all(Space.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$detail'.isEmpty ? l.remoteApprovalDescription : '$detail',
              style: TextStyles.body2.copyWith(color: p.text),
            ),
            const SizedBox(height: Space.s8),
            Wrap(
              spacing: Space.s8,
              children: [
                AppButton.primary(
                  label: l.remoteApprove,
                  onPressed: busy ? null : () => onAnswer(true),
                ),
                AppButton(
                  label: l.remoteDeny,
                  kind: ButtonKind.secondary,
                  onPressed: busy ? null : () => onAnswer(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
