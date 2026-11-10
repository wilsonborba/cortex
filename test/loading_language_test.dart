import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/widgets/common/states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skeleton announces loading in EN, PT-BR and TH', (tester) async {
    final semantics = tester.ensureSemantics();

    for (final (locale, label) in [
      (const Locale('en'), 'Loading'),
      (const Locale('pt', 'BR'), 'Carregando'),
      (const Locale('th'), 'กำลังโหลด'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: SkeletonBox()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel(label), findsOneWidget);
      if (locale.languageCode != 'en') {
        expect(find.bySemanticsLabel('Loading'), findsNothing);
      }
    }
    semantics.dispose();
  });
}
