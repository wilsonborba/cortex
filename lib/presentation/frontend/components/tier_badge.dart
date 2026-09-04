import 'package:flutter/material.dart';

import '../../../domain/models/tier.dart';

/// Small badge that visibly marks the session as locked to Tier 0.
///
/// This is a static, mocked affordance: there is no account/billing backend
/// yet (that is issue #3). The badge is the point where a real tier value
/// will be plugged in later.
class TierBadge extends StatelessWidget {
  const TierBadge({super.key, this.tier = AppTier.tier0, this.dense = false});

  final AppTier tier;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tier.isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
            size: dense ? 12 : 14,
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            tier.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
