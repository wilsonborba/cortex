import '../../theme/app_icons.dart';
import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

enum ButtonKind { primary, secondary, quiet, destructive }

/// One primary button per view (24, decision C2): the only accent besides the
/// selected item. Sentence case labels, no brackets, no all caps.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.secondary,
    this.icon,
    this.busy = false,
    this.statesController,
  });
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.statesController,
  }) : kind = ButtonKind.primary;
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.statesController,
  }) : kind = ButtonKind.destructive;
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final bool busy;
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    final (bg, fg, side) = switch (kind) {
      ButtonKind.primary => (p.brandBackground, p.onBrand, p.brandBackground),
      ButtonKind.destructive => (p.dangerSolid, p.onDanger, p.dangerSolid),
      ButtonKind.secondary => (p.surface, p.text, p.text),
      ButtonKind.quiet => (Colors.transparent, p.text, Colors.transparent),
    };
    final enabled = onPressed != null && !busy;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(Controls.minTouch, Controls.height(size)),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: Space.s16),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStatePropertyAll(
        kind == ButtonKind.quiet
            ? Colors.transparent
            : enabled
            ? bg
            : bg.withValues(alpha: 0.4),
      ),
      foregroundColor: WidgetStatePropertyAll(enabled ? fg : p.muted),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      animationDuration: Motion.of(context),
      shape: WidgetStateProperty.resolveWith(
        (states) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            FoundationTokens.of(context).controlRadius,
          ),
          side: BorderSide(
            color: states.contains(WidgetState.focused) ? p.text : side,
            width: states.contains(WidgetState.focused)
                ? Controls.focusRing
                : Controls.border,
          ),
        ),
      ),
      textStyle: WidgetStatePropertyAll(TextStyles.label),
    );
    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: IconSizes.action),
          const SizedBox(width: Space.s8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: busy ? 0 : 1, child: labelRow),
        if (busy)
          SizedBox.square(
            dimension: IconSizes.action,
            child: MediaQuery.disableAnimationsOf(context)
                ? Icon(AppIcons.loading, size: IconSizes.action, color: p.muted)
                : CircularProgressIndicator(
                    strokeWidth: Controls.focusRing,
                    color: p.muted,
                  ),
          ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: FilledButton(
        style: style,
        statesController: statesController,
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    );
  }
}
