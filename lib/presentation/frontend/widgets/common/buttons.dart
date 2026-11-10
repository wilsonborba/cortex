import 'package:flutter/material.dart';
import '../../theme/tokens.dart';

enum ButtonKind { primary, secondary, destructive }

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
  });
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  }) : kind = ButtonKind.primary;
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
  }) : kind = ButtonKind.destructive;
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    final (bg, fg, side) = switch (kind) {
      ButtonKind.primary => (p.accent, p.onAccent, p.accent),
      ButtonKind.destructive => (p.danger, p.onDanger, p.danger),
      ButtonKind.secondary => (p.surface, p.text, p.border),
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
        enabled ? bg : bg.withValues(alpha: 0.4),
      ),
      foregroundColor: WidgetStatePropertyAll(enabled ? fg : p.muted),
      overlayColor: WidgetStatePropertyAll(fg.withValues(alpha: 0.08)),
      animationDuration: Motion.of(context),
      shape: WidgetStateProperty.resolveWith(
        (states) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.control),
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
    final child = busy
        ? SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: Space.s8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: FilledButton(
        style: style,
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    );
  }
}
