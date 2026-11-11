import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/chat_controller.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/chat/chat_screen.dart';
import 'package:cortex/presentation/frontend/screens/chat/composer.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'chat_test.dart' as fixture;

void main() {
  testWidgets(
    'Enter leaves composing input to the IME and sends after composition',
    (tester) async {
      final (chat, api) = await fixture.pump(tester);
      final state = tester.state<ComposerState>(find.byType(Composer));
      await tester.tap(find.byKey(const Key('composer-text')));
      state.text.value = const TextEditingValue(
        text: 'ทดสอบ',
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 0, end: 5),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        api.requests.where((r) => r.$1 == 'POST' && r.$2 == '/chats'),
        isEmpty,
      );
      state.text.value = state.text.value.copyWith(composing: TextRange.empty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        api.requests.where((r) => r.$1 == 'POST' && r.$2 == '/chats'),
        hasLength(1),
      );
      await fixture.stopReconnecting(tester, chat);
    },
  );
  testWidgets('Send and Stop share the same rectangle', (tester) async {
    final api = fixture.Api()..keepOpen = true;
    api.streamFor = (_) => fixture.stream(done: false);
    final (chat, _) = await fixture.pump(tester, api: api);
    await tester.enterText(
      find.byKey(const Key('composer-text')),
      'Synthetic request',
    );
    await tester.pump();
    final before = tester.getRect(
      find.byKey(const Key('composer-action-slot')),
    );
    await tester.tap(find.byKey(const Key('send')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('stop')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('composer-action-slot'))),
      before,
    );
    await fixture.stopReconnecting(tester, chat);
  });
  testWidgets(
    'a failed request restores the original text before the answer starts',
    (tester) async {
      final api = fixture.Api();
      api.streamFor = (_) => const [];
      final (chat, _) = await fixture.pump(tester, api: api);
      const raw = '  Synthetic draft\nwith another line  ';
      await fixture.send(tester, raw);
      final state = tester.state<ComposerState>(find.byType(Composer));
      expect(state.text.text, raw);
      await fixture.stopReconnecting(tester, chat);
    },
  );
  testWidgets('pasted multiline text does not send itself', (tester) async {
    final (chat, api) = await fixture.pump(tester);
    await tester.enterText(
      find.byKey(const Key('composer-text')),
      'First line\nSecond line\nThird line',
    );
    await tester.pump();
    expect(
      api.requests.where((r) => r.$1 == 'POST' && r.$2 == '/chats'),
      isEmpty,
    );
    expect(
      tester.state<ComposerState>(find.byType(Composer)).text.text,
      contains('\n'),
    );
    await fixture.stopReconnecting(tester, chat);
  });
  for (final locale in [const Locale('pt', 'BR'), const Locale('th')]) {
    testWidgets(
      'compact composer at 200 percent in $locale with files and long text',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final fake = fixture.Api();
        final api = CortexApi(
          baseUrl: 'https://api.test/apps/cortex/v1',
          client: fake.client,
        );
        final chat = ChatController(api: api);
        chat.options
          ..memory = true
          ..thinking = true
          ..web = WebChoice.fast;
        chat.files.addAll([
          for (var i = 0; i < 3; i++)
            AttachedFile(
              'synthetic-example-$i.pdf',
              1024,
              'application/pdf',
              List.filled(1024, 0),
            )..fileId = 'synthetic-file-$i',
        ]);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            theme: cortexTheme(Brightness.dark),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: ChatScreen(
                api: api,
                controller: chat,
                details: DetailsController(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('composer-text')),
          List.filled(8, 'ข้อความตัวอย่างสำหรับการทดสอบ').join('\n'),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('composer-options')), findsOneWidget);
        expect(
          tester.getRect(find.byKey(const Key('composer-action-slot'))).bottom,
          lessThanOrEqualTo(844),
        );
        await tester.pumpWidget(const SizedBox());
        chat.dispose();
      },
    );
  }
}
