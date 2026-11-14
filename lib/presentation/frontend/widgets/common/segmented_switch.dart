import 'package:flutter/material.dart';
import '../../theme/tokens.dart';
import 'surfaces.dart';

/// One option of a [SegmentedSwitch]: a short text or a 16 px icon, and the
/// tooltip that is also the reader label.
class SegmentOption<T> {
  const SegmentOption({
    required this.value,
    required this.tooltip,
    this.text,
    this.icon,
  });
  final T value;
  final String tooltip;
  final String? text;
  final IconData? icon;
}

/// The segmented switch of the Asodya apps (#62): height 28, 1 px `stroke`,
/// radius 4, padding 2. Each option has padding 4 x 10 and `caption1Strong`.
/// The selected option is inverse: `text` fill with `background` text, 150 ms.
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Reader label of the whole group (for example "Language").
  final String label;
  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) == true;
    return Semantics(
      container: true,
      label: label,
      child: Container(
        height: Space.s28,
        padding: const EdgeInsets.all(Space.s2),
        decoration: BoxDecoration(
          border: Border.all(color: p.stroke, width: Strokes.thin),
          borderRadius: BorderRadius.circular(Radii.control),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              _Segment(
                option: o,
                selected: o.value == selected,
                duration: reduce ? Duration.zero : MotionDurations.fast,
                onTap: () => onChanged(o.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.option,
    required this.selected,
    required this.duration,
    required this.onTap,
  });
  final SegmentOption<T> option;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final color = selected ? p.background : p.text2;
    return AppTooltip(
      message: option.tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        label: option.tooltip,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.small),
            hoverColor: selected ? Colors.transparent : p.subtleHover,
            splashFactory: NoSplash.splashFactory,
            child: AnimatedContainer(
              duration: duration,
              curve: MotionCurves.easyEase,
              padding: const EdgeInsets.symmetric(
                horizontal: Space.s10,
                vertical: Space.s4,
              ),
              decoration: BoxDecoration(
                color: selected ? p.text : Colors.transparent,
                borderRadius: BorderRadius.circular(Radii.small),
              ),
              child: option.icon != null
                  ? Icon(option.icon, size: IconSizes.small, color: color)
                  : Text(
                      option.text ?? '',
                      style: TextStyles.caption1Strong.copyWith(color: color),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
