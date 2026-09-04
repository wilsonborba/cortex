import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Small inline action shown under an assistant message that was left
/// [ChatMessage.interrupted] by a dropped SSE connection (issue #7).
///
/// Tapping it retries the request (see `ChatService.continueGeneration`):
/// cortex_api has no partial-completion resume API, so this is a full
/// retry that replaces the interrupted text once a new reply comes in, not
/// a true "pick up where it left off".
class ContinueGenerationChip extends StatelessWidget {
  const ContinueGenerationChip({
    super.key,
    required this.onPressed,
    this.isBusy = false,
  });

  final VoidCallback onPressed;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: ActionChip(
        avatar: isBusy
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              )
            : Icon(
                Icons.refresh,
                size: 16,
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
        label: Text(l10n.continueGenerationLabel),
        tooltip: l10n.continueGenerationTooltip,
        onPressed: isBusy ? null : onPressed,
        backgroundColor: scheme.onSurface.withValues(alpha: 0.06),
        side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.14)),
      ),
    );
  }
}
