import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/buttons.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'components_golden_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  for (final mode in Brightness.values) {
    testWidgets('button states ${mode.name}', (tester) async {
      tester.view.physicalSize = const Size(1300, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controllers = <WidgetStatesController>[];
      Widget specimen(String name, ButtonKind kind, Set<WidgetState> state) {
        final controller = WidgetStatesController(state);
        controllers.add(controller);
        return AppButton(
          label: name,
          kind: kind,
          statesController: controller,
          onPressed: state.contains(WidgetState.disabled) ? null : () {},
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: cortexTheme(mode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final kind in ButtonKind.values) ...[
                    Text(kind.name),
                    Wrap(
                      spacing: 12,
                      children: [
                        specimen('Default', kind, {}),
                        specimen('Hover', kind, {WidgetState.hovered}),
                        specimen('Focus', kind, {WidgetState.focused}),
                        specimen('Pressed', kind, {WidgetState.pressed}),
                        specimen('Disabled', kind, {WidgetState.disabled}),
                        AppButton(
                          label: 'Working',
                          kind: kind,
                          busy: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  const AppInput(label: 'Input label', hint: 'Empty'),
                  const AppInput(
                    label: 'Input error',
                    error: 'Enter an example value',
                  ),
                  const AppInput(label: 'Disabled input', enabled: false),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    children: [
                      AppChip(label: 'Filter off', onSelected: (_) {}),
                      AppChip(
                        label: 'Filter on',
                        selected: true,
                        onSelected: (_) {},
                      ),
                      const AppChip(label: 'Disabled filter'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/control_states_${mode.name}.png'),
      );
      await tester.pumpWidget(const SizedBox());
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }
}
