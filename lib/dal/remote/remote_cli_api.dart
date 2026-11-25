import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../domain/models/remote_cli.dart';
import '../../domain/services/remote_cli_gateway.dart';
import 'cortex_api.dart';
import 'credentials_client.dart';
import 'stream_client.dart';

/// Authenticated gateway adapter for cortex_api #132.
class RemoteCliApi implements RemoteCliGateway {
  RemoteCliApi({
    String? baseUrl,
    http.Client? client,
    http.Client? streamClient,
    CortexApi? filesApi,
  }) : base = baseUrl ?? AppSettings.cortexApiBaseUrl,
       _client = client ?? createCredentialsClient(),
       _stream = streamClient ?? client ?? createStreamClient(),
       _filesApi = filesApi ?? CortexApi(baseUrl: baseUrl, client: client);

  final String base;
  final http.Client _client;
  final http.Client _stream;
  final CortexApi _filesApi;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$base$path').replace(queryParameters: query);

  Map<String, String> _headers({bool json = true}) {
    final csrf = readCsrfToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (csrf != null && csrf.isNotEmpty) 'X-CSRF-Token': csrf,
      if (csrf != null && csrf.isNotEmpty) 'X-CSRFToken': csrf,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> body = const {};
    try {
      body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (response.statusCode >= 400) {
      final data = (body['data'] as Map?) ?? const {};
      throw RemoteCliFailure(
        response.statusCode,
        '${body['message'] ?? response.reasonPhrase ?? 'Remote session request failed'}',
        number: (data['error_number'] as num?)?.toInt(),
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async => _decode(
    await _client.get(_uri(path, query), headers: _headers(json: false)),
  );

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? query,
  }) async {
    final response = await _client.post(
      _uri(path, query),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  String _sessionPath(String sessionId) =>
      '/remote/sessions/${Uri.encodeComponent(sessionId)}';

  @override
  Future<List<RemoteCliSession>> sessions() async {
    final data = (await _get('/remote/sessions'))['data'] as Map;
    return [
      for (final item in data['sessions'] as List? ?? const [])
        RemoteCliSession.fromJson((item as Map).cast<String, dynamic>()),
    ];
  }

  @override
  Stream<RemoteCliEvent> events(String sessionId, {required int after}) async* {
    final request = http.Request(
      'GET',
      _uri('${_sessionPath(sessionId)}/events', {'cursor': '$after'}),
    )..headers.addAll(_headers(json: false));
    request.headers['Accept'] = 'text/event-stream';
    final response = await _stream.send(request);
    if (response.statusCode >= 400) {
      _decode(await http.Response.fromStream(response));
    }
    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk.replaceAll('\r\n', '\n');
      int end;
      while ((end = buffer.indexOf('\n\n')) >= 0) {
        final block = buffer.substring(0, end);
        buffer = buffer.substring(end + 2);
        final event = _parseEvent(block);
        if (event != null) yield event;
      }
    }
  }

  static RemoteCliEvent? _parseEvent(String block) {
    String? cursor;
    final data = StringBuffer();
    for (final line in block.split('\n')) {
      if (line.startsWith('id:')) cursor = line.substring(3).trim();
      if (line.startsWith('data:')) {
        if (data.isNotEmpty) data.write('\n');
        data.write(line.substring(5).trimLeft());
      }
    }
    if (cursor == null || data.isEmpty) return null;
    final json = jsonDecode(data.toString()) as Map<String, dynamic>;
    final event = RemoteCliEvent.fromJson(json);
    final sseId = int.tryParse(cursor);
    // The event's own id is the durable cursor; a malformed or mismatched SSE
    // id must not silently advance the reconnect position.
    if (sseId == null || sseId != event.id) return null;
    return event;
  }

  @override
  Future<void> sendPrompt(
    String sessionId,
    String prompt, {
    List<String> fileIds = const [],
  }) async {
    await _post('${_sessionPath(sessionId)}/prompts', {
      'prompt': prompt,
      'file_ids': fileIds,
    });
  }

  @override
  Future<void> answerApproval(
    String sessionId,
    String approvalId, {
    required bool approved,
  }) async {
    await _post(
      '${_sessionPath(sessionId)}/approvals/${Uri.encodeComponent(approvalId)}',
      {'approved': approved},
    );
  }

  @override
  Future<void> cancel(String sessionId, {String? turnId}) async {
    await _post('${_sessionPath(sessionId)}/cancel', {'turn_id': turnId});
  }

  @override
  Future<String> uploadImage({
    required String name,
    required List<int> bytes,
    required String contentType,
  }) async {
    final result = await _filesApi.upload(name, bytes, contentType);
    final id = result.fileId;
    if (id == null || id.isEmpty) {
      throw const RemoteCliFailure(422, 'The selected image was not saved.');
    }
    return id;
  }
}
