import 'dart:convert';
import 'dart:math' as math;
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/models/answer_inspection.dart';
import 'package:cortex/domain/models/output.dart';
import 'package:cortex/domain/services/answer_inspection_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/handlers/answer_inspection.dart';
import 'package:cortex/presentation/frontend/screens/chat/answer_inspection.dart';
import 'package:cortex/presentation/frontend/screens/chat/output_block.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Synthetic fork words: chosen likelihood, then alternatives.
const forks = {
  'map': [0.47, ' paper', 0.32, ' book', 0.11],
  'trees': [0.58, ' roots', 0.31, ' rocks', 0.06],
  'mapa': [0.47, ' papel', 0.32, ' livro', 0.11],
  'árvores': [0.58, ' raízes', 0.31, ' pedras', 0.06],
  'ต้นไม้ใ': [0.47, 'ป่าใกล้', 0.32, 'บ้านใ', 0.11],
  'อ่านแผ': [0.52, 'มองแผ', 0.33, 'ถือแผ', 0.09],
};

/// Synthetic recorded tokens: words with their leading space, punctuation
/// alone. Fork words get close alternatives; the rest are near certain.
AnswerInspectionData fixtureData(String text) {
  final tokens = <InspectionToken>[];
  var offset = 0;
  var n = 0;
  final pieces = <String>[];
  for (final m in RegExp(
    r'\s*[^\s.,:;]+|[.,:;]|\s+',
    unicode: true,
  ).allMatches(text)) {
    final piece = m.group(0)!;
    // Scripts without spaces (Thai) get short pieces, like real tokens.
    if (piece.characters.length <= 12 || forks.containsKey(piece.trim())) {
      pieces.add(piece);
      continue;
    }
    final chars = piece.characters.toList();
    for (var i = 0; i < chars.length; i += 4) {
      pieces.add(chars.sublist(i, math.min(i + 4, chars.length)).join());
    }
  }
  var index = 0;
  for (final piece in pieces) {
    final bytes = utf8.encode(piece);
    final thai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(piece);
    final fork =
        forks[piece.trim()] ??
        (thai && (index == 3 || index == 9)
            ? const [0.47, 'ป่าไม้', 0.32, 'บ้าน', 0.11]
            : null);
    index++;
    final chosen = fork == null ? 0.72 + (n++ % 7) * 0.04 : fork[0] as double;
    final alternatives = [InspectionAlternative(bytes, math.log(chosen))];
    if (fork != null) {
      for (var i = 1; i < fork.length; i += 2) {
        alternatives.add(
          InspectionAlternative(
            utf8.encode(fork[i] as String),
            math.log(fork[i + 1] as double),
          ),
        );
      }
    } else {
      alternatives.add(
        InspectionAlternative(utf8.encode(' the'), math.log((1 - chosen) / 2)),
      );
    }
    tokens.add(
      InspectionToken(
        bytes,
        math.log(chosen),
        offset,
        offset + bytes.length,
        alternatives,
      ),
    );
    offset += bytes.length;
  }
  return AnswerInspectionData(
    model: 'synthetic-model',
    reason: null,
    tokens: tokens,
  );
}

String sampleText(String language) => switch (language) {
  'pt' =>
    'Mira encontrou um mapa sob as árvores. Mira leu o mapa com cuidado.\n\nAs árvores do mapa ficam perto do rio. Este texto é um exemplo criado para o teste.',
  'th' =>
    'มีราพบแผนที่ใต้ต้นไม้ มีราอ่านแผนที่อย่างช้า ๆ\n\nต้นไม้ในแผนที่อยู่ใกล้แม่น้ำ นี่คือข้อความตัวอย่างสำหรับการทดสอบเท่านั้น',
  _ =>
    'Mira found a map beneath the trees. Mira read the map with care.\n\nThe trees on the map stand near the river. This is a synthetic example for testing.',
};

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

/// The chat column of the chat screen, with the rail gutter when it fits.
Widget column(Widget Function(double gutter) child) => LayoutBuilder(
  builder: (context, box) {
    final free = (box.maxWidth - 48 - Space.chatColumnWidth) / 2;
    final gutter = free >= Space.inspectionGutter
        ? Space.inspectionGutter
        : 0.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Space.chatColumnWidth + gutter * 2,
          ),
          child: Padding(
            padding: EdgeInsets.only(right: gutter),
            child: child(gutter),
          ),
        ),
      ),
    );
  },
);

OutputView doneOutput(String text) =>
    OutputView(outputId: 'output', status: 'done')
      ..sessionId = 'session'
      ..answer.write(text);

