import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../components/app_theme.dart';
import '../../components/premium_hover_card.dart';
import 'my_background.dart';

/// Playful entry point shown by [SessionGate] when no session and no guest
/// flag are present: the chromatic [MyBackground] animation runs behind a
/// centered hero card offering the two ways in, sign in with Asodya, or
/// continue anonymously.
///
/// The hero card's width is the only thing that meaningfully changes between
/// desktop and mobile, so a single screen file (with a [Responsive] check)
/// covers both instead of splitting into `desktop_`/`mobile_` variants.
class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onSignIn,
    required this.onContinueAsGuest,
  });

  final Future<void> Function() onSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MyBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isMobile ? 420 : 520),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: PremiumHoverCard(
                    padding: const EdgeInsets.all(32),
                    child: _LandingContent(
                      onSignIn: onSignIn,
                      onContinueAsGuest: onContinueAsGuest,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingContent extends StatelessWidget {
  const _LandingContent({
    required this.onSignIn,
    required this.onContinueAsGuest,
  });

  final Future<void> Function() onSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.landingTagline,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => onSignIn(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Text(l10n.signInWithAsodya),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onContinueAsGuest,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.controlRadius),
            ),
          ),
          child: Text(l10n.continueAsGuest),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.guestModeNotice,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
