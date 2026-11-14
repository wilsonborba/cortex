import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';

/// Fluent spinner (#61): 16 px with a 2 px stroke inline, 32 px with a 3 px
/// stroke for a page. Color `text` on a `divider` track, linear rotation.
/// With Reduce Motion it shows a still loading icon.
class AppSpinner extends StatelessWidget {
  const AppSpinner({super.key, this.page = false, this.label});
  final bool page;

  /// Accessible name. Defaults to "Loading".
  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final size = page ? Space.s32 : Space.s16;
    return Semantics(
      label:
          label ??
          Localizations.of<AppLocalizations>(
            context,
            AppLocalizations,
          )?.loading,
      child: SizedBox.square(
        dimension: size,
        child: MediaQuery.disableAnimationsOf(context)
            ? Icon(
                page ? AppIcons.large(AppIcons.loading) : AppIcons.loading,
                size: size,
                color: p.text,
              )
            : CircularProgressIndicator(
                strokeWidth: page ? Strokes.thicker : Strokes.thick,
                color: p.text,
                backgroundColor: p.divider,
                strokeCap: Strokes.cap,
              ),
      ),
    );
  }
}

/// Fluent progress bar (#61): 2 px (4 px for the page level), round ends,
/// `divider` track, brand fill. A null [value] is indeterminate.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, this.value, this.page = false});
  final double? value;
  final bool page;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return LinearProgressIndicator(
      value: MediaQuery.disableAnimationsOf(context) ? value ?? 0 : value,
      minHeight: page ? Strokes.thickest : Strokes.thick,
      color: p.brandBackground,
      backgroundColor: p.divider,
      borderRadius: BorderRadius.circular(Radii.circular),
    );
  }
}

/// Skeleton (#61): `tagBackground` with a neutral light band moving left to
/// right (1.5 s, linear). No brand color. No shimmer with Reduce Motion.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height = 16});
  final double? width;
  final double height;
  static const period = Duration(milliseconds: 1500);
  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: SkeletonBox.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.stop();
    } else if (!controller.isAnimating) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: AppLocalizations.of(context).loading,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.control),
            color: p.tagBackground,
            gradient: still
                ? null
                : LinearGradient(
                    colors: [p.tagBackground, p.background, p.tagBackground],
                    stops: const [0.3, 0.5, 0.7],
                    transform: _Slide(controller.value),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Moves the gradient band from one width left of the box to one width right.
class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (2 * t - 1), 0, 0);
}
