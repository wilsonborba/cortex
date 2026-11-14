import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import 'buttons.dart';

/// Height of inputs and dropdowns: 40 at compact width, 32 at other widths.
double fieldHeight(BuildContext context) =>
    Controls.height(SizeClass.of(MediaQuery.sizeOf(context).width));

/// Fluent field frame (#61): `background` fill, radius 4, 1 px `stroke` on
/// top, left and right, 1 px `strokeAccessible` at the bottom, and a 2 px
/// `brandStroke1` bar at the bottom that grows from the center while
/// [focus] goes from 0 to 1.
class AppFieldFrame extends StatelessWidget {
  const AppFieldFrame({
    super.key,
    required this.child,
    this.focus = 0,
    this.enabled = true,
  });
  final Widget child;
  final double focus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return CustomPaint(
      foregroundPainter: _FramePainter(
        side: BorderSide(color: enabled ? p.stroke : p.disabledStroke),
        bottom: BorderSide(
          color: enabled ? p.strokeAccessible : p.disabledStroke,
        ),
        focus: p.brandStroke1,
        bar: enabled ? focus : 0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? p.background : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: child,
      ),
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter({
    required this.side,
    required this.bottom,
    required this.focus,
    required this.bar,
  });
  final BorderSide side, bottom;
  final Color focus;
  final double bar;

  @override
  void paint(Canvas canvas, Size size) => paintFluentFrame(
    canvas,
    Offset.zero & size,
    side,
    bottom,
    focus,
    bar,
    Radii.control,
  );

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.side != side ||
      old.bottom != bottom ||
      old.focus != focus ||
      old.bar != bar;
}

/// Drives the focus bar: enter 200 ms decelerateMid, exit 100 ms
/// accelerateMid, zero with Reduce Motion.
mixin _FocusBar<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController bar = AnimationController(vsync: this);

  void animateBar(bool on) {
    final tokens = FoundationTokens.of(context);
    if (on) {
      bar.animateTo(
        1,
        duration: tokens.duration(context, tokens.menu),
        curve: FoundationTokens.enterCurve,
      );
    } else {
      bar.animateTo(
        0,
        duration: tokens.duration(context, tokens.menuExit),
        curve: FoundationTokens.exitCurve,
      );
    }
  }

  @override
  void dispose() {
    bar.dispose();
    super.dispose();
  }
}

/// Fluent input with the Field pattern (#61): label above (`body1`, 4 px
/// gap), the input frame, and helper or validation text below (`caption1`).
/// A validation error shows the 16 px error icon in `dangerForeground`.
/// Multi line inputs have padding 6 x 12 and a minimum height of 52.
class AppInput extends StatefulWidget {
  const AppInput({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.maxLines = 1,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
  });
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label, hint, helper, error;
  final int? maxLines;
  final ValueChanged<String>? onSubmitted, onChanged;
  final bool enabled, autofocus;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput>
    with SingleTickerProviderStateMixin, _FocusBar {
  final ownedFocus = FocusNode();
  FocusNode get focus => widget.focusNode ?? ownedFocus;

  @override
  void initState() {
    super.initState();
    focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(AppInput old) {
    super.didUpdateWidget(old);
    final before = old.focusNode ?? ownedFocus;
    if (before != focus) {
      before.removeListener(_focusChanged);
      focus.addListener(_focusChanged);
    }
  }

  void _focusChanged() => animateBar(focus.hasFocus);

  @override
  void dispose() {
    focus.removeListener(_focusChanged);
    ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final multi = widget.maxLines != 1;
    final height = fieldHeight(context);
    final line = TextStyles.body1.fontSize! * TextStyles.body1.height!;
    final vertical = multi ? Space.s6 : (height - line) / 2 - Controls.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: TextStyles.body1.copyWith(color: p.text)),
          const SizedBox(height: Space.s4),
        ],
        AnimatedBuilder(
          animation: bar,
          builder: (context, child) => AppFieldFrame(
            focus: bar.value,
            enabled: widget.enabled,
            child: child!,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: focus,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.maxLines,
            minLines: multi ? 2 : null,
            onSubmitted: widget.onSubmitted,
            onChanged: widget.onChanged,
            style: TextStyles.body1.copyWith(
              color: widget.enabled ? p.text : p.disabledText,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: Space.s12,
                vertical: vertical,
              ),
            ),
          ),
        ),
        FieldMessage(error: widget.error, helper: widget.helper),
      ],
    );
  }
}

