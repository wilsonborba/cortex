// Tests MessageBubble's attachment rendering, in particular the historical
// (bytes-less) placeholder attachment produced by ChatService when a
// conversation is reloaded from GET /conversations/{id}.

import 'dart:typed_data';

import 'package:cortex/domain/models/attachment.dart';
import 'package:cortex/domain/models/chat_message.dart';
import 'package:cortex/presentation/frontend/components/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders a filename+icon chip for a placeholder attachment, without decoding an image or building an audio player',
    (tester) async {
      final message = ChatMessage(
        id: 'mem-1-u',
        role: MessageRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 9, 9),
        attachments: [
          ChatAttachment(
            id: 'historical-mem-1-u-report.pdf',
            filename: 'report.pdf',
            mimeType: 'application/pdf',
            bytes: Uint8List(0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message)),
        ),
      );
      await tester.pump();

      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'falls back to the filename chip for a placeholder audio attachment instead of an audio player',
    (tester) async {
      final message = ChatMessage(
        id: 'mem-2-u',
        role: MessageRole.user,
        content: '',
        createdAt: DateTime(2026, 9, 9),
        attachments: [
          ChatAttachment(
            id: 'historical-mem-2-u-note.mp3',
            filename: 'note.mp3',
            mimeType: 'audio/mpeg',
            bytes: Uint8List(0),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MessageBubble(message: message)),
        ),
      );
      await tester.pump();

      expect(find.text('note.mp3'), findsOneWidget);
      expect(find.byIcon(Icons.audiotrack_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
