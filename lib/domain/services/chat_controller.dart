import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';
import '../models/output.dart';

class AttachedFile {
  AttachedFile(this.name, this.size, this.contentType, this.bytes);
  final String name;
  final int size;
  final String contentType;
  final List<int> bytes;
  String? fileId;
  int? errorNumber;
  String? errorMessage;
  bool uploading = false;
}

class Exchange {
  Exchange({
    required this.text,
    this.inputId,
    this.files = const [],
    required this.output,
  });
  final String text;
  final String? inputId;
  final List<String> files;
  final OutputView output;
}

enum WebChoice { off, fast, medium, deep }

/// Input options of the composer (30.2). Defaults: web off, memory off, thinking off.
class InputOptions {
  WebChoice web = WebChoice.off;
  bool memory = false;
  String? topic;
  bool thinking = false;
  String? personaId;
  Map<String, Object?> toBody() => {
    'needs_web': web != WebChoice.off,
    if (web != WebChoice.off) 'web_mode': web.name,
    'use_memory': memory,
    if (memory && topic != null && topic!.isNotEmpty) 'memory_topic': topic,
    'thinking': thinking,
  };
}

/// State of one chat screen (issue #30).
class ChatController extends ChangeNotifier {
  ChatController({
    required this.api,
    this.sessionId,
    this.temporary = false,
    this.reconnectDelay = const Duration(seconds: 2),
  });
  final CortexApi api;
  String? sessionId;
  final bool temporary;
  final Duration reconnectDelay;
  final exchanges = <Exchange>[];
  final files = <AttachedFile>[];
  final options = InputOptions();
  InputBudget budget = InputBudget.fallback;
  Map<String, dynamic>? chat;
  List<Map<String, dynamic>> personas = const [];
  bool loading = false;
  bool reconnecting = false;
  bool hasOlder = false;
  ApiError? loadError;
  StreamSubscription<ChatEvent>? _sub;
  bool _disposed = false;