/// Helper or validation text below a field (#61).
class FieldMessage extends StatelessWidget {
  const FieldMessage({super.key, this.error, this.helper});
  final String? error, helper;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.error,
              size: IconSizes.small,
              color: p.dangerForeground,
            ),
            const SizedBox(width: Space.s4),
            Expanded(
              child: Text(
                error!,
                style: TextStyles.caption1.copyWith(color: p.dangerForeground),
              ),
            ),
          ],
        ),
      );
    }
    if (helper != null) {
      return Padding(
        padding: const EdgeInsets.only(top: Space.s4),
        child: Text(
          helper!,
          style: TextStyles.caption1.copyWith(color: p.muted),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Fluent tag as a choice chip (#61): 24 high, radius 4, `tagBackground`,
/// `caption1`; selected uses the `selected` fill.
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
  Widget build(BuildContext context) => ChoiceChip(
    visualDensity: Controls.tagDensity,
    label: Text(label),
    selected: selected,
    onSelected: onSelected,
  );
}

/// Fluent card (#61): `raised`, radius 4, padding 12, shadow4, no border.
/// Clickable cards show shadow8 on hover. Selected: `brandBackground2` fill
/// and a 1 px `brandStroke1` border.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.selected = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final bool selected;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final lift = hovered && widget.onTap != null;
    return Material(
      color: widget.selected ? p.brandBackground2 : p.raised,
      // No clip: the Fluent shadow is painted outside the shape.
      clipBehavior: Clip.none,
      shape: ShadowedBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        side: widget.selected
            ? BorderSide(color: p.brandStroke1)
            : BorderSide.none,
        shadows: lift ? Shadows.shadow8(b) : Shadows.shadow4(b),
      ),
      child: FoundationFocus(
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) => setState(() => hovered = value),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(Space.s12),
            child: widget.child,
          ),
        ),
      ),
    );
  }
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

/// Fluent dialog (#61): `background`, radius 8, padding 24, max width 600,
/// shadow64, overlay scrim. Title `subtitle1`, body `body1`, gap 8. Actions
/// at the bottom right, primary first. At compact width it fills the width
/// with a 16 px margin. An [alert] closes only with its buttons; other
/// dialogs close with Esc, an outside click or the close button.
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder content,
  required List<Widget> Function(BuildContext) actions,
  bool alert = false,
}) => showDialog<T>(
  context: context,
  barrierDismissible: !alert,
  builder: (c) => AppDialog(
    title: title,
    alert: alert,
    actions: actions(c),
    content: content(c),
  ),
);

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.alert = false,
  });
  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(
        Space.s24,
        Space.s24,
        Space.s24,
        0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        Space.s24,
        Space.s8,
        Space.s24,
        0,
      ),
      actionsPadding: const EdgeInsets.all(Space.s24),
      actionsAlignment: MainAxisAlignment.end,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyles.subtitle1.copyWith(color: p.text),
            ),
          ),
          if (!alert)
            IconButton(
              tooltip: AppLocalizations.of(context).close,
              icon: const Icon(AppIcons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
      content: compact
          ? SizedBox(width: double.maxFinite, child: content)
          : content,
      actions: actions,
    );
  }
}

/// Delete or other confirmation (an alert dialog). The confirm button comes
/// first: destructive (danger fill) or primary; Cancel is secondary.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  required String cancel,
  bool destructive = false,
}) async =>
    await showAppDialog<bool>(
      context,
      title: title,
      alert: true,
      content: (c) => Text(message, style: TextStyles.body1),
      actions: (c) => [
        destructive
            ? AppButton.destructive(
                label: confirm,
                onPressed: () => Navigator.pop(c, true),
              )
            : AppButton.primary(
                label: confirm,
                onPressed: () => Navigator.pop(c, true),
              ),
        AppButton(label: cancel, onPressed: () => Navigator.pop(c, false)),
      ],
    ) ??
    false;

/// Tooltip that also opens on keyboard focus (#61). Fluent: sentence case,
/// no end period.
class AppTooltip extends StatefulWidget {
  const AppTooltip({super.key, required this.message, required this.child});
  final String message;
  final Widget child;
  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip> {
  final tooltip = GlobalKey<TooltipState>();
  @override
  Widget build(BuildContext context) => Focus(
    skipTraversal: true,
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (focused &&
          FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional) {
        tooltip.currentState?.ensureTooltipVisible();
      } else if (!focused) {
        Tooltip.dismissAllToolTips();
      }
    },
    child: Tooltip(key: tooltip, message: widget.message, child: widget.child),
  );
}

