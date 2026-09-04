import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/logs.dart';
import '../../core/settings.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/execute_request.dart';
import '../../domain/models/execute_response.dart';
import 'credentials_client.dart';

/// Remote adapter for cortex_api, reached exclusively through api_for_apps'
/// public proxy at `AppSettings.cortexProxyPrefix` (see api_for_apps issue
/// #19, `src/presentation/routes/cortex_route.py`). This client never talks
/// to cortex_api directly for chat/execute traffic and never sends
/// `force_model`/`force_provider`/`tier` overrides: the proxy strips those
/// server-side, and this adapter simply does not expose any way to set them.
class CortexApiAdapter {
  CortexApiAdapter({
    this.apiForAppsBaseUrl = AppSettings.apiForAppsBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? createCredentialsClient();

  final String apiForAppsBaseUrl;
  final http.Client _httpClient;

  Uri get _chatCompletionsUri => Uri.parse(
    '$apiForAppsBaseUrl${AppSettings.cortexProxyPrefix}/v1/chat/completions',
  );

  Uri get _executeUri =>
      Uri.parse('$apiForAppsBaseUrl${AppSettings.cortexProxyPrefix}/execute');

  /// Streams assistant reply tokens for [messages] via cortex_api's OpenAI
  /// facade, `POST $cortexProxyPrefix/v1/chat/completions` with
  /// `stream: true`. Parses the upstream `text/event-stream` response
  /// (`chat.completion.chunk` frames, terminated by `data: [DONE]`)
  /// line-by-line as bytes arrive, yielding each non-empty content delta as
  /// soon as it is parsed, this is real incremental streaming, not a
  /// `Future.delayed` simulation.
  ///
  /// `model` is always [AppSettings.cortexTier0Model]: the proxy rewrites it
  /// to that value regardless of what is sent, and this client never offers
  /// any other model in its UI.
  Stream<String> streamChatCompletion({
    required List<ChatMessage> messages,
  }) async* {
    final request = http.Request('POST', _chatCompletionsUri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream'
      ..body = jsonEncode({
        'model': AppSettings.cortexTier0Model,
        'messages': messages
            .map((m) => {'role': _roleName(m.role), 'content': m.content})
            .toList(),
        'stream': true,
      });

    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _httpClient.send(request);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Chat completion streaming request failed',
        error: e,
        stackTrace: stackTrace,
      );
      throw CortexApiException('Could not reach the Cortex chat API: $e');
    }

    if (streamedResponse.statusCode != 200) {
      final body = await streamedResponse.stream.bytesToString();
      throw CortexApiException(
        'Chat completion request failed with status '
        '${streamedResponse.statusCode}: $body',
      );
    }

    final lines = streamedResponse.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (line.isEmpty) continue; // SSE frame separator, no payload
      if (!line.startsWith('data:')) continue;

      final data = line.substring(5).trim();
      if (data.isEmpty) continue;
      if (data == '[DONE]') break;

      Map<String, dynamic> chunk;
      try {
        chunk = jsonDecode(data) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.warning('Skipping malformed SSE chunk: $data');
        continue;
      }

      final choices = chunk['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) continue;
      final choice = choices.first as Map<String, dynamic>;
      final delta = choice['delta'] as Map<String, dynamic>?;
      final content = delta?['content'] as String?;
      if (content != null && content.isNotEmpty) {
        yield content;
      }
    }
  }

  /// Calls cortex_api's native `POST $cortexProxyPrefix/execute` for the
  /// "memory recall" enriched-execution path (opted into from the prompt
  /// dock). Mirrors cortex_api's real `ExecuteRequest`/`ExecuteResponse`
  /// schema (see `lib/presentation/api/schemas/execute.py`).
  Future<ExecuteResponse> execute(ExecuteRequest request) async {
    final http.Response response;
    try {
      response = await _httpClient.post(
        _executeUri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Execute request failed', error: e, stackTrace: stackTrace);
      throw CortexApiException('Could not reach the Cortex execute API: $e');
    }

    if (response.statusCode != 200) {
      throw CortexApiException(
        'Execute request failed with status ${response.statusCode}: '
        '${response.body}',
      );
    }

    return ExecuteResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  String _roleName(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }
}

/// Raised when the Cortex chat/execute API is unreachable or returns a
/// non-success status.
class CortexApiException implements Exception {
  CortexApiException(this.message);

  final String message;

  @override
  String toString() => 'CortexApiException: $message';
}
