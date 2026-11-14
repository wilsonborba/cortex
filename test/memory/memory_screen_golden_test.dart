import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;
import 'memory_test.dart' as fixture;

/// Memory overview screenshots (cortex #65): summary and list, a group, the
/// detail with connections and usage, the tiny map, and the empty state.
void main() {
  setUpAll(loadFonts);
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 900.0, 1300.0]) {
      for (final mode in ['overview', 'group', 'detail', 'map', 'empty']) {
        testWidgets('memory $mode ${brightness.name} $width', (tester) async {
          final api = fixture.Api()..empty = mode == 'empty';
          final detail = mode == 'detail' || mode == 'map';
          await fixture.pump(
            tester,
            api,
            path: detail
                ? '/v1/settings/memory/${fixture.memoryId}'
                : '/v1/settings/memory',
            size: Size(width, 1000),
            brightness: brightness,
          );
          if (mode == 'group') {
            if (width < 600) {
              await tester.tap(find.byKey(const Key('memory-filters')));
              await tester.pumpAndSettle();
            } else if (width < 1000) {
              await tester.tap(find.byKey(const Key('memory-filters')));
              await tester.pumpAndSettle();
            }
            await tester.tap(find.byKey(const Key('facet-chat')).last);
            await tester.pumpAndSettle();
            if (width >= 600 && width < 1000) {
              await tester.tapAt(const Offset(5, 5));
              await tester.pumpAndSettle();
            }
            await tester.tap(find.byKey(const Key('group-${fixture.chatA}')));
            await tester.pumpAndSettle();
          }
          if (mode == 'map') {
            await tester.ensureVisible(find.byKey(const Key('memory-picture')));
            await tester.tap(find.byKey(const Key('memory-picture')));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.byKey(const Key('tiny-map')));
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
