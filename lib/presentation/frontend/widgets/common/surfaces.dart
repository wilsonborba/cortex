import '../../theme/app_icons.dart';
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      if (label != null) ...[
        Text(label!, style: TextStyles.label),
        const SizedBox(height: Space.s8),
      ],
      TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        onSubmitted: onSubmitted,
        style: TextStyles.body,
        decoration: InputDecoration(hintText: hint, errorText: error),
      ),
    ],
  );
}

/// Selected chips use neutral inverse colors.
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
    final p = Palette.from(context);
    return ChoiceChip(
      // The label color is set on the Text: the chip theme does not apply
      // labelStyle to a selected Material 3 chip.
      label: Text(
        label,
        style: TextStyles.label.copyWith(
          color: selected ? p.background : p.text,
        ),
      ),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyles.label.copyWith(
        color: selected ? p.background : p.text,
      ),
      selectedColor: p.text,
      backgroundColor: p.surface,
      side: WidgetStateBorderSide.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) || selected
              ? p.text
              : p.border,
          width: states.contains(WidgetState.focused)
              ? Controls.focusRing
              : Controls.border,
        ),
      ),
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
    child: FoundationFocus(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(Space.s16),
          child: child,
        ),
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

/// A Material menu with the app's neutral trigger and keyboard behavior.
class AppSelect<T> extends StatefulWidget {
  const AppSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isExpanded = false,
    this.isDense = false,
    this.itemHeight,
    this.underline,
    this.hint,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded, isDense;
  final double? itemHeight;
  final Widget? underline, hint;
  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chosen = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;
    return MenuAnchor(
      childFocusNode: focus,
      menuChildren: [
        for (final item in widget.items)
          MenuItemButton(
            onPressed: widget.onChanged == null || !item.enabled
                ? null
                : () {
                    widget.onChanged!(item.value);
                    focus.requestFocus();
                  },
            trailingIcon: item.value == widget.value
                ? const Icon(AppIcons.copied)
                : null,
            child: item.child,
          ),
      ],
      builder: (context, controller, child) => TextButton(
        focusNode: focus,
        onPressed: widget.onChanged == null
            ? null
            : () {
                controller.isOpen ? controller.close() : controller.open();
              },
        child: Row(
          mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.isExpanded)
              Expanded(child: chosen?.child ?? widget.hint ?? const SizedBox())
            else
              chosen?.child ?? widget.hint ?? const SizedBox(),
            const SizedBox(width: Space.s8),
            const Icon(AppIcons.expand, size: IconSizes.action),
          ],
        ),
      ),
    );
  }
}

class AppSelectFormField<T> extends FormField<T> {
  AppSelectFormField({
    super.key,
    super.initialValue,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
    InputDecoration decoration = const InputDecoration(),
    super.validator,
  }) : super(
         builder: (state) => InputDecorator(
           decoration: decoration.copyWith(errorText: state.errorText),
           child: AppSelect<T>(
             value: state.value,
             items: items,
             onChanged: onChanged == null
                 ? null
                 : (value) {
                     state.didChange(value);
                     onChanged(value);
                   },
           ),
         ),
       );
}

class AppMenu<T> extends StatefulWidget {
  const AppMenu({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.itemBuilder,
    required this.onSelected,
  });
  final String tooltip;
  final Widget icon;
  final List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder;
  final ValueChanged<T> onSelected;
  @override
  State<AppMenu<T>> createState() => _AppMenuState<T>();
}

class _AppMenuState<T> extends State<AppMenu<T>> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MenuAnchor(
    childFocusNode: focus,
    menuChildren: [
      for (final item in widget.itemBuilder(context))
        if (item is PopupMenuDivider)
          const Divider()
        else if (item is PopupMenuItem<T>) ...[
          if (item.value == 'delete') const Divider(),
          MenuItemButton(
            onPressed: !item.enabled
                ? null
                : () {
                    if (item.value != null) widget.onSelected(item.value as T);
                    focus.requestFocus();
                  },
            child: item.child ?? const SizedBox(),
          ),
        ],
    ],
    builder: (context, controller, child) => IconButton(
      focusNode: focus,
      tooltip: widget.tooltip,
      icon: widget.icon,
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
    ),
  );
}
