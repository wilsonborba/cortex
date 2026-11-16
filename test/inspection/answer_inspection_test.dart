import 'package:flutter/services.dart';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/presentation/frontend/handlers/answer_inspection.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/answer_inspection.dart';
import 'package:cortex/domain/services/answer_inspection_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/answer_inspection.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/widgets/common/surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AnswerInspectionData fixtureData(String text) {
  var offset = 0;
  final tokens = <InspectionToken>[];
  for (final rune in text.runes) {
    final bytes = utf8.encode(String.fromCharCode(rune));
    tokens.add(
      InspectionToken(bytes, -0.2, offset, offset + bytes.length, [
        InspectionAlternative(bytes, -0.2),
        for (var i = 0; i < 4; i++)
          InspectionAlternative(
            utf8.encode([' tree', ' path', ' river', ' map'][i]),
            -3.0 - i,
          ),
      ]),
    );
    offset += bytes.length;
  }
  return AnswerInspectionData(
    model: 'synthetic-model',
    reason: null,
    tokens: tokens,
  );
}

Widget app(
  Widget child, {
  Brightness brightness = Brightness.light,
  String language = 'en',
  double scale = 1,
}) => MaterialApp(
  theme: cortexTheme(brightness),
  locale: Locale(language),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);
void main() {
  test(
    'replay preserves the original and respects combined Unicode characters',
    () {
      const text = 'Olá ก้ 👨‍👩‍👧‍👦 café';
      final c = AnswerInspectionController(text: text);
      final seen = <String>{};
      for (var i = 0; i <= 100; i++) {
        c.reveal(i / 100);
        seen.add(c.visibleText);
        expect(utf8.decode(utf8.encode(c.visibleText)), c.visibleText);
      }
      expect(seen.any((s) => s.endsWith('ก')), false);
      expect(seen.any((s) => s.endsWith('👨')), false);
      c.reveal(0);
      expect(c.visibleText, '');
      c.reveal(1);
      expect(c.visibleText, text);
      expect(c.text, text);
      c.dispose();
    },
  );
  test(
    'real token boundaries map raw UTF-8 fragments to safe display positions',
    () {
      const text = 'ก💡';
      final bytes = utf8.encode(text);
      final tokens = <InspectionToken>[];
      for (var i = 0; i < bytes.length; i++) {
        tokens.add(InspectionToken([bytes[i]], -1, i, i + 1, const []));
      }
      final c = AnswerInspectionController(
        text: text,
        initialData: AnswerInspectionData(
          model: 'synthetic',
          reason: null,
          tokens: tokens,
        ),
      );
      c.reveal(0.5);
      expect(c.visibleText, 'ก');
      expect(c.cursor.byte, 3);
      expect(c.nextToken!.startByte, 3);
      c.step(1);
      expect(c.visibleText, text);
      expect(c.nextToken, isNull);
      c.dispose();
    },
  );
  test('progress measures revealed characters instead of token count', () {
    const text = 'abcdefghij x';
    final data = AnswerInspectionData(
      reason: null,
      tokens: [
        InspectionToken(utf8.encode('abcdefghij'), -0.2, 0, 10, const []),
        InspectionToken(utf8.encode(' x'), -0.2, 10, 12, const []),
      ],
    );
    final c = AnswerInspectionController(text: text, initialData: data)
      ..reveal(0.7);
    expect(c.visibleText, 'abcdefghij');
    expect(c.fraction, closeTo(10 / 12, 0.000001));
    c.dispose();
  });
  test('probabilities are not normalized over the displayed alternatives', () {
    final data = fixtureData('x');
    expect(
      data.tokens.first.otherAlternatives.first.likelihood,
      closeTo(0.049787, 0.000001),
    );
    expect(
      data.tokens.first.alternatives.fold<double>(
        0,
        (v, a) => v + a.likelihood,
      ),
      lessThan(1),
    );
  });
  test(
    'read errors can retry and mismatched records cannot create predictions',
    () async {
      var calls = 0;
      final c = AnswerInspectionController(
        text: 'answer',
        loader: () async {
          calls++;
          if (calls == 1) throw StateError('synthetic error');
          return fixtureData('different');
        },
      );
      await c.load();
      expect(c.failed, true);
      await c.load();
      expect(c.failed, false);
      expect(c.data.reason, 'invalid_data');
      expect(c.data.tokens, isEmpty);
      expect(c.text, 'answer');
      c.dispose();
    },
  );
  test('closing during a read does not update a disposed controller', () async {
    final pending = Completer<AnswerInspectionData>();
    final c = AnswerInspectionController(
      text: 'x',
      loader: () => pending.future,
    );
    final future = c.load();
    c.dispose();
    pending.complete(fixtureData('x'));
    await future;
  });
  test('typed client makes only the scoped read request', () async {
    final requests = <http.Request>[];
    final api = CortexApi(
      baseUrl: 'https://api.test',
      client: MockClient((r) async {
        requests.add(r);
        return http.Response(
          jsonEncode({
            'data': {
              'model': 'synthetic',
              'reason': 'not_recorded',
              'tokens': [],
            },
          }),
          200,
        );
      }),
    );
    final data = await api.answerInspection('session', 'output');
    expect(data.available, false);
    expect(requests.single.method, 'GET');
    expect(
      requests.single.url.path,
      '/chats/session/outputs/output/inspection',
    );
  });
  testWidgets(
    'slider, circle and selection preserve text without another read',
    (tester) async {
      var reads = 0;
      const text = 'Synthetic answer. A synthetic answer stays unchanged.';
      final c = AnswerInspectionController(
        text: text,
        loader: () async {
          reads++;
          return fixtureData(text);
        },
      );
      await c.load();
      await tester.pumpWidget(app(AnswerInspectionView(controller: c)));
      final originalHeight = tester
          .getSize(find.byKey(const Key('inspection-text-area')))
          .height;
      await tester.drag(find.byType(Slider), const Offset(-160, 0));
      await tester.pump();
      expect(c.fraction, lessThan(1));
      expect(c.text, text);
      expect(reads, 1);
      expect(
        tester.getSize(find.byKey(const Key('inspection-text-area'))).height,
        originalHeight,
      );
      await tester.drag(
        find.byKey(const Key('inspection-handle')),
        const Offset(0, 40),
      );
      await tester.pump();
      c.reveal(1);
      await tester.pump();
      expect(c.visibleText, text);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Inspect opens a read-only dialog; keyboard, copy and Escape work',
    (tester) async {
      var reads = 0;
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String?;
          }
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final api = CortexApi(
        baseUrl: 'https://api.test',
        client: MockClient((r) async {
          reads++;
          expect(r.method, 'GET');
          return http.Response(
            jsonEncode({
              'data': {'model': '', 'reason': 'not_recorded', 'tokens': []},
            }),
            200,
          );
        }),
      );
      const text = 'Synthetic original answer. This answer stays unchanged.';
      final output = OutputView(outputId: 'output', status: 'done')
        ..sessionId = 'session'
        ..answer.write(text);
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => OutputBlock(
              output: output,
              onInspect: () => openAnswerInspection(
                context,
                api: api,
                output: output,
                temporary: false,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('inspect-answer')));
      await tester.pumpAndSettle();
      expect(find.byType(AnswerInspectionView), findsOneWidget);
      expect(reads, 1);
      final slider = find.byType(Slider);
      await tester.tap(slider);
      await tester.pump();
      final before = tester.widget<Slider>(slider).value;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(tester.widget<Slider>(slider).value, lessThan(before));
      final controller = tester
          .widget<AnswerInspectionView>(find.byType(AnswerInspectionView))
          .controller;
      await tester.tap(find.text('Inspection controls').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspection-dial')), findsOneWidget);
      await tester.tap(find.byKey(const Key('inspection-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Repeated text').last);
      await tester.pumpAndSettle();
      expect(controller.mode, InspectionMode.repeatedText);
      expect(reads, 1);
      expect(output.answer.toString(), text);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inspection-dial')), findsNothing);
      await tester.tap(find.byType(CopyMessageButton).last);
      await tester.pumpAndSettle();
      expect(clipboard, text);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AnswerInspectionView), findsNothing);
      expect(output.answer.toString(), text);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final language in ['en', 'pt', 'th']) {
        testWidgets('replay ${brightness.name} ${width.toInt()} $language', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final text = switch (language) {
            'th' =>
              'มีราพบแผนที่ใต้ต้นไม้ มีราอ่านแผนที่อย่างช้า ๆ\n\nต้นไม้ในแผนที่อยู่ใกล้แม่น้ำ นี่คือข้อความตัวอย่างสำหรับการทดสอบเท่านั้น',
            'pt' =>
              'Mira encontrou um mapa sob as árvores. Mira leu o mapa com cuidado.\n\nAs árvores do mapa ficam perto do rio. Este texto é um exemplo criado para o teste.',
            _ =>
              'Mira found a map beneath the trees. Mira read the map with care.\n\nThe trees on the map stand near the river. This is a synthetic example for testing.',
          };
          final c = AnswerInspectionController(
            text: text,
            initialData: fixtureData(text),
          )..reveal(0.5);
          await tester.pumpWidget(
            app(
              Builder(
                builder: (context) => AppDialog(
                  title: AppLocalizations.of(context).inspectionTitle,
                  content: AnswerInspectionView(
                    controller: c,
                    onControls: () => openInspectionControls(context, c),
                  ),
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
              'goldens/replay_${brightness.name}_${width.toInt()}_$language.png',
            ),
          );
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
        testWidgets(
          'replay 200 percent ${brightness.name} ${width.toInt()} $language',
          (tester) async {
            tester.view.physicalSize = Size(width, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final c = AnswerInspectionController(
              text: 'Synthetic text without recorded model data.',
              initialData: fixtureData(
                'Synthetic text without recorded model data.',
              ),
            );
            await tester.pumpWidget(
              app(
                Builder(
                  builder: (context) => AppDialog(
                    title: AppLocalizations.of(context).inspectionTitle,
                    content: AnswerInspectionView(
                      controller: c,
                      onControls: () => openInspectionControls(context, c),
                    ),
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
