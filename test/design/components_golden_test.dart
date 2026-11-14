import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../flutter_test_config.dart' show loadFonts;
export '../flutter_test_config.dart' show loadFonts;

void _noop(bool _) {}

/// Shared components on the plain reading surface, in both themes.
Widget gallery() => Scaffold(
  body: Padding(
    padding: const EdgeInsets.all(Space.s24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section title', style: TextStyles.title3),
        const SizedBox(height: Space.s16),
        Wrap(
          spacing: Space.s8,
          runSpacing: Space.s8,
          children: [
            AppButton.primary(label: 'Send', onPressed: () {}),
            AppButton(label: 'Cancel', onPressed: () {}),
            AppButton.destructive(label: 'Delete chat', onPressed: () {}),
            const AppButton(label: 'Disabled', onPressed: null),
            AppButton.primary(label: 'Busy', onPressed: () {}, busy: true),
          ],
        ),
        const SizedBox(height: Space.s16),
        const SizedBox(
          width: 360,
          child: AppInput(label: 'Title', hint: 'Write a title'),
        ),
        const SizedBox(height: Space.s8),
        const SizedBox(
          width: 360,
          child: AppInput(label: 'Name', error: 'The name is required'),
        ),
        const SizedBox(height: Space.s16),
        const Row(
          children: [
            AppChip(label: 'Fast', selected: true, onSelected: _noop),
            SizedBox(width: Space.s8),
            AppChip(label: 'Medium', onSelected: _noop),
          ],
        ),
        const SizedBox(height: Space.s16),
        const SizedBox(
          width: 360,
          child: AppCard(child: Text('A memory card with body text.')),
        ),
        const SizedBox(height: Space.s16),
        const SkeletonBox(width: 240),
        const SizedBox(height: Space.s16),
        const NoticeLine(message: 'Memory could not be loaded'),
        const NoticeLine(
          message: 'The file was not saved',
          kind: NoticeKind.error,
        ),
        const SizedBox(height: Space.s16),
        const OfflineBanner(message: 'You are offline'),
        const SizedBox(height: Space.s16),
        SizedBox(
          height: 140,
          child: ErrorState(
            message: 'Chats could not be loaded',
            retryLabel: 'Retry',
            onRetry: () {},
          ),
        ),
      ],
    ),
  ),
);

void main() {
  setUpAll(loadFonts);
  for (final brightness in Brightness.values) {
    testWidgets('components ${brightness.name}', (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: cortexTheme(brightness),
          home: gallery(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/components_${brightness.name}.png'),
      );
    });
  }
  testWidgets('a destructive confirm dialog is red and needs the confirm', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: cortexTheme(Brightness.dark),
        home: Builder(
          builder: (c) => AppButton(
            label: 'Delete',
            onPressed: () async => result = await showConfirmDialog(
              c,
              title: 'Delete the chat?',
              message: 'This cannot be undone.',
              confirm: 'Delete',
              cancel: 'Cancel',
              destructive: true,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    final confirm = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Delete').last,
        matching: find.byType(FilledButton),
      ),
    );
    expect(
      confirm.style!.backgroundColor!.resolve({}),
      Palette.dark.dangerSolid,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
