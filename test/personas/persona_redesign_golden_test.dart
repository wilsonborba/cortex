import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;
import 'persona_test.dart' as fixture;

void main() {
  setUpAll(loadFonts);
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final mode in [
        'data',
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
          if (mode == 'empty' || mode == 'no_match') api.items.clear();
          if (mode == 'errors') api.rejects = 1;
          final route = ['new', 'errors'].contains(mode)
              ? '/v1/personas/new'
              : mode == 'edit'
              ? '/v1/personas/p1'
              : '/v1/personas';
          await fixture.pump(
            tester,
            api,
            path: route,
            brightness: brightness,
            size: Size(width, 1000),
          );
          if (mode == 'no_match') {
            await tester.enterText(
              find.byKey(const Key('persona-search')),
              'Missing example',
            );
            await tester.tap(find.byTooltip('Search personas'));
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
