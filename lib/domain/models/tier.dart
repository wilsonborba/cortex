import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Access tier describing which models and features a session may use.
///
/// Only Tier 0 exists today. Higher tiers, and the account/billing logic
/// that would unlock them, are out of scope for this issue: this model is a
/// static stub that issue #3 will replace with a real, backend-driven
/// value.
class AppTier {
  const AppTier({
    required this.level,
    required this.label,
    required this.isLocked,
  });

  final int level;

  /// Untranslated fallback label (used where a [BuildContext] is not
  /// available). Prefer [labelOf] in widgets so the tier name follows the
  /// app's selected language.
  final String label;
  final bool isLocked;

  /// The only tier currently available: free and fast, premium features
  /// visually locked in the UI.
  static const AppTier tier0 = AppTier(
    level: 0,
    label: 'Tier 0 - Free & Fast',
    isLocked: true,
  );

  /// Localized tier label, resolved through [AppLocalizations].
  String labelOf(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (level) {
      case 0:
        return l10n.tierZeroLabel;
      default:
        return label;
    }
  }
}
