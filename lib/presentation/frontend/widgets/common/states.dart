import '../../../../l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'buttons.dart';

/// Skeleton loader: a still block in the border color (no shimmer, 24 motion rule).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 16});
  final double? width;
  final double height;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: p.border,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32, color: p.muted),
              const SizedBox(height: Space.s12),
              Text(
                title,
                style: TextStyles.subsection,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: Space.s8),
                Text(
                  message!,
                  style: TextStyles.body.copyWith(color: p.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: Space.s16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error with Retry.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => EmptyState(
    title: message,
    icon: Icons.error_outline,
    action: AppButton(
      label: retryLabel,
      onPressed: onRetry,
      icon: Icons.refresh,
    ),
  );
}

/// Offline banner at the top of the content.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s16,
          vertical: Space.s8,
        ),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(bottom: BorderSide(color: p.border)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: p.text),
            const SizedBox(width: Space.s8),
            Expanded(child: Text(message, style: TextStyles.compact)),
          ],
        ),
      ),
    );
  }
}

enum NoticeKind { info, warning, error }

/// One notice line with an icon (process number notices, 24).
class NoticeLine extends StatelessWidget {
  const NoticeLine({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
  });
  final String message;
  final NoticeKind kind;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    final (icon, color) = switch (kind) {
      NoticeKind.info => (Icons.info_outline, p.muted),
      NoticeKind.warning => (Icons.warning_amber_outlined, p.text),
      NoticeKind.error => (Icons.error_outline, p.danger),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: Space.s8),
        Expanded(
          child: Text(
            message,
            style: TextStyles.compact.copyWith(color: p.muted),
          ),
        ),
      ],
    );
  }
}
