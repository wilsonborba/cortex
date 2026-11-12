import 'package:cortex/presentation/frontend/screens/landing/code_snippet.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('public Rust source reaches a loaded readable state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: cortexTheme(Brightness.light),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: CodeSnippet(
              asset:
                  'lib/presentation/frontend/assets/snippets/scoped_names.rs.txt',
              path: 'synthetic/source.rs',
              caption: 'Synthetic source',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final future = tester
        .widget<FutureBuilder<TextSpan>>(find.byType(FutureBuilder<TextSpan>))
        .future;
    final span = await tester.runAsync(() => future!);
    final p = Palette.light;
    void neutral(TextSpan node) {
      if (node.style?.color case final Color color) {
        expect([p.text, p.muted], contains(color));
      }
      for (final child in node.children ?? <InlineSpan>[]) {
        if (child is TextSpan) neutral(child);
      }
    }

    neutral(span!);
    expect(span.toPlainText(), contains('pub async fn scoped_names'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('pub async fn scoped_names', findRichText: true),
      findsOneWidget,
    );
  });
}
