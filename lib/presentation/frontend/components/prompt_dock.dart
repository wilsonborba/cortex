import 'package:flutter/material.dart';

import '../../../domain/models/attachment.dart';
import '../../../domain/models/tier.dart';
import '../../../domain/services/attachment_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'attachment_preview_strip.dart';
import 'voice_recording_bar.dart';

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
    this.onSendVoiceMessage,
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

  /// Called with the finished clip when the recording bar's send button is
  /// tapped (issue #11: record and send a voice message, not dictation).
  final ValueChanged<ChatAttachment>? onSendVoiceMessage;

  @override
  State<PromptDock> createState() => _PromptDockState();
}

class _PromptDockState extends State<PromptDock> {
  late final _controller = TextEditingController(text: widget.draftText);
  final _focusNode = FocusNode();
  final _attachmentService = const AttachmentService();
  bool _isRecordingVoice = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isRecordingVoice && widget.pendingAttachments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: AttachmentPreviewStrip(
                attachments: widget.pendingAttachments,
                onRemove: widget.onRemoveAttachment ?? (_) {},
              ),
            ),
          if (_isRecordingVoice)
            VoiceRecordingBar(
              onSend: (attachment) {
                setState(() => _isRecordingVoice = false);
                widget.onSendVoiceMessage?.call(attachment);
              },
              onCancelled: () => setState(() => _isRecordingVoice = false),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 6,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l10n.messageHint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _submit(),
                onChanged: widget.onDraftChanged,
              ),
            ),
            const Divider(height: 12, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Attach button
                          _DockToolButton(
                            icon: Icons.attach_file,
                            tooltip: l10n.attachTooltip,
                            onPressed: widget.onAddAttachments == null
                                ? null
                                : _openAttachMenu,
                          ),
                          const SizedBox(width: 6),
                          // Web Search Pill
                          _DockPill(
                            icon: Icons.language,
                            label: l10n.webResearchPill,
                            active: widget.needsWeb,
                            onPressed: widget.onToggleNeedsWeb == null
                                ? null
                                : () => widget.onToggleNeedsWeb!(!widget.needsWeb),
                          ),
                          const SizedBox(width: 6),
                          // Memory Engine Pill
                          _DockPill(
                            icon: Icons.memory,
                            label: l10n.memoryEnginePill,
                            active: widget.useMemory,
                            onPressed: widget.onToggleMemory == null
                                ? null
                                : () => widget.onToggleMemory!(!widget.useMemory),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Voice message recorder (issue #11): tapping transitions
                  // this dock into VoiceRecordingBar above.
                  Tooltip(
                    message: l10n.voiceStartRecording,
                    child: IconButton(
                      onPressed: widget.onSendVoiceMessage == null
                          ? null
                          : () => setState(() => _isRecordingVoice = true),
                      icon: Icon(
                        Icons.mic_none_outlined,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Send button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: widget.isBusy ? null : _submit,
                      child: Icon(
                      widget.isBusy ? Icons.stop : Icons.arrow_upward,
                      size: 16,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }
}

class _DockToolButton extends StatelessWidget {
  const _DockToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(
            color: scheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Icon(
            icon,
            size: 15,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _DockPill extends StatelessWidget {
  const _DockPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? scheme.surfaceContainerHighest
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? scheme.primary
                : scheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
