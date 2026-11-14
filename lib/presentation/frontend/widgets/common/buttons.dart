import 'package:flutter/material.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'progress.dart';

/// Fluent button appearances for [AppButton] (#61).
enum ButtonKind {
  /// The one primary action of a view: brand fill.
  primary,

  /// Default: background fill and 1 px stroke.
  secondary,

  /// No fill and no border; hover shows the subtle fill.
  subtle,

  /// No fill; hover changes only the text color.
  transparent,

  /// Danger fill, only inside a delete confirmation dialog.
  destructive;

  /// Old name of [subtle]. Remove in #69.
  static const quiet = subtle;

  ButtonAppearance get appearance => switch (this) {
    primary => ButtonAppearance.primary,
    secondary => ButtonAppearance.secondary,
    subtle => ButtonAppearance.subtle,
    transparent => ButtonAppearance.transparent,
    destructive => ButtonAppearance.destructive,
  };
}

/// Fluent button. One primary button per view; when several actions have the
/// same weight, all are secondary or subtle. Sentence case labels. The size
/// is large at compact width and medium at other widths unless [size] is set.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.secondary,
    this.icon,
    this.busy = false,
    this.size,
    this.statesController,
  });
  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.size,
    this.statesController,
  }) : kind = ButtonKind.primary;
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.size,
    this.statesController,
  }) : kind = ButtonKind.destructive;
  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;
  final bool busy;
  final ButtonSize? size;
  final WidgetStatesController? statesController;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final s =
        size ?? ButtonSize.of(SizeClass.of(MediaQuery.sizeOf(context).width));
    final enabled = onPressed != null && !busy;
    final style = buttonStyle(p, kind.appearance, size: s);
    final glyph = icon == null
        ? null
        : s == ButtonSize.large
        ? AppIcons.large(icon!)
        : icon!;
    final labelRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph != null) ...[
          Icon(glyph, size: s.icon),
          SizedBox(width: s.gap),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
    final child = Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: busy ? 0 : 1, child: labelRow),
        if (busy) const AppSpinner(),
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
