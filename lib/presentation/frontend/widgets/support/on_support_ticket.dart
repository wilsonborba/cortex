import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/models/support_ticket.dart';
import '../../../../domain/services/attachment_service.dart';
import '../../../../domain/services/support_api_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_theme.dart';
import '../../components/file_icons.dart';

/// One ticket's continuous message thread (ported from `certifications/lib/
/// presentation/widgets/support/on_support_ticket.dart`): reply, attach an
/// image, see basic stats (status, message count, created date). Marks the
/// ticket read as soon as it opens. Restyled to Cortex's dark monochrome
/// glass aesthetic.
class SupportTicketScreen extends StatefulWidget {
  const SupportTicketScreen({super.key, required this.ticketId});
  final String ticketId;

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> {
  final _api = SupportApiService();
  final _attachmentService = const AttachmentService();
  final _bodyController = TextEditingController();
  late Future<SupportTicketDetail> _future = _load();
  bool _sending = false;
  ({String name, List<int> bytes, String mimeType})? _pendingAttachment;
  String? _error;

  Future<SupportTicketDetail> _load() async {
    final detail = await _api.getTicket(widget.ticketId);
    // Best-effort: not marking read should never block viewing the thread.
    unawaited(_api.markTicketRead(widget.ticketId).catchError((_) {}));
    return detail;
  }

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    final picked = await _attachmentService.pickImages();
    if (picked.isEmpty) return;
    final attachment = picked.first;
    setState(() {
      _pendingAttachment = (
        name: attachment.filename,
        bytes: attachment.bytes,
        mimeType: attachment.mimeType,
      );
    });
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      String? attachmentReference;
      final attachment = _pendingAttachment;
      if (attachment != null) {
        attachmentReference = await _api.uploadAttachment(
          filename: attachment.name,
          bytes: attachment.bytes,
          mimeType: attachment.mimeType,
        );
      }
      await _api.postMessage(widget.ticketId, body: body, attachmentReference: attachmentReference);
      _bodyController.clear();
      if (!mounted) return;
      setState(() {
        _pendingAttachment = null;
        _future = _load();
      });
    } catch (_) {
      if (mounted) setState(() => _error = l10n.ticketActionFailedMessage);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTicketDetailTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: FutureBuilder<SupportTicketDetail>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorLoadingTicketsMessage));
                }
                final ticket = snapshot.data!;
                return Column(
                  children: [
                    _TicketStatsHeader(ticket: ticket),
                    if (!ticket.messagesAvailable)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: const _ThreadUnavailableBanner(),
                      ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: ticket.messages.length,
                        itemBuilder: (context, index) => _MessageBubble(message: ticket.messages[index]),
                      ),
                    ),
                    _Composer(
                      controller: _bodyController,
                      pendingAttachmentName: _pendingAttachment?.name,
                      onPickAttachment: _pickAttachment,
                      onClearAttachment: () => setState(() => _pendingAttachment = null),
                      onSend: _sending ? null : _send,
                      sending: _sending,
                      error: _error,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketStatsHeader extends StatelessWidget {
  const _TicketStatsHeader({required this.ticket});
  final SupportTicketDetail ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: AppTheme.glassDecoration(context, radius: AppTheme.cardRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ticket.subject?.isNotEmpty == true ? ticket.subject! : l10n.supportTicketDetailTitle,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _StatChip(icon: Icons.forum_outlined, label: '${ticket.messages.length}'),
              _StatChip(icon: Icons.flag_outlined, label: _statusLabel(l10n, ticket.status)),
              if (ticket.createdAt != null)
                _StatChip(icon: Icons.event_outlined, label: ticket.createdAt!.split('T').first),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'resolved':
        return l10n.ticketStatusResolved;
      case 'closed':
        return l10n.ticketStatusClosed;
      case 'pending':
        return l10n.ticketStatusPending;
      default:
        return l10n.ticketStatusOpen;
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: scheme.onSurface.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.8))),
      ],
    );
  }
}

class _ThreadUnavailableBanner extends StatelessWidget {
  const _ThreadUnavailableBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        border: Border.all(color: const Color(0xFFFF9F0A).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, color: Color(0xFFFF9F0A), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.ticketThreadUnavailableNotice, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fromAdmin = message.isFromAdmin;

    return Align(
      alignment: fromAdmin ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: fromAdmin
              ? scheme.surfaceContainerHighest.withValues(alpha: 0.7)
              : scheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fromAdmin ? l10n.supportTeamLabel : l10n.youLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(message.body, style: const TextStyle(fontSize: 13)),
            if (message.attachmentReference != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attachment, size: 16),
                  const SizedBox(width: 6),
                  Text(l10n.attachmentLabel, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.pendingAttachmentName,
    required this.onPickAttachment,
    required this.onClearAttachment,
    required this.onSend,
    required this.sending,
    required this.error,
  });

  final TextEditingController controller;
  final String? pendingAttachmentName;
  final VoidCallback onPickAttachment;
  final VoidCallback onClearAttachment;
  final VoidCallback? onSend;
  final bool sending;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingAttachmentName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                avatar: Icon(fileIconForFilename(pendingAttachmentName!), size: 18),
                label: Text(pendingAttachmentName!),
                onDeleted: onClearAttachment,
              ),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(error!, style: const TextStyle(color: Color(0xFFC53030))),
            ),
          Row(
            children: [
              IconButton(
                tooltip: l10n.attachImageAction,
                onPressed: sending ? null : onPickAttachment,
                icon: const Icon(Icons.image_outlined),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.ticketReplyHint,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSend,
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
