import '../../../../l10n/generated/app_localizations.dart';

/// The status line text from step and params (10.7.2): the frontend writes its
/// own language from the fixed step name.
String stepText(
  AppLocalizations l,
  String step,
  Map<String, dynamic> params,
  List<int>? progress,
) {
  final base = switch (step) {
    'web.queries' => l.steps_web_queries,
    'queue.wait' => l.steps_queue_wait,
    'model.load' => l.steps_model_load,
    'model.ready' => l.steps_model_ready,
    'security.ok' => l.steps_security_ok,
    'file.read.page' => l.steps_file_read_page,
    'file.ocr.page' => l.steps_file_ocr_page,
    'file.transcribe' => l.steps_file_transcribe,
    'memory.search' => l.steps_memory_search,
    'memory.found' => l.steps_memory_found,
    'web.search' => l.steps_web_search,
    'web.page.read' => l.steps_web_page_read,
    'chunks.selected' => l.steps_chunks_selected,
    'thinking.step' => l.steps_thinking_step,
    'thinking.stopped' => l.steps_thinking_stopped,
    _ => l.stepUnknown,
  };
  final detail = [
    for (final key in ['file', 'name', 'query', 'url', 'model', 'role'])
      if (params[key] != null)
        key == 'role' ? thinkingRole(l, '${params[key]}') : '${params[key]}',
  ].join(' ');
  final count = progress != null && progress.length == 2
      ? ' (${progress[0]} / ${progress[1]})'
      : '';
  return [base, if (detail.isNotEmpty) detail].join(': ') + count;
}

String thinkingRole(AppLocalizations l, String role) => switch (role) {
  'plan' => l.rolePlan,
  'work' => l.roleWork,
  'check' => l.roleCheck,
  _ => l.roleNotes,
};
String stageText(AppLocalizations l, String stage) => switch (stage) {
  'accept' => l.stageAccept,
  'gather' => l.stageGather,
  'assemble' => l.stageAssemble,
  'think' => l.stageThink,
  'answer' => l.stageAnswer,
  'save' => l.stageSave,
  _ => l.stepUnknown,
};
String stageStatus(AppLocalizations l, String status) => switch (status) {
  'started' => l.statusStarted,
  'done' => l.statusDone,
  'completed' => l.statusDone,
  'failed' => l.statusFailed,
  'cancelled' => l.statusCancelled,
  'skipped' => l.statusSkipped,
  _ => l.stepUnknown,
};