/// Fluent menu enter motion (#61): fade and a 4 px slide, 200 ms
/// decelerateMid. Flutter removes a MenuAnchor menu at once on close, so
/// there is no exit motion.
class MenuEnter extends StatelessWidget {
  const MenuEnter({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Motion.menuOf(context),
    curve: FoundationTokens.enterCurve,
    builder: (context, t, child) => Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * -Space.s4),
        child: child,
      ),
    ),
    child: child,
  );
}

/// A Fluent group divider inside a menu: 1 px line with 4 px space.
class MenuGroupDivider extends StatelessWidget {
  const MenuGroupDivider({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: Space.s4),
    child: Divider(),
  );
}

/// Fluent dropdown: the input frame with the chosen value and a chevron,
/// and a Fluent menu with a check on the chosen item.
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
    this.focusNode,
  });
  final FocusNode? focusNode;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isExpanded, isDense;
  final double? itemHeight;
  final Widget? underline, hint;
  @override
  State<AppSelect<T>> createState() => _AppSelectState<T>();
}

class _AppSelectState<T> extends State<AppSelect<T>>
    with SingleTickerProviderStateMixin, _FocusBar {
  final ownedFocus = FocusNode();
  FocusNode get focus => widget.focusNode ?? ownedFocus;
  bool open = false;

  @override
  void initState() {
    super.initState();
    focus.addListener(_changed);
  }

  void _changed() => animateBar(focus.hasFocus || open);

  @override
  void dispose() {
    focus.removeListener(_changed);
    ownedFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final enabled = widget.onChanged != null;
    final chosen = widget.items
        .where((item) => item.value == widget.value)
        .firstOrNull;
    final shown = DefaultTextStyle.merge(
      style: TextStyles.body1.copyWith(
        color: chosen == null ? p.muted : (enabled ? p.text : p.disabledText),
      ),
      overflow: TextOverflow.ellipsis,
      child: chosen?.child ?? widget.hint ?? const SizedBox(),
    );
    return MenuAnchor(
      childFocusNode: focus,
      // No clip: the Fluent menu shadow is painted outside the shape.
      clipBehavior: Clip.none,
      onOpen: () {
        open = true;
        _changed();
      },
      onClose: () {
        open = false;
        _changed();
      },
      menuChildren: [
        for (final item in widget.items)
          MenuEnter(
            child: MenuItemButton(
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
          ),
      ],
      builder: (context, controller, child) => AnimatedBuilder(
        animation: bar,
        builder: (context, child) =>
            AppFieldFrame(focus: bar.value, enabled: enabled, child: child!),
        child: TextButton(
          focusNode: focus,
          style: ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, fieldHeight(context))),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: Space.s12),
            ),
            backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            foregroundColor: WidgetStatePropertyAll(
              enabled ? p.text : p.disabledText,
            ),
            textStyle: WidgetStatePropertyAll(TextStyles.body1),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: WidgetStateProperty.resolveWith(
              (s) => ControlBorder(ring: keyboardRing(p, s)),
            ),
          ),
          onPressed: widget.onChanged == null
              ? null
              : () {
                  controller.isOpen ? controller.close() : controller.open();
                },
          child: Row(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              if (widget.isExpanded)
                Expanded(child: shown)
              else
                Flexible(child: shown),
              const SizedBox(width: Space.s8),
              Icon(
                AppIcons.expand,
                size: IconSizes.action,
                color: enabled ? p.text2 : p.disabledText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [AppSelect] in a form: label above and validation text below.
class AppSelectFormField<T> extends FormField<T> {
  AppSelectFormField({
    super.key,
    super.initialValue,
    FocusNode? focusNode,
    required List<DropdownMenuItem<T>> items,
    ValueChanged<T?>? onChanged,
    InputDecoration decoration = const InputDecoration(),
    super.validator,
  }) : super(
         builder: (state) => Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
             if (decoration.labelText != null) ...[
               Text(decoration.labelText!, style: TextStyles.body1),
               const SizedBox(height: Space.s4),
             ],
             AppSelect<T>(
               focusNode: focusNode,
               isExpanded: true,
               value: state.value,
               items: items,
               onChanged: onChanged == null
                   ? null
                   : (value) {
                       state.didChange(value);
                       onChanged(value);
                     },
             ),
             FieldMessage(
               error: decoration.errorText ?? state.errorText,
               helper: decoration.helperText,
             ),
           ],
         ),
       );
}

/// Fluent menu from an icon button. Destructive items (value 'delete') come
/// last after a group divider, in `dangerForeground`.
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
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final danger = menuItemStyle(p).copyWith(
      foregroundColor: WidgetStatePropertyAll(p.dangerForeground),
      iconColor: WidgetStatePropertyAll(p.dangerForeground),
    );
    return MenuAnchor(
      childFocusNode: focus,
      // No clip: the Fluent menu shadow is painted outside the shape.
      clipBehavior: Clip.none,
      menuChildren: [
        for (final item in widget.itemBuilder(context))
          if (item is PopupMenuDivider)
            const MenuEnter(child: MenuGroupDivider())
          else if (item is PopupMenuItem<T>) ...[
            if (item.value == 'delete')
              const MenuEnter(child: MenuGroupDivider()),
            MenuEnter(
              child: MenuItemButton(
                style: item.value == 'delete' ? danger : null,
                onPressed: !item.enabled
                    ? null
                    : () {
                        if (item.value != null) {
                          widget.onSelected(item.value as T);
                        }
                        focus.requestFocus();
                      },
                child: item.child ?? const SizedBox(),
              ),
            ),
          ],
      ],
      // IconButton keeps its own tooltip: it is also the reader label.
      builder: (context, controller, child) => IconButton(
        focusNode: focus,
        tooltip: widget.tooltip,
        icon: widget.icon,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// Fluent switch (#61): 40 x 20 track, round, 14 px thumb with a 3 px inset.
/// Off: 1 px `strokeAccessible` border, `muted` thumb. On: `brandBackground`
/// track, `onBrand` thumb. 200 ms easyEase. Label on the right, `body1`.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final enabled = onChanged != null;
    final duration = FoundationTokens.of(
      context,
    ).duration(context, MotionDurations.normal);
    final track = Container(
      width: Space.s40,
      height: Space.s20,
      decoration: BoxDecoration(
        color: !enabled
            ? (value ? p.disabledBackground : Colors.transparent)
            : value
            ? p.brandBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.circular),
        border: value
            ? null
            : Border.all(
                color: enabled ? p.strokeAccessible : p.disabledStroke,
              ),
      ),
      padding: const EdgeInsets.all(Space.s2 + Strokes.thin),
      child: AnimatedAlign(
        duration: duration,
        curve: MotionCurves.easyEase,
        alignment: value
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !enabled
                ? p.disabledText
                : value
                ? p.onBrand
                : p.muted,
          ),
        ),
      ),
    );
    return _Toggle(
      checked: value,
      enabled: enabled,
      onToggle: () => onChanged?.call(!value),
      isSwitch: true,
      label: label,
      radius: Radii.circular,
      control: track,
    );
  }
}

