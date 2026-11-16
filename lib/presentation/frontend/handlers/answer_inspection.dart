import 'dart:async';
import '../../../dal/remote/cortex_api.dart';
import '../../../domain/models/output.dart';
import '../../../domain/services/answer_inspection_controller.dart';

/// Start in-place inspection of one finished answer (cortex#77). Saved data
/// loads only now. Temporary answers have no saved data and show words only.
AnswerInspectionController startAnswerInspection({
  required CortexApi api,
  required OutputView output,
  required bool temporary,
  String? sessionId,
}) {
  final session = output.sessionId ?? sessionId;
  final id = output.outputId;
  final controller = AnswerInspectionController(
    text: output.answer.toString(),
    loader: temporary || session == null || id == null
        ? null
        : () => api.answerInspection(session, id),
  );
  unawaited(controller.load());
  return controller;
}
