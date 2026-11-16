import 'dart:math' as math;
import 'package:cortex/domain/models/answer_inspection.dart';
import 'package:cortex/domain/services/answer_inspection_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/answer_inspection.dart';
import 'package:cortex/presentation/frontend/screens/chat/inspection_controls.dart';
import 'package:cortex/presentation/frontend/screens/chat/inspection_rail.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'answer_inspection_test.dart' as fixture;

String sampleText(String language) => switch (language) {
  'pt' =>
    'Mira lê o mapa. O mapa mostra um rio. Mira segue o rio e volta para o mapa.',
  'th' => 'มีราอ่านแผนที่ แผนที่แสดงแม่น้ำ มีราเดินตามแม่น้ำแล้วกลับมาดูแผนที่',
  _ =>
    'Mira reads a map. The map shows a river. Mira follows the river and returns to the map.',
};
void main() {
  test('text matches use earlier visible text only', () {
    const text = 'map later map';
    final c = AnswerInspectionController(text: text)..reveal(3 / text.length);
    expect(c.earlierMatches, isEmpty);
    expect(c.focusMatch, isNull);
    c.reveal(1);
    expect(c.earlierMatches, isNotEmpty);
    final selected = c.focusMatch!;
    for (final match in c.earlierMatches) {
      expect(match.end, lessThanOrEqualTo(selected.start));
      expect(
        text.substring(match.start, match.end),
        text.substring(selected.start, selected.end),
      );
    }
    c.reveal(3 / text.length);
    expect(c.earlierMatches, isEmpty);
    c.dispose();
  });
  test('Thai matches do not require spaces and keep graphemes intact', () {
    const text = 'ต้นไม้ริมทางต้นไม้';
    final c = AnswerInspectionController(text: text)
      ..selectMode(InspectionMode.repeatedText);
    expect(c.earlierMatches, isNotEmpty);
    final selected = c.focusMatch!;
    expect(text.substring(selected.start, selected.end), 'ต้นไม้');
    expect(
      inspectionSpans(c, const TextStyle(), Palette.light).toPlainText(),
      text,
    );
    c.dispose();
  });
  test('dial and standard controls select the same read-only state', () {
    final c = AnswerInspectionController(text: 'map map map map map');
    final original = c.text;
    c.setDial(math.pi * 0.25, 1);
    expect(c.mode, InspectionMode.repeatedText);
    expect(c.detail, 5);
    c.selectMode(InspectionMode.predictions);
    expect(c.dialAngle, math.pi * 0.75);
    c.selectDetail(1);
    expect(c.dialDistance, 0);
    expect(c.earlierMatches.length, lessThanOrEqualTo(1));
    c.setDial(double.nan, 1);
    expect(c.detail, 1);
    expect(c.text, original);
    c.dispose();
  });
  test(
    'detail limits actual alternatives and never duplicates the chosen token',
    () {
      final c = AnswerInspectionController(
        text: 'x',
        initialData: fixture.fixtureData('x'),
      )..reveal(0);
      expect(c.alternatives.length, 3);
      expect(c.alternatives.any((v) => v.text == 'x'), false);
      c.selectDetail(5);
      expect(c.alternatives.length, 4);
      expect(c.alternatives.first.likelihood, closeTo(math.exp(-3), 0.000001));
      c.dispose();
    },
  );
  testWidgets(
    'pointer dial updates standard controls without changing the answer',
    (tester) async {
      final c = AnswerInspectionController(
        text: 'Synthetic map. Synthetic map.',
      );
      await tester.pumpWidget(fixture.app(InspectionControls(controller: c)));
      final dial = find.byKey(const Key('inspection-dial'));
      final rect = tester.getRect(dial);
      final touch = await tester.startGesture(
        rect.topLeft + Offset(rect.width * 0.8, rect.height * 0.5),
      );
      await touch.moveBy(const Offset(0, -20));
      await touch.up();
      await tester.pumpAndSettle();
      expect(c.mode, InspectionMode.repeatedText);
      expect(c.detail, inInclusiveRange(1, 5));
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, (c.detail - 1) / 4);
      expect(c.text, 'Synthetic map. Synthetic map.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final language in ['en', 'pt', 'th']) {
        for (final controls in [false, true]) {
          testWidgets(
            '${controls ? 'dial' : 'matches'} ${brightness.name} ${width.toInt()} $language',
            (tester) async {
              tester.view.physicalSize = Size(width, 1000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final text = sampleText(language);
              final c = AnswerInspectionController(
                text: text,
                initialData: fixture.fixtureData(text),
              )..selectMode(InspectionMode.repeatedText);
              await tester.pumpWidget(
                fixture.app(
                  Builder(
                    builder: (context) => AppDialog(
                      title: controls
                          ? AppLocalizations.of(context).inspectionControls
                          : AppLocalizations.of(context).inspectionTitle,
                      content: controls
                          ? InspectionControls(controller: c)
                          : AnswerInspectionView(controller: c),
                      actions: const [],
                    ),
                  ),
                  brightness: brightness,
                  language: language,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await expectLater(
                find.byType(Scaffold),
                matchesGoldenFile(
                  'goldens/${controls ? 'dial' : 'matches'}_${brightness.name}_${width.toInt()}_$language.png',
                ),
              );
              await tester.pumpWidget(const SizedBox());
              c.dispose();
            },
          );
          testWidgets(
            '${controls ? 'dial' : 'matches'} 200 percent ${brightness.name} ${width.toInt()} $language',
            (tester) async {
              tester.view.physicalSize = Size(width, 1000);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              final text = sampleText(language);
              final c = AnswerInspectionController(
                text: text,
                initialData: fixture.fixtureData(text),
              )..selectMode(InspectionMode.repeatedText);
              await tester.pumpWidget(
                fixture.app(
                  Builder(
                    builder: (context) => AppDialog(
                      title: AppLocalizations.of(context).inspectionControls,
                      content: controls
                          ? InspectionControls(controller: c)
                          : AnswerInspectionView(controller: c),
                      actions: const [],
                    ),
                  ),
                  brightness: brightness,
                  language: language,
                  scale: 2,
                ),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              await tester.pumpWidget(const SizedBox());
              c.dispose();
            },
          );
        }
      }
    }
  }
}
