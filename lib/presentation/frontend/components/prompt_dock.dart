import 'package:flutter/material.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/models/tier.dart';
import '../../../domain/services/attachment_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'app_theme.dart';
import 'attachment_preview_strip.dart';
import 'tier_badge.dart';
import 'voice_recorder_button.dart';

/// Floating, bottom-anchored glass prompt input.
///
/// Carries the memory recall, web-search grounding, attachment and voice
/// affordances. Attachments and web-search grounding (issue #6) are real,
/// working features on Tier 0 today, unlike the model-picker style
/// upgrades this dock has no UI for at all.
class PromptDock extends StatefulWidget {
  const PromptDock({
    super.key,
    required this.onSubmit,
    this.tier = AppTier.tier0,
    this.isBusy = false,
    this.useMemory = false,
    this.onToggleMemory,
    this.needsWeb = false,
    this.onToggleNeedsWeb,
    this.pendingAttachments = const [],
    this.onAddAttachments,
    this.onRemoveAttachment,
    this.conversationId,
    this.draftText = '',
    this.onDraftChanged,
  });

  final ValueChanged<String> onSubmit;
  final AppTier tier;
  final bool isBusy;

  /// Id of the conversation this dock is currently composing a message
  /// for (issue #7). When it changes between builds, the text field's
  /// content is swapped for [draftText] (the newly-selected conversation's
  /// restored draft) instead of keeping whatever was typed for the
  /// previous conversation.
  final String? conversationId;

  /// The persisted, in-progress draft for [conversationId], restored from
  /// `DraftStore` by `ChatFlowHandler`. Only consulted on first build and
  /// whenever [conversationId] changes, once the user starts typing this
  /// widget owns the text via its own `TextEditingController`.
  final String draftText;

  /// Called on every keystroke so the caller (`ChatFlowHandler`) can persist
  /// the draft (issue #7).
  final ValueChanged<String>? onDraftChanged;

  /// Whether the next submit should opt into memory-aware execution
  /// (cortex_api's native `/execute` with `capabilities.memory = true`)
  /// instead of the plain streamed chat facade. Unlike attachments/web
  /// browsing, this is not tier-locked: it works on Tier 0 today.
  final bool useMemory;
  final ValueChanged<bool>? onToggleMemory;

  /// Whether the next submit should set `needs_web`/`capabilities.web`
  /// (issue #6), asking cortex_api for web-search-grounded results.
  final bool needsWeb;
  final ValueChanged<bool>? onToggleNeedsWeb;

  /// Files picked from the attach menu, waiting to be sent with the next
  /// submit (issue #6).
  final List<ChatAttachment> pendingAttachments;
  final ValueChanged<List<ChatAttachment>>? onAddAttachments;
  final ValueChanged<String>? onRemoveAttachment;

  @override
  State<PromptDock> createState() => _PromptDockState();
}

class _PromptDockState extends State<PromptDock> {
  late final _controller = TextEditingController(text: widget.draftText);
  final _focusNode = FocusNode();
  final _attachmentService = const AttachmentService();

  @override
  void didUpdateWidget(PromptDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only swap the field's content when the conversation actually changed,
    // not on every rebuild carrying the same draft back down (issue #7):
    // otherwise this would clobber whatever the user is actively typing.
    if (oldWidget.conversationId != widget.conversationId) {
      _controller.text = widget.draftText;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isBusy) return;
    widget.onSubmit(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _insertTranscript(String transcript) {
    final selection = _controller.selection;
    final text = _controller.text;
    final insertAt = selection.isValid ? selection.start : text.length;
    final needsSpace =
        insertAt > 0 && text.isNotEmpty && text[insertAt - 1] != ' ';
    final toInsert = (needsSpace ? ' ' : '') + transcript;
    final newText = text.replaceRange(insertAt, insertAt, toInsert);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: insertAt + toInsert.length),
    );
    _focusNode.requestFocus();
  }

  Future<void> _openAttachMenu() async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(l10n.attachImage),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.attachDocument),
              subtitle: Text(l10n.documentAttachmentBackendGap),
              onTap: () => Navigator.of(context).pop('document'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || widget.onAddAttachments == null) return;
    final picked = choice == 'image'
        ? await _attachmentService.pickImages()
        : await _attachmentService.pickDocuments();
    if (picked.isNotEmpty) widget.onAddAttachments!(picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: AppTheme.glassDecoration(
        context,
        radius: AppTheme.cardRadius,
        fillOpacity: 0.72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: TierBadge(tier: widget.tier, dense: true),
          ),
          AttachmentPreviewStrip(
            attachments: widget.pendingAttachments,
            onRemove: widget.onRemoveAttachment ?? (_) {},
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DockIconButton(
                icon: Icons.add,
                tooltip: l10n.attachFile,
                onPressed: widget.onAddAttachments == null
                    ? null
                    : _openAttachMenu,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: l10n.messageHint,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    onChanged: widget.onDraftChanged,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              VoiceRecorderButton(onTranscript: _insertTranscript),
              const SizedBox(width: 4),
              _DockIconButton(
                icon: Icons.public,
                tooltip: widget.needsWeb
                    ? l10n.webSearchOnTooltip
                    : l10n.webSearchOffTooltip,
                onPressed: widget.onToggleNeedsWeb == null
                    ? null
                    : () => widget.onToggleNeedsWeb!(!widget.needsWeb),
                active: widget.needsWeb,
              ),
              const SizedBox(width: 4),
              _DockIconButton(
                icon: Icons.psychology_alt_outlined,
                tooltip: widget.useMemory
                    ? l10n.memoryRecallOnTooltip
                    : l10n.memoryRecallOffTooltip,
                onPressed: widget.onToggleMemory == null
                    ? null
                    : () => widget.onToggleMemory!(!widget.useMemory),
                active: widget.useMemory,
              ),
              const SizedBox(width: 4),
              Material(
                color: scheme.onSurface,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: widget.isBusy ? null : _submit,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      widget.isBusy ? Icons.stop_rounded : Icons.arrow_upward,
                      color: scheme.surface,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  const _DockIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: active
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}
