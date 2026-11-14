import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'buttons.dart';

export 'progress.dart' show SkeletonBox, AppSpinner, AppProgressBar;

/// Empty state (#61): the 24 px glyph in a 48 px `tagBackground` circle,
/// title `subtitle1`, text `body1` `muted` (at most 2 lines), one secondary
/// action. Centered in the area.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.empty,
    this.action,
  });
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: Space.s48,
                height: Space.s48,
                decoration: BoxDecoration(
                  color: p.tagBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.large(icon),
                  size: IconSizes.large,
                  color: p.text2,
                ),
              ),
              const SizedBox(height: Space.s12),
              Text(
                title,
                style: TextStyles.subtitle1.copyWith(color: p.text),
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: Space.s8),
                Text(
                  message!,
                  style: TextStyles.body1.copyWith(color: p.muted),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

/// Error with Retry, as an empty state with the error icon.
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
    icon: AppIcons.error,
    action: AppButton(
      label: retryLabel,
      onPressed: onRetry,
      icon: AppIcons.retry,
    ),
  );
}

/// Message bar intents (#61).
enum NoticeKind { info, warning, error, success }

/// Fluent MessageBar (#61): min height 36, radius 4, padding 8 x 12, 1 px
/// border and background from the status colors, 16 px icon in the status
/// foreground color, `body1` text, optional subtle small action on the right.
class MessageBar extends StatelessWidget {
  const MessageBar({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
    this.icon,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final NoticeKind kind;

  /// Defaults to the icon of [kind].
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final (background, border, foreground, glyph) = switch (kind) {
      NoticeKind.info => (p.tagBackground, p.stroke, p.muted, AppIcons.info),
      NoticeKind.warning => (
        p.warningBackground,
        p.warningBorder,
        p.warningForeground,
        AppIcons.warning,
      ),
      NoticeKind.error => (
        p.dangerBackground,
        p.dangerBorder,
        p.dangerForeground,
        AppIcons.error,
      ),
      NoticeKind.success => (
        p.successBackground,
        p.successBorder,
        p.successForeground,
        AppIcons.copied,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        padding: const EdgeInsets.symmetric(
          horizontal: Space.s12,
          vertical: Space.s8,
        ),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon ?? glyph, size: IconSizes.small, color: foreground),
            const SizedBox(width: Space.s8),
            Expanded(
              child: Text(
                message,
                style: TextStyles.body1.copyWith(color: p.text),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: Space.s8),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                kind: ButtonKind.subtle,
                size: ButtonSize.small,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Offline message bar at the top of the content.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.s8),
    child: MessageBar(
      message: message,
      kind: NoticeKind.warning,
      icon: AppIcons.offline,
    ),
  );
}

/// One notice as a message bar (process number notices).
class NoticeLine extends StatelessWidget {
  const NoticeLine({
    super.key,
    required this.message,
    this.kind = NoticeKind.info,
  });
  final String message;
  final NoticeKind kind;
  @override
  Widget build(BuildContext context) =>
      MessageBar(message: message, kind: kind);
}
