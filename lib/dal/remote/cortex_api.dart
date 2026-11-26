import '../../domain/models/answer_inspection.dart';
import '../../domain/models/telemetry.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../domain/models/memory_overview.dart';
import '../../domain/models/persona.dart';
import '../../domain/models/api.dart';
import 'credentials_client.dart';
import 'stream_client.dart';

/// Client of the Cortex API v2 through the gateway (route map 06361aef).
class CortexApi {
  static const maxFileContentBytes = 5 * 1024 * 1024;
  static const maxFileErrorResponseBytes = 64 * 1024;
  CortexApi({String? baseUrl, http.Client? client, http.Client? streamClient})
    : base = baseUrl ?? AppSettings.cortexApiBaseUrl,
      _client = client ?? createCredentialsClient(),
      _stream = streamClient ?? client ?? createStreamClient();
  final String base;
  final http.Client _client;
  final http.Client _stream;
  static const appId = AppSettings.appIdentifier;

  Map<String, String> _headers({bool json = true}) {
    final csrf = readCsrfToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (csrf != null && csrf.isNotEmpty) 'X-CSRF-Token': csrf,
      if (csrf != null && csrf.isNotEmpty) 'X-CSRFToken': csrf,
    };
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$base$path').replace(queryParameters: query);

  Map<String, dynamic> _body(http.Response r) {
    Map<String, dynamic> body = const {};
    try {
      body = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (r.statusCode >= 400) {
      final data = (body['data'] as Map?) ?? const {};
      throw ApiError(
        r.statusCode,
        (data['error_number'] as num?)?.toInt(),
        '${body['message'] ?? r.reasonPhrase}',
        fieldErrors: {
          for (final error in data['errors'] as List? ?? const [])
            if (error is Map)
              '${error['field_path'] ?? ''}': '${error['message'] ?? ''}',
        },
      );
    }
    return body;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? q,
  ]) async =>
      _body(await _client.get(_uri(path, q), headers: _headers(json: false)));
  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Object? body, [
    Map<String, String>? q,
  ]) async {
    final request = http.Request(method, _uri(path, q))
      ..headers.addAll(_headers());
    if (body != null) request.body = jsonEncode(body);
    return _body(await http.Response.fromStream(await _client.send(request)));
  }

  Future<AnswerInspectionData> answerInspection(
    String sessionId,
    String outputId,
  ) async => AnswerInspectionData.fromJson(
    ((await _get(
              '/chats/${Uri.encodeComponent(sessionId)}/outputs/${Uri.encodeComponent(outputId)}/inspection',
            ))['data']
            as Map)
        .cast<String, dynamic>(),
  );

  Future<UsageData> usage() async => UsageData.fromJson(
    ((await _get('/telemetry/usage'))['data'] as Map).cast(),
  );
  Future<List<TimingAverage>> timing() async => [
    for (final item in (await _get('/telemetry/timing'))['data'] as List)
      TimingAverage.fromJson((item as Map).cast()),
  ];
  Future<List<GroupStats>> stats() async => [
    for (final item in (await _get('/telemetry/stats'))['data'] as List)
      GroupStats.fromJson((item as Map).cast()),
  ];
  Future<List<CallEvent>> callEvents({String? before, int limit = 20}) async =>
      [
        for (final item
            in (await _get('/telemetry/events', {
                  'limit': '$limit',
                  'before': ?before,
                }))['data']
                as List)
          CallEvent.fromJson((item as Map).cast()),
      ];

  Future<ChatModelCatalog> modelCatalog() async => ChatModelCatalog.fromJson(
    ((await _get('/models'))['data'] as Map).cast<String, dynamic>(),
  );

  Future<InputBudget> budget() async => (await modelCatalog()).budget;

  Future<Map<String, dynamic>> page(
    String session, {
    String? before,
    int limit = 20,
  }) async =>
      ((await _get('/chats/$session', {
                'limit': '$limit',
                'before': ?before,
              }))['data']
              as Map)
          .cast();

  Future<List<Map<String, dynamic>>> chats({bool running = false}) async =>
      ((await _get('/chats', running ? {'status': 'running'} : null))['data']
              as List)
          .cast();

  Future<Map<String, dynamic>> patchChat(
    String session,
    Map<String, Object> change,
  ) async =>
      ((await _send('PATCH', '/chats/$session', change))['data'] as Map).cast();

  Future<void> deleteChat(String session) =>
      _send('DELETE', '/chats/$session', null);

  /// Memory overview numbers and facets (cortex_api #121).
  Future<MemoryOverview> memoryOverview() async => MemoryOverview.fromJson(
    ((await _get('/memory-graph/overview', {'app_id': appId}))['data'] as Map)
        .cast(),
  );

  /// One page of memory items, or the groups of a source (cortex_api #121).
  Future<MemoryPage> memoryItems({
    String source = 'all',
    String? groupId,
    String period = 'all',
    String? query,
    String? cursor,
    int limit = 50,
  }) async => MemoryPage.fromJson(
    ((await _get('/memory-graph/items', {
              'app_id': appId,
              'source': source,
              'group_id': ?groupId,
              'period': period,
              'q': ?(query == null || query.isEmpty ? null : query),
              'cursor': ?cursor,
              'limit': '$limit',
            }))['data']
            as Map)
        .cast(),
  );

  /// The readable detail of one memory (cortex_api #121).
  Future<MemoryDetail> memoryDetail(String id) async => MemoryDetail.fromJson(
    ((await _get('/memory-graph/nodes/${Uri.encodeComponent(id)}', {
              'app_id': appId,
            }))['data']
            as Map)
        .cast(),
  );

  /// Delete one memory of the caller (cortex_api #122).
  Future<void> deleteMemory(String id) => _send(
    'DELETE',
    '/memory-graph/nodes/${Uri.encodeComponent(id)}',
    null,
    {'app_id': appId},
  );

  Future<List<Map<String, dynamic>>> botPersonas() async =>
      ((await _get('/personas', {'app_id': appId, 'type': 'bot'}))['data']
              as List)
          .cast();

  Future<List<Persona>> personas({String? query, String? type}) async => [
    for (final value
        in (await _get('/personas', {
              'app_id': appId,
              'q': ?query,
              'type': ?type,
            }))['data']
            as List)
      Persona.fromJson((value as Map).cast()),
  ];
  Future<Persona> persona(String id) async => Persona.fromJson(
    ((await _get('/personas/${Uri.encodeComponent(id)}', {
              'app_id': appId,
            }))['data']
            as Map)
        .cast(),
  );
  Future<PersonaSchema> personaSchema(String type) async =>
      PersonaSchema.fromJson(
        ((await _get('/personas/schemas/${Uri.encodeComponent(type)}', {
                  'app_id': appId,
                }))['data']
                as Map)
            .cast(),
      );
  Future<Persona> savePersona({
    String? id,
    required String type,
    required String name,
    required List<String> aliases,
    required bool isSelf,
    required Map<String, dynamic> attributes,
  }) async => Persona.fromJson(
    ((await _send(
              id == null ? 'POST' : 'PATCH',
              id == null ? '/personas' : '/personas/${Uri.encodeComponent(id)}',
              {
                if (id == null) 'type': type,
                'name': name,
                'aliases': aliases,
                'is_self': isSelf,
                'attributes': attributes,
              },
              {'app_id': appId},
            ))['data']
            as Map)
        .cast(),
  );
  Future<void> deletePersona(String id) => _send(
    'DELETE',
    '/personas/${Uri.encodeComponent(id)}',
    null,
    {'app_id': appId},
  );

  /// Output controls (10.5, 11.8).
  Future<void> cancel(String session, String output) => _send(
    'PATCH',
    '/chats/$session/outputs/$output',
    {'status': 'cancelled'},
  );
  Future<void> stopThinking(String session, String output) =>
      _send('PATCH', '/chats/$session/outputs/$output', {'thinking': false});

  /// POST /files (multipart, 8.2).
  Future<UploadResult> upload(
    String name,
    List<int> bytes,
    String contentType, {
    bool temporary = false,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/files'))
      ..headers.addAll(_headers(json: false))
      ..fields['app_id'] = appId
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: _media(contentType),
        ),
      );
    if (temporary) request.fields['temporary'] = 'true';
    final data =
        (_body(
              await http.Response.fromStream(await _client.send(request)),
            )['data']
            as Map?) ??
        const {};
    return UploadResult(
      fileId: data['file_id'] as String?,
      noticeNumber: (data['notice_number'] as num?)?.toInt(),
    );
  }

  /// Reads one authenticated file through the existing owner/app-scoped route.
  /// The response is bounded while streaming so a large file cannot be
  /// materialized in memory by the preview path.
  Future<DownloadedFileContent> downloadFileContent(
    String fileId, {
    int maxBytes = maxFileContentBytes,
  }) async {
    if (fileId.isEmpty || maxBytes <= 0) {
      throw const FormatException(
        'A valid file id and byte limit are required.',
      );
    }
    final request = http.Request(
      'GET',
      _uri('/files/${Uri.encodeComponent(fileId)}/content', {'app_id': appId}),
    )..headers.addAll(_headers(json: false));
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      final errorResponse = await _boundedFileErrorResponse(response);
      if (errorResponse == null) {
        throw ApiError(
          response.statusCode,
          null,
          'File error response is too large to preview.',
        );
      }
      _body(errorResponse);
    }
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maxBytes) {
      await response.stream.listen(null).cancel();
      throw const ApiError(413, null, 'File is too large to preview.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 30),
    )) {
      if (bytes.length + chunk.length > maxBytes) {
        throw const ApiError(413, null, 'File is too large to preview.');
      }
      bytes.addAll(chunk);
    }
    final contentType = response.headers['content-type']
        ?.split(';')
        .first
        .trim()
        .toLowerCase();
    if (contentType == null || contentType.isEmpty) {
      throw const FormatException('File response has no content type.');
    }
    return DownloadedFileContent(contentType: contentType, bytes: bytes);
  }

  Future<http.Response?> _boundedFileErrorResponse(
    http.StreamedResponse response,
  ) async {
    final declaredLength = response.contentLength;
    if (declaredLength != null && declaredLength > maxFileErrorResponseBytes) {
      await response.stream.listen((_) {}).cancel();
      return null;
    }
    final iterator = StreamIterator<List<int>>(response.stream);
    final bytes = BytesBuilder(copy: false);
    try {
      while (await iterator.moveNext()) {
        final chunk = iterator.current;
        if (bytes.length + chunk.length > maxFileErrorResponseBytes) {
          await iterator.cancel();
          return null;
        }
        bytes.add(chunk);
      }
    } finally {
      await iterator.cancel();
    }
    return http.Response.bytes(
      bytes.takeBytes(),
      response.statusCode,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  static MediaType? _media(String type) {
    try {
      return MediaType.parse(type);
    } catch (_) {
      return null;
    }
  }

  /// POST /chats or /chats/{id}/inputs with stream true: the SSE events.
  Stream<ChatEvent> input({
    String? session,
    required Map<String, Object?> body,
  }) => _events('POST', session == null ? '/chats' : '/chats/$session/inputs', {
    ...body,
    'stream': true,
  });

  /// Reconnect: saved events after [after], then live events (10.4).
  Stream<ChatEvent> events(String session, String output, {int after = 0}) =>
      _events(
        'GET',
        '/chats/$session/outputs/$output/events',
        null,
        after > 0 ? {'after': '$after'} : null,
      );

  Stream<ChatEvent> _events(
    String method,
    String path,
    Object? body, [
    Map<String, String>? q,
  ]) async* {
    final request = http.Request(method, _uri(path, q))
      ..headers.addAll(_headers(json: body != null));
    request.headers['Accept'] = 'text/event-stream';
    if (body != null) request.body = jsonEncode(body);
    final response = await _stream.send(request);
    if (response.statusCode >= 400) {
      _body(await http.Response.fromStream(response));
    }
    var buffer = '';
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      buffer += chunk.replaceAll('\r\n', '\n');
      int end;
      while ((end = buffer.indexOf('\n\n')) >= 0) {
        final block = buffer.substring(0, end);
        buffer = buffer.substring(end + 2);
        final event = parseEvent(block);
        if (event != null) yield event;
      }
    }
  }

  /// One SSE block: `id:`, `event:` and `data:` lines.
  static ChatEvent? parseEvent(String block) {
    int? id;
    String? name;
    final data = StringBuffer();
    for (final line in block.split('\n')) {
      if (line.startsWith('id:')) id = int.tryParse(line.substring(3).trim());
      if (line.startsWith('event:')) name = line.substring(6).trim();
      if (line.startsWith('data:')) data.write(line.substring(5).trimLeft());
    }
    if (id == null || name == null) return null;
    final body = jsonDecode(data.toString()) as Map<String, dynamic>;
    return ChatEvent(
      id,
      name,
      '${body['message'] ?? ''}',
      ((body['data'] as Map?) ?? const {}).cast(),
    );
  }
}
