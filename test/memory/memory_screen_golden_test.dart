import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;
import 'memory_test.dart' as fixture;
import 'graph_fixtures.dart';

void main() {
  setUpAll(loadFonts);
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final mode in ['list', 'stack']) {
        testWidgets('memory $mode ${brightness.name} $width', (tester) async {
          final data = graphFixture(6, stack: true);
          final api = fixture.Api()
            ..custom = {
              'nodes': [
                for (final n in data.nodes)
                  {
                    'id': n.id,
                    'node_type': n.type,
                    'label': n.label,
                    'metadata': n.metadata,
                  },
              ],
              'edges': [
                for (final e in data.edges)
                  {
                    'source_id': e.source,
                    'target_id': e.target,
                    'edge_type': e.type,
                  },
              ],
              'truncated': false,
            };
          await fixture.pump(
            tester,
            api,
            size: Size(width, 1000),
            brightness: brightness,
          );
          if (mode == 'list') {
            await tester.tap(find.text('List'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              '../design/goldens/memory_${mode}_${brightness.name}_${width.toInt()}.png',
            ),
          );
        });
      }
    }
  }
}
