import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'buttons.dart';

/// Text input with the token border and a visible focus ring.
class AppInput extends StatelessWidget {
  const AppInput({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.error,
    this.maxLines = 1,
    this.onSubmitted,
    this.enabled = true,
  });
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? error;
  final int maxLines;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    maxLines: maxLines,
    onSubmitted: onSubmitted,
    style: TextStyles.body,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
    ),
  );
}

/// Chip; the selected chip is the selected item, so it carries the accent.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
  });
  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return ChoiceChip(
      // The label color is set on the Text: the chip theme does not apply
      // labelStyle to a selected Material 3 chip.
      label: Text(
        label,
        style: TextStyles.label.copyWith(color: selected ? p.onAccent : p.text),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyles.label.copyWith(
        color: selected ? p.onAccent : p.text,
      ),
      selectedColor: p.accent,
      backgroundColor: p.surface,
      side: BorderSide(color: selected ? p.accent : p.border),
      elevation: 0,
      pressElevation: 0,
    );
  }
}

/// Card: radius 12, 1 px border, no shadow.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap, this.padding});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(Space.s16),
        child: child,
      ),
    ),
  );
}

/// Bottom sheet with the token shape.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (c) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.s24, 0, Space.s24, Space.s24),
        child: builder(c),
      ),
    );

/// Confirm dialog. A destructive action is red and needs the confirm press.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title, style: TextStyles.subsection),
        content: Text(message, style: TextStyles.body),
        actions: [
          AppButton(label: cancel, onPressed: () => Navigator.pop(c, false)),
          destructive
              ? AppButton.destructive(
                  label: confirm,
                  onPressed: () => Navigator.pop(c, true),
                )
              : AppButton.primary(
                  label: confirm,
                  onPressed: () => Navigator.pop(c, true),
                ),
        ],
      ),
    ) ??
    false;
