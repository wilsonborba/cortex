import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'buttons.dart';
import 'states.dart' show NoticeKind;

/// Toast width at medium and expanded width. The issue gives no Fluent toast
/// width, so it uses the menu maximum width until the owner confirms a value.
const toastWidth = Space.menuMaxWidth;

/// How long a toast without an action stays (#61).
const toastTimeout = Duration(seconds: 7);

/// Shows a Fluent toast (#61): floating, radius 4, padding 12, `raised`,
/// shadow8, status icon on the left, title `body1Strong`, body `body1`.
/// Bottom end at medium and expanded width, bottom full width (16 px margin)
/// at compact width. Without an action it closes after 7 seconds; hover
/// keeps it open. With an action it stays until the action or close.
void showToast(
  BuildContext context, {
  required String message,
  String? title,
  NoticeKind kind = NoticeKind.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final width = MediaQuery.sizeOf(context).width;
  final compact = SizeClass.of(width) == SizeClass.compact;
  messenger.hideCurrentSnackBar();
  late final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> shown;
  shown = messenger.showSnackBar(
    SnackBar(
      // The toast owns its timer so that hover can keep it open.
      duration: const Duration(days: 1),
      // No clip: the Fluent toast shadow is painted outside the shape.
      clipBehavior: Clip.none,
      padding: const EdgeInsets.all(Space.s12),
      margin: compact
          ? const EdgeInsets.all(Space.s16)
          : EdgeInsets.only(
              left: math.max(Space.s16, width - Space.s16 - toastWidth),
              right: Space.s16,
              bottom: Space.s16,
            ),
      content: Toast(
        message: message,
        title: title,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction == null
            ? null
            : () {
                shown.close();
                onAction();
              },
        onTimeout: () => shown.close(),
      ),
    ),
  );
}

/// The content of a toast. Public for the component gallery.
class Toast extends StatefulWidget {
  const Toast({
    super.key,
    required this.message,
    this.title,
    this.kind = NoticeKind.info,
    this.actionLabel,
    this.onAction,
    this.onTimeout,
  });
  final String message;
  final String? title;
  final NoticeKind kind;
  final String? actionLabel;
  final VoidCallback? onAction, onTimeout;
  @override
  State<Toast> createState() => _ToastState();
}

class _ToastState extends State<Toast> {
  Timer? timer;
  bool get timed => widget.actionLabel == null && widget.onTimeout != null;

  void start() {
    timer?.cancel();
    if (timed) timer = Timer(toastTimeout, () => widget.onTimeout?.call());
  }

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final (icon, color) = switch (widget.kind) {
      NoticeKind.info => (AppIcons.info, p.muted),
      NoticeKind.success => (AppIcons.success, p.successForeground),
      NoticeKind.warning => (AppIcons.warning, p.warningForeground),
      NoticeKind.error => (AppIcons.error, p.dangerForeground),
    };
    return MouseRegion(
      onEnter: (_) => timer?.cancel(),
      onExit: (_) => start(),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: IconSizes.action, color: color),
            const SizedBox(width: Space.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.title != null)
                    Text(
                      widget.title!,
                      style: TextStyles.body1Strong.copyWith(color: p.text),
                    ),
                  Text(
                    widget.message,
                    style: TextStyles.body1.copyWith(color: p.text),
                  ),
                ],
              ),
            ),
            if (widget.actionLabel != null) ...[
              const SizedBox(width: Space.s8),
              AppButton(
                label: widget.actionLabel!,
                onPressed: widget.onAction,
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
