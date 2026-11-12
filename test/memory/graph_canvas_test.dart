import 'package:cortex/domain/models/memory_graph.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/memory/graph_canvas.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../design/components_golden_test.dart' show loadFonts;
import 'graph_fixtures.dart';

Future<GraphCanvasState> pumpCanvas(
  WidgetTester tester,
  MemoryGraphData data, {
  double width = 390,
  Brightness brightness = Brightness.light,
  String? selected,
  ValueChanged<String>? onSelect,
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: cortexTheme(brightness),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: GraphCanvas(
          data: data,
          selected: selected,
          onSelect: onSelect ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<GraphCanvasState>(find.byType(GraphCanvas));
}

void main() {
  setUpAll(loadFonts);
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAllTestValues(),
  );
  test('two static layouts are identical and retain every node', () {
    final data = graphFixture(200),
        a = graphPositions(data),
        b = graphPositions(data);
    expect(a, b);
    expect(a.length, 200);
    expect(a.values.every((p) => p.dx.isFinite && p.dy.isFinite), isTrue);
  });
  test('five equal titles under a chat produce one expandable stack', () {
    final data = graphFixture(6, stack: true), scene = GraphScene(data);
    expect(scene.nodes.length, 2);
    expect(scene.stacks.values.single.length, 5);
    expect(scene.edges.length, 1);
    final expanded = GraphScene(data, {scene.stacks.keys.single});
    expect(expanded.nodes.length, 6);
    expect(expanded.edges.length, 5);
  });
  for (final count in [1, 15, 100, 200]) {
    for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
      for (final loose in [false, true]) {
        testWidgets('fit includes all labels $count $width loose $loose', (
          tester,
        ) async {
          addTearDown(tester.view.reset);
          final state = await pumpCanvas(
            tester,
            graphFixture(count, loose: loose),
            width: width,
          );
          state.fit();
          await tester.pump();
          final framed = MatrixUtils.transformRect(
            state.transform.value,
            state.bounds,
          );
          expect(framed.left, greaterThanOrEqualTo(-.001));
          expect(framed.top, greaterThanOrEqualTo(-.001));
          expect(framed.right, lessThanOrEqualTo(state.viewport.width + .001));
          expect(
            framed.bottom,
            lessThanOrEqualTo(state.viewport.height + .001),
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets('theme locale and selection retain positions and matrix', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    final data = graphFixture(15),
        state = await pumpCanvas(tester, graphFixture(15));
    state.zoom(GraphTokens.labelScale);
    final positions = Map.of(state.positions),
        matrix = state.transform.value.clone();
    final after = await pumpCanvas(
      tester,
      data,
      brightness: Brightness.dark,
      locale: const Locale('th'),
      selected: 'synthetic-3',
    );
    expect(identical(state, after), isTrue);
    expect(after.positions, positions);
    expect(after.transform.value, matrix);
  });
  testWidgets('keyboard enters nodes and selects without a pointer', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    String? selected;
    final state = await pumpCanvas(
      tester,
      graphFixture(15),
      onSelect: (id) => selected = id,
    );
    state.focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 'synthetic-1');
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('dragging a node changes only its own position', (tester) async {
    addTearDown(tester.view.reset);
    final state = await pumpCanvas(tester, graphFixture(15));
    final initial = Map.of(state.positions),
        matrix = state.transform.value.clone();
    final origin = tester.getTopLeft(find.byType(InteractiveViewer));
    final point =
        origin +
        MatrixUtils.transformPoint(matrix, state.positions['synthetic-1']!);
    final gesture = await tester.startGesture(
      point,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(25, 10));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(state.positions['synthetic-1'], isNot(initial['synthetic-1']));
    for (final id in initial.keys.where((id) => id != 'synthetic-1')) {
      expect(state.positions[id], initial[id]);
    }
    expect(state.transform.value, matrix);
  });
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 768.0, 1024.0, 1300.0, 1440.0]) {
      for (final count in [0, 1, 15, 100]) {
        testWidgets('canvas golden $count ${brightness.name} $width', (
          tester,
        ) async {
          addTearDown(tester.view.reset);
          await pumpCanvas(
            tester,
            graphFixture(count),
            width: width,
            brightness: brightness,
          );
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              '../design/goldens/canvas_${count}_${brightness.name}_${width.toInt()}.png',
            ),
          );
        });
      }
      for (final mode in ['hover', 'selected']) {
        testWidgets('canvas $mode ${brightness.name} $width', (tester) async {
          addTearDown(tester.view.reset);
          final state = await pumpCanvas(
            tester,
            graphFixture(15),
            width: width,
            brightness: brightness,
            selected: mode == 'selected' ? 'synthetic-1' : null,
          );
          if (mode == 'hover') {
            final mouse = await tester.createGesture(
              kind: PointerDeviceKind.mouse,
            );
            await mouse.addPointer();
            await mouse.moveTo(
              tester.getTopLeft(find.byType(InteractiveViewer)) +
                  MatrixUtils.transformPoint(
                    state.transform.value,
                    state.positions['synthetic-1']!,
                  ),
            );
            await tester.pump();
          }
          await expectLater(
            find.byType(Scaffold),
            matchesGoldenFile(
              '../design/goldens/canvas_${mode}_${brightness.name}_${width.toInt()}.png',
            ),
          );
        });
      }
    }
  }
}
