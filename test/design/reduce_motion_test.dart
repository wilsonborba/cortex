import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// #69 Reduce Motion check: with Reduce Motion on, the spinner, the skeleton
/// shimmer, the progress bar and the thinking pulse do not move, so the
/// frame scheduler goes quiet.
void main() {
  for (final brightness in Brightness.values) {
    testWidgets('no animation and no shimmer (${brightness.name})', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: cortexTheme(brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Column(
              children: [
                AppSpinner(),
                AppSpinner(page: true),
                SkeletonBox(width: 200),
                AppProgressBar(),
                PulsingDot(),
              ],
            ),
          ),
        ),
      );
      // pumpAndSettle fails when a ticker keeps running.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  }
}
