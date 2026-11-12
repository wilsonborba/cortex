import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/app_icons.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  for (final mode in Brightness.values) {
    for (final name in [
      'select',
      'choices',
      'chips',
      'notices',
      'list',
      'dialog',
      'loading',
    ]) {
      testWidgets('$name inventory ${mode.name}', (tester) async {
        if (name == 'dialog') {
          debugDisableShadows = false;
          addTearDown(() => debugDisableShadows = true);
        }
        tester.view.physicalSize = const Size(1300, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        Widget sample() => switch (name) {
          'select' => Column(
            children: [
              AppSelect<String>(
                value: 'one',
                items: const [
                  DropdownMenuItem(
                    value: 'one',
                    child: Text('Selected example'),
                  ),
                ],
                onChanged: (_) {},
              ),
              const AppSelect<String>(
                value: 'one',
                items: [
                  DropdownMenuItem(
                    value: 'one',
                    child: Text('Disabled example'),
                  ),
                ],
                onChanged: null,
              ),
            ],
          ),
          'choices' => Column(
            children: [
              SwitchListTile(
                title: const Text('Off'),
                value: false,
                onChanged: (_) {},
              ),
              SwitchListTile(
                title: const Text('On'),
                value: true,
                onChanged: (_) {},
              ),
              const SwitchListTile(
                title: Text('Disabled'),
                value: false,
                onChanged: null,
              ),
              CheckboxListTile(
                title: const Text('Unchecked'),
                value: false,
                onChanged: (_) {},
              ),
              CheckboxListTile(
                title: const Text('Checked'),
                value: true,
                onChanged: (_) {},
              ),
              const CheckboxListTile(
                title: Text('Disabled'),
                value: true,
                onChanged: null,
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'graph', label: Text('Graph')),
                  ButtonSegment(value: 'list', label: Text('List')),
                ],
                selected: const {'graph'},
                onSelectionChanged: (_) {},
              ),
            ],
          ),
          'chips' => Wrap(
            spacing: 12,
            children: [
              AppChip(label: 'Filter off', onSelected: (_) {}),
              AppChip(label: 'Filter on', selected: true, onSelected: (_) {}),
              const AppChip(label: 'Disabled filter'),
              InputChip(
                label: const Text('example.pdf, 12 KB'),
                avatar: const Icon(AppIcons.file),
                onDeleted: () {},
              ),
              const Chip(label: Text('Information')),
            ],
          ),
          'notices' => const Column(
            children: [
              NoticeLine(message: 'Example information'),
              NoticeLine(message: 'Example warning', kind: NoticeKind.warning),
              NoticeLine(message: 'Example failure', kind: NoticeKind.error),
              OfflineBanner(message: 'Example connection is unavailable'),
              Expanded(child: EmptyState(title: 'No data')),
              Expanded(child: EmptyState(title: 'No matches')),
              Expanded(
                child: EmptyState(
                  title: 'Service not available',
                  icon: AppIcons.error,
                ),
              ),
            ],
          ),
          'list' => Column(
            children: [
              ListTile(title: const Text('Default example'), onTap: () {}),
              ListTile(
                title: const Text('Selected example'),
                selected: true,
                onTap: () {},
              ),
              const ListTile(title: Text('Disabled example'), enabled: false),
            ],
          ),
          'dialog' => AlertDialog(
            title: const Text('Confirm example'),
            content: const Text('Synthetic dialog content.'),
            actions: [
              AppButton(label: 'Cancel', onPressed: () {}),
              AppButton.destructive(label: 'Delete', onPressed: () {}),
            ],
          ),
          _ => const Column(
            children: [
              SkeletonBox(width: 240),
              SizedBox(height: 24),
              CircularProgressIndicator(value: .5),
              SizedBox(height: 24),
              LinearProgressIndicator(value: .5),
            ],
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: cortexTheme(mode),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Padding(padding: const EdgeInsets.all(24), child: sample()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/control_${name}_${mode.name}.png'),
        );
        debugDisableShadows = true;
      });
    }
  }
}
