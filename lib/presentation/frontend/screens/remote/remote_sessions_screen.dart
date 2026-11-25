import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/file_picker.dart';
import '../../../../core/utils/remote_image_picker.dart';
import '../../../../domain/models/remote_cli.dart';
import '../../../../domain/services/remote_cli_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
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
    unawaited(remote.closeSession(clearSessions: true));
    prompt.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
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
                  onTap: () => remote.openSession(session),
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
    final answer = remote.answerText;
    final running = remote.turnRunning;
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
        if (running && !remote.cancelQueued)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s16),
              child: AppButton(
                label: l.remoteCancelTurn,
                kind: ButtonKind.secondary,
                icon: AppIcons.close,
                onPressed: () => remote.cancel(),
              ),
            ),
          ),
        if (remote.events.isEmpty)
          Expanded(
            child: EmptyState(
              title: l.remoteNoEvents,
              icon: AppIcons.systemTheme,
            ),
          )
        else
          Expanded(
            child: ListView(
              key: const Key('remote-event-list'),
              padding: const EdgeInsets.fromLTRB(
                Space.s16,
                Space.s8,
                Space.s16,
                Space.s16,
              ),
              children: [
                for (final event in remote.events)
                  if (event.kind == 'progress')
                    _EventLine(
                      title: l.remoteProgress,
                      text:
                          '${event.payload['message'] ?? event.payload['event'] ?? ''}',
                      icon: AppIcons.activity,
                    ),
                if (answer.isNotEmpty) ...[
                  const SizedBox(height: Space.s12),
                  Text(
                    l.remoteAnswer,
                    style: TextStyles.body1Strong.copyWith(color: p.text),
                  ),
                  const SizedBox(height: Space.s4),
                  SelectableText(
                    answer,
                    style: TextStyles.body1.copyWith(color: p.text),
                  ),
                ],
                for (final event in remote.events.where(
                  (event) => event.kind == 'artifact',
                ))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(AppIcons.file),
                    title: Text(
                      l.remoteArtifact('${event.payload['name'] ?? ''}'),
                    ),
                  ),
                const SizedBox(height: Space.s16),
                _approvals(context),
              ],
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
  };

  Widget _approvals(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final pending = remote.approvalRequests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.remoteApprovals,
          style: TextStyles.body1Strong.copyWith(color: p.text),
        ),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Space.s8),
            child: Text(
              l.remoteNoApprovals,
              style: TextStyles.caption1.copyWith(color: p.muted),
            ),
          ),
        for (final event in pending)
          _ApprovalCard(
            event: event,
            busy: remote.answeringApprovals.contains(
              '${event.payload['approval_id']}',
            ),
            onAnswer: (approved) => remote.answerApproval(
              '${event.payload['approval_id']}',
              approved: approved,
            ),
          ),
      ],
    );
  }

  Widget _composer(BuildContext context, RemoteCliSession session) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final hasText = prompt.text.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.s12,
        Space.s8,
        Space.s12,
        Space.s12,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (remote.attachments.isNotEmpty)
              Wrap(
                spacing: Space.s8,
                runSpacing: Space.s4,
                children: [
                  for (final file in remote.attachments)
                    InputChip(
                      avatar: const Icon(
                        AppIcons.attach,
                        size: IconSizes.action,
                      ),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onDeleted: () => remote.removeAttachment(file),
                      deleteButtonTooltipMessage: l.remoteRemoveAttachment(
                        file.name,
                      ),
                    ),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: l.remoteAttachImage,
                  onPressed: selectingImage ? null : _pickImages,
                  icon: selectingImage
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.attach),
                ),
                Expanded(
                  child: TextField(
                    key: const Key('remote-prompt'),
                    controller: prompt,
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: l.remotePromptHint,
                      filled: true,
                      fillColor: p.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.control),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.s8),
                AppButton.primary(
                  key: const Key('remote-send'),
                  label: l.remoteSendPrompt,
                  icon: AppIcons.send,
                  onPressed:
                      hasText && !remote.streamExpired && !remote.sendingPrompt
                      ? () async {
                          final text = prompt.text;
                          final sessionId = session.id;
                          final epoch = remote.operationEpoch;
                          final sent = await remote.sendPrompt(text);
                          if (sent &&
                              mounted &&
                              prompt.text == text &&
                              remote.isCurrentSession(sessionId, epoch)) {
                            prompt.clear();
                            setState(() {});
                          }
                        }
                      : null,
                ),
              ],
            ),
            if (!session.online)
              Padding(
                padding: const EdgeInsets.only(top: Space.s4, left: Space.s48),
                child: Text(
                  l.remoteOffline,
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
              ),
          ],
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
  const _EventLine({
    required this.title,
    required this.text,
    required this.icon,
  });
  final String title;
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
                Text(
                  title,
                  style: TextStyles.caption1Strong.copyWith(color: p.text2),
                ),
                Text(text, style: TextStyles.body2.copyWith(color: p.text)),
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