/// Fluent checkbox (#61): 16 x 16, radius 2, 1 px `strokeAccessible`;
/// checked: `brandBackground` with the `onBrand` 12 px checkmark.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final enabled = onChanged != null;
    final box = Container(
      width: Space.s16,
      height: Space.s16,
      decoration: BoxDecoration(
        color: !value
            ? Colors.transparent
            : enabled
            ? p.brandBackground
            : p.disabledBackground,
        borderRadius: BorderRadius.circular(Radii.small),
        border: value
            ? null
            : Border.all(
                color: enabled ? p.strokeAccessible : p.disabledStroke,
              ),
      ),
      child: value
          ? Icon(
              AppIcons.checkboxMark,
              size: 12,
              color: enabled ? p.onBrand : p.disabledText,
            )
          : null,
    );
    return _Toggle(
      checked: value,
      enabled: enabled,
      onToggle: () => onChanged?.call(!value),
      isSwitch: false,
      label: label,
      radius: Radii.small,
      control: box,
    );
  }
}

/// Keyboard, pointer and semantics for [AppSwitch] and [AppCheckbox].
class _Toggle extends StatefulWidget {
  const _Toggle({
    required this.checked,
    required this.enabled,
    required this.onToggle,
    required this.isSwitch,
    required this.label,
    required this.radius,
    required this.control,
  });
  final bool checked, enabled, isSwitch;
  final VoidCallback onToggle;
  final String? label;
  final double radius;
  final Widget control;
  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final ring =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Semantics(
      toggled: widget.isSwitch ? widget.checked : null,
      checked: widget.isSwitch ? null : widget.checked,
      enabled: widget.enabled,
      label: widget.label,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onToggle();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onToggle : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Controls.minTouch),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  foregroundPainter: ring
                      ? FocusRingPainter(
                          outer: p.focusOuter,
                          inner: p.focusInner,
                          radius: widget.radius,
                        )
                      : null,
                  child: widget.control,
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: Space.s8),
                  Flexible(
                    child: ExcludeSemantics(
                      child: Text(
                        widget.label!,
                        style: TextStyles.body1.copyWith(
                          color: widget.enabled ? p.text : p.disabledText,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