  OutputView? get running =>
      exchanges.where((e) => e.output.running).lastOrNull?.output;
  bool get isNew => sessionId == null;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }

  Future<void> open() async {
    loading = true;
    _notify();
    try {
      budget = await api.budget();
    } catch (_) {}
    if (isNew && !temporary) {
      try {
        personas = await api.botPersonas();
      } catch (_) {}
    }
    if (sessionId != null) await _loadPage();
    loading = false;
    _notify();
    // Reconnect to a running output of this chat (10.4).
    final run = running;
    if (run != null && run.outputId != null && !temporary) {
      _follow(run, reconnect: true);
    }
  }

  Future<void> _loadPage({String? before}) async {
    try {
      final page = await api.page(sessionId!, before: before);
      chat = (page['chat'] as Map?)?.cast();
      final outputs = {
        for (final o in (page['outputs'] as List? ?? const []))
          o['input_id']: o,
      };
      final older = [
        for (final i in (page['inputs'] as List? ?? const []))
          Exchange(
            text: '${i['text']}',
            inputId: '${i['input_id']}',
            output: outputs[i['input_id']] == null
                ? OutputView(status: 'failed')
                : OutputView.fromHistory(
                    (outputs[i['input_id']] as Map).cast(),
                  ),
          ),
      ];
      hasOlder = older.length >= 20;
      exchanges.insertAll(0, older);
      loadError = null;
    } on ApiError catch (e) {
      loadError = e;
    }
  }

  Future<void> loadOlder() async {
    if (!hasOlder || exchanges.isEmpty) return;
    await _loadPage(before: exchanges.first.inputId);
    _notify();
  }

  int estimate(String text) => budget.estimate(utf8.encode(text).length);
  bool overLimit(String text) => estimate(text) > budget.maxTokens;

  /// Files go first through POST /files, then file_ids in the input (30.3).
  Future<void> attach(AttachedFile file) async {
    files.add(file..uploading = true);
    _notify();
    try {
      final result = await api.upload(
        file.name,
        file.bytes,
        file.contentType,
        temporary: temporary,
      );
      file.fileId = result.fileId;
      file.errorNumber = result.noticeNumber;
    } on ApiError catch (e) {
      file.errorNumber = e.number;
      file.errorMessage = e.message;
    }
    file.uploading = false;
    _notify();
  }

  void removeFile(AttachedFile file) {
    files.remove(file);
    _notify();
  }

  Future<void> send(String text) async {
    if (running != null || overLimit(text) || files.any((f) => f.uploading)) {
      return;
    }
    final ids = [
      for (final f in files)
        if (f.fileId != null) f.fileId!,
    ];
    final names = [
      for (final f in files)
        if (f.fileId != null) f.name,
    ];
    final output = OutputView();
    exchanges.add(Exchange(text: text, files: names, output: output));
    final body = <String, Object?>{
      'text': text,
      'file_ids': ids,
      ...options.toBody(),
    };
    if (isNew) {
      body['app_id'] = CortexApi.appId;
      if (temporary) body['temporary'] = true;
      if (options.personaId != null && !temporary) {
        body['persona_id'] = options.personaId;
      }
    }
    files.clear();
    _notify();
    _listen(output, api.input(session: sessionId, body: body));
  }

  void _listen(OutputView output, Stream<ChatEvent> stream) {
    _sub?.cancel();
    var ended = false;
    _sub = stream.listen(
      (e) {
        if (e.name == 'done') {
          sessionId ??= e.data['session_id'] as String?;
          output.outputId ??= e.data['output_id'] as String?;
        }
        ended = output.apply(e) || ended;
        if (e.name == 'stage' &&
            e.data['stage'] == 'accept' &&
            e.data['status'] != 'started' &&
            e.data['status'] != 'failed') {
          _resolveIds(output);
        }
        _notify();
      },
      onError: (Object error) {
        if (error is ApiError) {
          output
            ..errorNumber = error.number
            ..errorMessage = error.message
            ..status = 'failed';
          ended = true;
          _notify();
        } else {
          _lost(output);
        }
      },
      onDone: () {
        if (!ended) _lost(output);
      },
    );
  }

  /// The stream sends the ids only in `done`; Stop and reconnect need them
  /// earlier, so they come from the aligned running list and chat page (10.4.4).
  Future<void> _resolveIds(OutputView output) async {
    if (output.outputId != null || temporary) return;
    try {
      if (sessionId == null) {
        final running = await api.chats(running: true);
        running.sort(
          (a, b) => '${b['updated_at']}'.compareTo('${a['updated_at']}'),
        );
        sessionId = running.firstOrNull?['session_id'] as String?;
        chat = running.firstOrNull;
      }
      if (sessionId == null) return;
      final page = await api.page(sessionId!, limit: 1);
      final out = (page['outputs'] as List? ?? const [])
          .where((o) => o['status'] == 'running')
          .lastOrNull;
      output.outputId ??= out?['output_id'] as String?;
      chat ??= (page['chat'] as Map?)?.cast();
      _notify();
    } catch (_) {}
  }

  /// A lost connection: the banner shows and the events replay with ?after (10.4).
  Future<void> _lost(OutputView output) async {
    // The ids may not be known yet when the connection drops early.
    if (!temporary && output.outputId == null) await _resolveIds(output);
    if (temporary || sessionId == null || output.outputId == null) {
      output.status = 'failed';
      _notify();
      return;
    }
    reconnecting = true;
    _notify();
    Future.delayed(reconnectDelay, () {
      if (!_disposed) _follow(output, reconnect: true);
    });
  }

  void _follow(OutputView output, {bool reconnect = false}) {
    reconnecting = reconnect;
    _notify();
    final stream = api.events(
      sessionId!,
      output.outputId!,
      after: output.lastEventId,
    );
    _listen(
      output,
      stream.map((e) {
        if (reconnecting) {
          reconnecting = false;
        }
        return e;
      }),
    );
  }

  /// Stop = PATCH {"status": "cancelled"} (30.7).
  Future<void> stop() async {
    final run = running;
    if (run?.outputId == null || sessionId == null) {
      return;
    }
    await api.cancel(sessionId!, run!.outputId!);
  }

  /// Stop thinking = PATCH {"thinking": false} (30.5.b).
  Future<void> stopThinking() async {
    final run = running;
    if (run?.outputId == null || sessionId == null) {
      return;
    }
    await api.stopThinking(sessionId!, run!.outputId!);
  }

  Future<void> rename(String title) async {
    chat = await api.patchChat(sessionId!, {'title': title});
    _notify();
  }

  Future<void> togglePin() async {
    chat = await api.patchChat(sessionId!, {
      'is_pinned': !(chat?['is_pinned'] == true),
    });
    _notify();
  }

  Future<void> delete() => api.deleteChat(sessionId!);
}
