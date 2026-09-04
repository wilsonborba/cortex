import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Reusable translucent glass card shared across the presentation layer.
///
/// On desktop (mouse input) it gains elevation and an accent glow on hover.
/// On mobile / touch it gives immediate tap feedback instead, since there is
/// no hover state to rely on.
class PremiumHoverCard extends StatefulWidget {
  const PremiumHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;

  @override
  State<PremiumHoverCard> createState() => _PremiumHoverCardState();
}

class _PremiumHoverCardState extends State<PremiumHoverCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? AppTheme.cardRadius;
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          transform: Matrix4.identity()
            ..scaleByDouble(
              _isPressed ? 0.98 : 1.0,
              _isPressed ? 0.98 : 1.0,
              1.0,
              1.0,
            ),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: isActive ? 0.72 : 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: scheme.onSurface.withValues(
                alpha: isActive ? 0.22 : 0.10,
              ),
              width: isActive ? 1.8 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: isActive ? 0.18 : 0.08),
                blurRadius: isActive ? 32 : 18,
                offset: Offset(0, isActive ? 12 : 6),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
