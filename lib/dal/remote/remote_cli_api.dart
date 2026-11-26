import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../domain/models/api.dart';
import '../../domain/models/remote_cli.dart';
import '../../domain/services/remote_cli_gateway.dart';
import 'cortex_api.dart';
import 'credentials_client.dart';
import 'stream_client.dart';

/// Authenticated gateway adapter for cortex_api #132.
class RemoteCliApi implements RemoteCliGateway {
  static const maxSseLineCharacters = 64 * 1024;
  static const maxSseFrameBytes = 256 * 1024;
  static const requestTimeout = Duration(seconds: 30);

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
    await _client
        .get(_uri(path, query), headers: _headers(json: false))
        .timeout(requestTimeout),
  );

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? query,
  }) async {
    final response = await _client
        .post(_uri(path, query), headers: _headers(), body: jsonEncode(body))
        .timeout(requestTimeout);
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
    final response = await _stream.send(request).timeout(requestTimeout);
    if (response.statusCode >= 400) {
      _decode(await http.Response.fromStream(response).timeout(requestTimeout));
    }
    String? id;
    final data = StringBuffer();
    var hasData = false;
    var frameBytes = 0;
    await for (final line in _lines(
      response.stream.timeout(requestTimeout).transform(utf8.decoder),
    )) {
      if (line.isEmpty) {
        if (hasData || id != null) yield _parseEvent(id, data.toString());
        id = null;
        data.clear();
        hasData = false;
        frameBytes = 0;
        continue;
      }
      if (line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'id') {
        id = value;
      } else if (field == 'data') {
        frameBytes += utf8.encode(value).length + (hasData ? 1 : 0);
        if (frameBytes > maxSseFrameBytes) {
          throw const FormatException('Remote event exceeds the allowed size.');
        }
        if (hasData) data.write('\n');
        data.write(value);
        hasData = true;
      }
    }
  }

  static Stream<String> _lines(Stream<String> chunks) async* {
    final line = StringBuffer();
    var pendingCarriageReturn = false;
    await for (final chunk in chunks) {
      for (var index = 0; index < chunk.length; index++) {
        final unit = chunk.codeUnitAt(index);
        if (pendingCarriageReturn) {
          yield line.toString();
          line.clear();
          pendingCarriageReturn = false;
          if (unit == 0x0a) continue;
        }
        if (unit == 0x0d) {
          pendingCarriageReturn = true;
        } else if (unit == 0x0a) {
          yield line.toString();
          line.clear();
        } else {
          line.writeCharCode(unit);
          if (line.length > maxSseLineCharacters) {
            throw const FormatException(
              'Remote event line exceeds the allowed size.',
            );
          }
        }
      }
    }
    if (pendingCarriageReturn || line.isNotEmpty) yield line.toString();
  }

  static RemoteCliEvent _parseEvent(String? cursor, String data) {
    if (cursor == null || cursor.isEmpty || data.isEmpty) {
      throw const FormatException(
        'Remote event is missing its cursor or data.',
      );
    }
    final decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Remote event data must be an object.');
    }
    final json = decoded;
    final event = RemoteCliEvent.fromJson(json);
    final sseId = int.tryParse(cursor);
    if (sseId == null || sseId != event.id) {
      throw const FormatException(
        'Remote event cursor does not match its body.',
      );
    }
    return event;
  }

  @override
  Future<int?> sendPrompt(
    String sessionId,
    String prompt, {
    List<String> fileIds = const [],
  }) async {
    final response = await _post('${_sessionPath(sessionId)}/prompts', {
      'prompt': prompt,
      'file_ids': fileIds,
    });
    final data = (response['data'] as Map?) ?? const {};
    final id = data['id'] ?? data['command_id'];
    return id is num ? id.toInt() : null;
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
    final result = await _filesApi
        .upload(name, bytes, contentType)
        .timeout(requestTimeout);
    final id = result.fileId;
    if (id == null || id.isEmpty) {
      throw const RemoteCliFailure(422, 'The selected image was not saved.');
    }
    return id;
  }

  @override
  Future<DownloadedFileContent> artifactImage(String fileId) =>
      _filesApi.downloadFileContent(fileId);
}
