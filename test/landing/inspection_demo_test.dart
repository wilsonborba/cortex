import 'package:cortex/dal/local/inspection_demo.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/answer_inspection.dart';
import 'package:cortex/presentation/frontend/screens/landing/inspection_demo.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget demo(String language, {Brightness brightness = Brightness.dark}) =>
    MaterialApp(
      theme: cortexTheme(brightness),
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: LandingInspectionDemo(),
        ),
      ),
    );

void main() {
  test('every sample is genuine recorded data that matches its text', () async {
    for (final code in ['en', 'pt', 'th']) {
      final (text, data) = await const InspectionDemoSource().load(code);
      expect(data.available, true, reason: code);
      expect(data.matches(text), true, reason: code);
      expect(data.tokens.every((t) => t.alternatives.length <= 5), true);
      expect(text, isNot(contains('—')));
    }
  });
  for (final language in ['en', 'pt', 'th']) {
    testWidgets('the $language sample follows the site language', (
      tester,
    ) async {
      await tester.pumpWidget(demo(language));
      await tester.pumpAndSettle();
      final (text, _) = InspectionDemoSource.cached(language)!;
      final inspection = tester.widget<InspectionAnswer>(
        find.byType(InspectionAnswer),
      );
      expect(inspection.controller.text, text);
      expect(inspection.onContinue, isNull, reason: 'no generation in demo');
    });
  }
  testWidgets('hover and click work on the static sample', (tester) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(demo('en'));
    await tester.pumpAndSettle();
    final c = tester
        .widget<InspectionAnswer>(find.byType(InspectionAnswer))
        .controller;
    final rich = find.descendant(
      of: find.byKey(const Key('inspection-text')),
      matching: find.byType(RichText),
    );
    final origin = tester.getTopLeft(rich);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: origin);
    await mouse.moveTo(origin + const Offset(40, 10));
    await tester.pump();
    expect(c.cursor, lessThan(c.spans.length - 1));
    await tester.tapAt(
      origin + const Offset(40, 10),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(c.pinned, true);
    expect(find.byKey(const Key('radar-continue')), findsNothing);
    await tester.tap(find.byKey(const Key('inspection-exit')));
    await tester.pumpAndSettle();
    expect((c.pinned, c.cursor), (false, c.spans.length - 1));
    await mouse.removePointer();
  });
  testWidgets('200 percent text at 390 px has no layout error', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 1600),
          textScaler: TextScaler.linear(2),
        ),
        child: demo('th', brightness: Brightness.light),
      ),
    );
    await tester.pumpAndSettle();
    final c = tester
        .widget<InspectionAnswer>(find.byType(InspectionAnswer))
        .controller;
    c.nextFork();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
