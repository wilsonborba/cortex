import 'dart:async';
import 'package:flutter/material.dart';
import '../../../dal/remote/cortex_api.dart';
import '../../../domain/models/output.dart';
import '../../../domain/services/answer_inspection_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../screens/chat/answer_inspection.dart';
import '../screens/chat/output_block.dart' show CopyMessageButton;
import '../widgets/common/buttons.dart';
import '../widgets/common/surfaces.dart';

Future<void> openAnswerInspection(
  BuildContext context, {
  required CortexApi api,
  required OutputView output,
  required bool temporary,
  String? sessionId,
}) async {
  final session = output.sessionId ?? sessionId;
  final id = output.outputId;
  final controller = AnswerInspectionController(
    text: output.answer.toString(),
    loader: temporary || session == null || id == null
        ? null
        : () => api.answerInspection(session, id),
  );
  unawaited(controller.load());
  try {
    await showAppDialog<void>(
      context,
      title: AppLocalizations.of(context).inspectionTitle,
      content: (_) => AnswerInspectionView(controller: controller),
      actions: (c) => [
        CopyMessageButton(text: controller.text),
        AppButton(
          label: AppLocalizations.of(c).close,
          onPressed: () => Navigator.of(c).pop(),
        ),
      ],
    );
  } finally {
    controller.dispose();
  }
}