void main() {
  test('spans keep whole characters and join split byte tokens', () {
    const text = 'ก💡 x';
    final bytes = utf8.encode(text);
    final data = AnswerInspectionData(
      reason: null,
      tokens: [
        for (var i = 0; i < bytes.length; i++)
          InspectionToken([bytes[i]], -0.1, i, i + 1, const []),
      ],
    );
    final c = AnswerInspectionController(text: text, initialData: data);
    expect(c.spans.map((s) => s.text), ['ก', '💡', ' ', 'x']);
    expect(c.spans[1].certainty, closeTo(math.exp(-0.4), 1e-9));
    expect(c.spans[1].options, isEmpty, reason: 'joined tokens have no rank');
    expect(c.spans.last.tokenIndex, bytes.length - 1);
    c.dispose();
  });
  test('options are sorted, keep their saved rank and are not normalized', () {
    final c = AnswerInspectionController(
      text: sampleText('en'),
      initialData: fixtureData(sampleText('en')),
    );
    final map = c.spans.indexWhere((s) => s.text == ' map');
    final options = c.spans[map].options;
    expect(options.first.chosen, true);
    expect(options.first.likelihood, closeTo(0.47, 1e-9));
    expect(options[1].text, ' paper');
    expect(options[1].rank, 2);
    expect(c.spans[map].fork, true);
    expect(c.spans[map].otherLikelihood, closeTo(0.10, 1e-9));
    c.dispose();
  });
  test('summary: geometric average, lowest word, forks and token count', () {
    final data = fixtureData(sampleText('en'));
    final c = AnswerInspectionController(
      text: sampleText('en'),
      initialData: data,
    );
    final s = c.summary;
    final mean = math.exp(
      c.spans.fold<double>(0, (v, x) => v + math.log(x.certainty!)) /
          c.spans.length,
    );
    expect(s.average, closeTo(mean, 1e-9));
    expect(c.spans[s.lowest!].text.trim(), 'map');
    expect(s.forks, isNotEmpty);
    expect(s.forks.every((i) => c.spans[i].fork), true);
    expect(s.tokens, data.tokens.length);
    c.dispose();
  });
  test('without data the cursor moves by words and shows no values', () {
    const text = 'Synthetic answer, no data.';
    final c = AnswerInspectionController(text: text);
    expect(c.available, false);
    expect(c.spans.map((s) => s.text).join(), text);
    expect(c.spans.every((s) => s.certainty == null), true);
    expect(c.summary.average, isNull);
    c.openRadar();
    expect(c.radarOpen, false);
    c.dispose();
  });
  test('invalid saved data is not shown', () async {
    final c = AnswerInspectionController(
      text: 'other text',
      loader: () async => fixtureData(sampleText('en')),
    );
    await c.load();
    expect(c.data.reason, 'invalid_data');
    expect(c.available, false);
    final failed = AnswerInspectionController(
      text: 'x',
      loader: () async => throw StateError('offline'),
    );
    await failed.load();
    expect(failed.failed, true);
    c.dispose();
    failed.dispose();
  });
  test('cursor, pin, forks and lowest move without changing the text', () {
    final text = sampleText('pt');
    final c = AnswerInspectionController(
      text: text,
      initialData: fixtureData(text),
    );
    expect(c.cursor, c.spans.length - 1);
    c.moveTo(3);
    expect((c.cursor, c.pinned, c.moved), (3, false, true));
    c.step(1);
    expect((c.cursor, c.pinned), (4, true));
    c.nextFork();
    expect(c.current!.fork, true);
    expect(c.radarOpen, true);
    c.select(1);
    expect(c.picked, isNotNull);
    c.closeRadar(unpin: true);
    expect((c.radarOpen, c.pinned, c.pick), (false, false, null));
    c.showLowest();
    expect(c.cursor, c.summary.lowest);
    expect(c.text, text);
    c.dispose();
  });
  test('links use earlier words only and alternatives found earlier', () {
    const text = 'The river and the bridge. The bridge crossed the river.';
    final data = fixtureData(text);
    final c = AnswerInspectionController(text: text, initialData: data);
    final second = c.spans.lastIndexWhere((s) => s.word == 'river');
    final links = c.links(second);
    expect(links.map((l) => c.spans[l.span].word), ['river']);
    expect(links.every((l) => l.span < second), true);
    final first = c.spans.indexWhere((s) => s.word == 'river');
    expect(c.links(first), isEmpty);
    final the = c.spans.lastIndexWhere((s) => s.word == 'the');
    expect(c.links(the), isEmpty, reason: 'stop words have no links');
    c.dispose();
  });

  testWidgets('Inspect opens in place, follows the pointer and pins', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final requests = <http.Request>[];
    final text = sampleText('en');
    final api = CortexApi(
      baseUrl: 'https://api.test',
      client: MockClient((r) async {
        requests.add(r);
        final data = fixtureData(text);
        return http.Response(
          jsonEncode({
            'data': {
              'model': data.model,
              'reason': null,
              'tokens': [
                for (final t in data.tokens)
                  {
                    'start_byte': t.startByte,
                    'end_byte': t.endByte,
                    'bytes': t.bytes,
                    'logprob': t.logprob,
                    'alternatives': [
                      for (final a in t.alternatives)
                        {'bytes': a.bytes, 'logprob': a.logprob},
                    ],
                  },
              ],
            },
          }),
          200,
        );
      }),
    );
    final output = doneOutput(text);
    await tester.pumpWidget(
      app(
        column(
          (gutter) => OutputBlock(
            output: output,
            gutter: gutter,
            inspect: () => startAnswerInspection(
              api: api,
              output: output,
              temporary: false,
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('answer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inspect-answer')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.byKey(const Key('answer-inspection')), findsOneWidget);
    expect(find.byKey(const Key('answer')), findsNothing);
    expect(find.byKey(const Key('inspection-hint')), findsOneWidget);
    expect(find.byKey(const Key('inspection-average')), findsOneWidget);
    final state = tester.state<InspectionAnswerState>(
      find.byType(InspectionAnswer),
    );
    final c = state.widget.controller;
    expect(c.available, true);
    // Hover over the first word: the cursor follows without a click.
    final rich = find.descendant(
      of: find.byKey(const Key('inspection-text')),
      matching: find.byType(RichText),
    );
    final origin = tester.getTopLeft(rich.first);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: origin + const Offset(5, 8));
    await mouse.moveTo(origin + const Offset(8, 10));
    await tester.pump();
    expect(c.cursor, 0);
    expect(c.pinned, false);
    expect(find.byKey(const Key('inspection-hint')), findsNothing);
    // Pause opens the radar data state; a click pins and a second unpins.
    await tester.pump(const Duration(milliseconds: 700));
    expect(c.radarOpen, true);
    await mouse.moveTo(origin + const Offset(60, 10));
    await tester.pump();
    final hovered = c.cursor;
    expect(hovered, greaterThan(0));
    await tester.tapAt(
      origin + const Offset(60, 10),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(c.pinned, true);
    await mouse.moveTo(origin + const Offset(200, 10));
    await tester.pump();
    expect(c.cursor, hovered, reason: 'a pinned cursor does not follow');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(c.cursor, hovered + 1);
    // Ghost text after the cursor keeps the saved text in place.
    final paragraph = tester.widget<RichText>(rich.first);
    final children = (paragraph.text as TextSpan).children!;
    final p = Palette.light;
    expect((children.last as TextSpan).style?.color, InspectionTones.ghost(p));
    expect(children.map((s) => (s as TextSpan).text).join(), text);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(c.pinned, false);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('answer-inspection')), findsNothing);
    expect(find.byKey(const Key('answer')), findsOneWidget);
    expect(output.answer.toString(), text);
    expect(requests.length, 1);
    expect(requests.single.method, 'GET');
    expect(requests.single.url.path, endsWith('/inspection'));
    await mouse.removePointer();
    expect(tester.takeException(), isNull);
  });
  testWidgets('touch drag moves the cursor and release pins it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = sampleText('en');
    final c = AnswerInspectionController(
      text: text,
      initialData: fixtureData(text),
    );
    await tester.pumpWidget(
      app(column((_) => InspectionAnswer(controller: c, onExit: () {}))),
    );
    await tester.pumpAndSettle();
    final rich = find.descendant(
      of: find.byKey(const Key('inspection-text')),
      matching: find.byType(RichText),
    );
    final origin = tester.getTopLeft(rich.first);
    final gesture = await tester.startGesture(
      origin + const Offset(10, 10),
      kind: PointerDeviceKind.touch,
    );
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    final dragged = c.cursor;
    expect(c.pinned, false);
    await gesture.up();
    await tester.pump();
    expect(c.cursor, dragged);
    expect(c.pinned, true);
    expect(c.radarOpen, true);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('unavailable data keeps the word cursor and says why', (
    tester,
  ) async {
    final c = AnswerInspectionController(
      text: 'Synthetic answer without data.',
      initialData: const AnswerInspectionData(reason: 'not_supported'),
    );
    await tester.pumpWidget(
      app(column((_) => InspectionAnswer(controller: c, onExit: () {}))),
    );
    await tester.pumpAndSettle();
    expect(find.text('This model did not provide prediction data.'), findsOne);
    expect(find.byKey(const Key('inspection-average')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('radar: hover selects, ghost replaces, text stays saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = sampleText('en');
    final c = AnswerInspectionController(
      text: text,
      initialData: fixtureData(text),
    );
    InspectionOption? continued;
    Widget build({bool withContinue = false}) => app(
      column(
        (gutter) => InspectionAnswer(
          controller: c,
          onExit: () {},
          gutter: gutter,
          onContinue: withContinue ? (_, o) => continued = o : null,
        ),
      ),
    );
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    final map = c.spans.indexWhere((s) => s.text == ' map');
    c.moveTo(map, pin: true);
    c.openRadar();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspection-radar')), findsOneWidget);
    for (var k = 0; k < c.current!.options.length; k++) {
      expect(find.byKey(ValueKey('radar-option-$k')), findsOneWidget);
    }
    expect(find.textContaining('The model chose “map” with 47%'), findsOne);
    expect(find.text('Fork: the second option was close'), findsOne);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(
      tester.getCenter(find.byKey(const ValueKey('radar-option-1'))),
    );
    await tester.pumpAndSettle();
    expect(c.pick, 1);
    expect(c.cursor, map, reason: 'the radar area does not move the cursor');
    expect(find.byKey(const Key('radar-ghost')), findsOneWidget);
    expect(find.textContaining('also considered “paper”'), findsOne);
    expect(find.byKey(const Key('radar-continue')), findsNothing);
    await tester.pumpWidget(build(withContinue: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radar-continue')));
    expect(continued?.text, ' paper');
    expect(continued?.rank, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspection-radar')), findsNothing);
    expect(c.text, text);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('rail rows follow lines; a row goes to its weakest token', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = sampleText('en');
    final c = AnswerInspectionController(
      text: text,
      initialData: fixtureData(text),
    );
    await tester.pumpWidget(
      app(
        column(
          (gutter) =>
              InspectionAnswer(controller: c, onExit: () {}, gutter: gutter),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final state = tester.state<InspectionAnswerState>(
      find.byType(InspectionAnswer),
    );
    final lines = state.layout!.lines;
    expect(find.byKey(const ValueKey('rail-row-0')), findsOneWidget);
    expect(find.byKey(ValueKey('rail-row-${lines.length - 1}')), findsOne);
    await tester.tap(find.byKey(const ValueKey('rail-row-0')));
    await tester.pumpAndSettle();
    final first = lines.first.spans.where((i) => c.spans[i].hasWord);
    final weakest = first.reduce(
      (a, b) => c.spans[b].certainty! < c.spans[a].certainty! ? b : a,
    );
    expect(c.cursor, weakest);
    expect((c.pinned, c.radarOpen), (true, true));
    // A later repeated word links back and highlights the earlier word.
    final second = c.spans.lastIndexWhere((s) => s.word == 'trees');
    c.moveTo(second, pin: true);
    await tester.pumpAndSettle();
    final rich = tester.widget<RichText>(
      find.descendant(
        of: find.byKey(const Key('inspection-text')),
        matching: find.byType(RichText),
      ),
    );
    final children = (rich.text as TextSpan).children!;
    final firstTrees = c.spans.indexWhere((s) => s.word == 'trees');
    expect(
      (children[firstTrees] as TextSpan).style?.backgroundColor,
      InspectionTones.linkFill(Palette.light),
    );
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets('narrow width and 200 percent text keep rail and radar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final text = sampleText('pt');
    final c = AnswerInspectionController(
      text: text,
      initialData: fixtureData(text),
    );
    await tester.pumpWidget(
      app(
        column((_) => InspectionAnswer(controller: c, onExit: () {})),
        scale: 2,
      ),
    );
    await tester.pumpAndSettle();
    c.nextFork();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('inspection-radar')), findsOneWidget);
    expect(find.byKey(const ValueKey('rail-row-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  for (final brightness in Brightness.values) {
    for (final width in [390.0, 1300.0]) {
      for (final language in ['en', 'pt', 'th']) {
        testWidgets('in-place ${brightness.name} ${width.toInt()} $language', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 820);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final text = sampleText(language);
          final c = AnswerInspectionController(
            text: text,
            initialData: fixtureData(text),
          );
          final fork = c.summary.forks.first;
          c
            ..moveTo(fork, pin: true)
            ..openRadar()
            ..select(1);
          await tester.pumpWidget(
            app(
              column(
                (gutter) => InspectionAnswer(
                  controller: c,
                  onExit: () {},
                  gutter: gutter,
                  onContinue: (_, _) {},
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
              'goldens/inplace_${brightness.name}_${width.toInt()}_$language.png',
            ),
          );
          await tester.pumpWidget(const SizedBox());
          c.dispose();
        });
      }
    }
  }
}
