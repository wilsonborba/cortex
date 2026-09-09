import 'package:flutter/material.dart';

import '../../../../domain/models/support_ticket.dart';
import '../../../../domain/services/attachment_service.dart';
import '../../../../domain/services/support_api_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_theme.dart';
import '../../components/file_icons.dart';
import '../../components/premium_hover_card.dart';
import 'on_support_ticket.dart';

/// Support ticket list (ported from `certifications/lib/presentation/widgets/
/// support/on_support.dart`): CRUD against api_for_apps's central support
/// system (api_for_apps#17), restyled to Cortex's dark monochrome glass
/// aesthetic instead of certifications' Material theme.
///
/// Reachable at any time from the settings sheet (see [AppSettingsSheet]),
/// independent of whether an error ever occurred. When [initialComposeSubject]
/// or [initialComposeBody] is set (the generic error view's "contact
/// support" CTA), the new-ticket composer opens automatically, pre-filled,
/// right after this screen's first frame.
class OnSupportScreen extends StatefulWidget {
  const OnSupportScreen({
    super.key,
    this.initialComposeSubject,
    this.initialComposeBody,
  });

  final String? initialComposeSubject;
  final String? initialComposeBody;

  @override
  State<OnSupportScreen> createState() => _OnSupportScreenState();
}

class _OnSupportScreenState extends State<OnSupportScreen> {
  final _api = SupportApiService();
  late Future<List<SupportTicket>> _future = _api.listTickets();

  @override
  void initState() {
    super.initState();
    if (widget.initialComposeSubject != null || widget.initialComposeBody != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNewTicket();
      });
    }
  }

  void _reload() => setState(() => _future = _api.listTickets());

  Future<void> _openNewTicket() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewTicketDialog(
        api: _api,
        initialSubject: widget.initialComposeSubject,
        initialBody: widget.initialComposeBody,
      ),
    );
    if (created == true) _reload();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SupportTicketScreen(ticketId: ticket.id)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supportTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTicket,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l10n.newTicketAction),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<SupportTicket>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Text(l10n.errorLoadingTicketsMessage),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _reload,
                                child: Text(l10n.tryAgainAction),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final tickets = snapshot.data ?? const [];
                  if (tickets.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.support_agent_outlined,
                                size: 56,
                                color: scheme.onSurface.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noSupportTicketsYetTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  l10n.noSupportTicketsYetBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: scheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final statusColor = _statusColor(scheme, ticket.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PremiumHoverCard(
                          onTap: () => _openTicket(ticket),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                                ),
                                child: Icon(Icons.confirmation_number_outlined, color: statusColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.id.length >= 8 ? ticket.id.substring(0, 8) : ticket.id,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _statusLabel(l10n, ticket.status),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme scheme, String status) {
    switch (status) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF34C759);
      case 'pending':
        return const Color(0xFFFF9F0A);
      default:
        return scheme.primary;
    }
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

class _NewTicketDialog extends StatefulWidget {
  const _NewTicketDialog({required this.api, this.initialSubject, this.initialBody});

  final SupportApiService api;
  final String? initialSubject;
  final String? initialBody;

  @override
  State<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends State<_NewTicketDialog> {
  late final _subjectController = TextEditingController(text: widget.initialSubject ?? '');
  late final _bodyController = TextEditingController(text: widget.initialBody ?? '');
  final _attachmentService = const AttachmentService();
  bool _submitting = false;
  String? _error;
  ({String name, List<int> bytes, String mimeType})? _pendingAttachment;

  @override
  void dispose() {
    _subjectController.dispose();
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

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      String? attachmentReference;
      final attachment = _pendingAttachment;
      if (attachment != null) {
        attachmentReference = await widget.api.uploadAttachment(
          filename: attachment.name,
          bytes: attachment.bytes,
          mimeType: attachment.mimeType,
        );
      }
      await widget.api.createTicket(
        subject: _subjectController.text.trim().isEmpty ? null : _subjectController.text.trim(),
        body: body,
        attachmentReference: attachmentReference,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = l10n.ticketActionFailedMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
      ),
      title: Text(
        l10n.newTicketAction,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: l10n.ticketSubjectLabel, hintText: l10n.ticketSubjectHint),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(labelText: l10n.ticketBodyLabel),
            ),
            const SizedBox(height: 12),
            if (_pendingAttachment != null)
              Chip(
                avatar: Icon(fileIconForFilename(_pendingAttachment!.name), size: 18),
                label: Text(_pendingAttachment!.name),
                onDeleted: () => setState(() => _pendingAttachment = null),
              )
            else
              OutlinedButton.icon(
                onPressed: _submitting ? null : _pickAttachment,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text(l10n.attachImageAction),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFC53030))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel, style: TextStyle(color: scheme.onSurface)),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submitAction),
        ),
      ],
    );
  }
}
