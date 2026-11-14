import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;
import 'persona_test.dart' as fixture;

void main() {
  setUpAll(loadFonts);
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
      for (final mode in [
        'data',
        'detail',
        'empty',
        'no_match',
        'new',
        'edit',
        'errors',
      ]) {
        testWidgets('personas $mode ${brightness.name} $width', (tester) async {
          final api = fixture.Api()
            ..fields = [
              {
                'name': 'nickname',
                'type': 'string',
                'required': true,
                'in_context': true,
              },
            ];
          if (mode == 'empty') api.items.clear();
          if (mode == 'errors') api.rejects = 1;
          final route = ['new', 'errors'].contains(mode)
              ? '/v1/settings/personas/new'
              : mode == 'edit'
              ? '/v1/settings/personas/p1/edit'
              : mode == 'detail'
              ? '/v1/settings/personas/p1'
              : '/v1/settings/personas';
          await fixture.pump(
            tester,
            api,
            path: route,
            brightness: brightness,
            size: Size(width, 1000),
          );
          if (mode == 'no_match') {
            await tester.enterText(
              find.descendant(
                of: find.byKey(const Key('persona-search')),
                matching: find.byType(TextField),
              ),
              'Missing example',
            );
            await tester.testTextInput.receiveAction(TextInputAction.done);
            await tester.pumpAndSettle();
          }
          if (mode == 'errors') {
            await fixture.enter(tester, 'persona-name', 'Synthetic reader');
            await fixture.enter(tester, 'attribute-nickname', 'Typed value');
            await fixture.save(tester);
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../design/goldens/personas_${mode}_${brightness.name}_${width.toInt()}.png',
            ),
          );
        });
      }
    }
  }
}
