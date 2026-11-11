import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test/chat/chat_test.dart' as chat;
import '../test/memory/memory_test.dart' as memory;
import '../test/design/components_golden_test.dart' as design;

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pump();
  final layer = tester.binding.renderViews.single.debugLayer! as OffsetLayer;
  await tester.runAsync(() async {
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    final image = await layer.toImage(Offset.zero & size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('/home/main-server/Documents/Others/Asodya/cortex/docs/ux-review-2026-11-12/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
void main() {
  setUpAll(design.loadFonts);
  testWidgets('capture synthetic chat and graph review', (tester) async {
    final fake = chat.Api();
    fake.page = {
      'chat': {'session_id': chat.sid, 'title': 'Cortex request flow'},
      'inputs': [{'input_id': 'review-input', 'text': 'How does Cortex use my files and memory?', 'created_at': '2026-11-12T02:20:00+07:00'}],
      'outputs': [{'input_id': 'review-input', 'output_id': chat.oid, 'status': 'done', 'text': '## Your context stays together\n\nCortex gathers file text, saved memories and web sources before it builds the prompt.\n\n1. Read the selected files.\n2. Find relevant memories.\n3. Keep the sources separate.\n4. Stream the answer to this conversation.\n\nYou can select this text, copy the answer, and continue the conversation.'}],
    };
    final (controller, _) = await chat.pump(tester, session: chat.sid, api: fake);
    await tester.pumpAndSettle();
    await capture(tester, 'chat-desktop');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await capture(tester, 'chat-compact');
    await chat.stopReconnecting(tester, controller);
    await memory.pump(tester, memory.Api()..isolated = true);
    await capture(tester, 'memory-isolated');
    expect(tester.takeException(), isNull);
  });
}
