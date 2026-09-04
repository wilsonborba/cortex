import 'package:flutter/material.dart';

import '../../../domain/models/tier.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'app_theme.dart';
import 'tier_badge.dart';

/// Floating, bottom-anchored glass prompt input.
///
/// Visually locks premium features (attachments, web browsing, model
/// picker) behind a small lock affordance while the session is on Tier 0.
/// There is no backend behind the lock yet, tapping a locked action simply
/// surfaces a snackbar explaining that upgrades are not available yet; the
/// real gating logic is issue #3's job.
class PromptDock extends StatefulWidget {
  const PromptDock({
    super.key,
    required this.onSubmit,
    this.tier = AppTier.tier0,
    this.isBusy = false,
    this.useMemory = false,
    this.onToggleMemory,
  });

  final ValueChanged<String> onSubmit;
  final AppTier tier;
  final bool isBusy;

  /// Whether the next submit should opt into memory-aware execution
  /// (cortex_api's native `/execute` with `capabilities.memory = true`)
  /// instead of the plain streamed chat facade. Unlike attachments/web
  /// browsing, this is not tier-locked: it works on Tier 0 today.
  final bool useMemory;
  final ValueChanged<bool>? onToggleMemory;

  @override
  State<PromptDock> createState() => _PromptDockState();
}

class _PromptDockState extends State<PromptDock> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

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

  void _showLockedFeatureNotice() {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.lockedFeatureNotice(widget.tier.labelOf(context))),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _DockIconButton(
                icon: Icons.add,
                tooltip: l10n.attachFileLocked(widget.tier.labelOf(context)),
                onPressed: widget.tier.isLocked
                    ? _showLockedFeatureNotice
                    : null,
                locked: widget.tier.isLocked,
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
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _DockIconButton(
                icon: Icons.public,
                tooltip: l10n.webBrowsingLocked(widget.tier.labelOf(context)),
                onPressed: widget.tier.isLocked
                    ? _showLockedFeatureNotice
                    : null,
                locked: widget.tier.isLocked,
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
    this.locked = false,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool locked;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                color: active
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (locked)
              Positioned(
                right: 6,
                bottom: 6,
                child: Icon(
                  Icons.lock,
                  size: 10,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
