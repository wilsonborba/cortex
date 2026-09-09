import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/settings.dart';
import '../../core/utils/csrf.dart';
import '../../dal/remote/credentials_client.dart';
import '../models/support_ticket.dart';

class SupportApiException implements Exception {
  const SupportApiException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'SupportApiException: HTTP $statusCode';
}

/// Client for api_for_apps's central cross-app support ticket system
/// (ported from `certifications/lib/domain/services/support_api_service.dart`,
/// api_for_apps#17). The backend route is generic across apps: `source_app`
/// is a free-text string, not an allowlisted value, so every call here is
/// simply scoped with `_sourceApp = 'cortex'`.
///
/// Uses this app's own `createCredentialsClient()`/CSRF conventions (see
/// `CortexApiAdapter`) rather than certifications' `ApiAdapter`.
class SupportApiService {
  SupportApiService({http.Client? httpClient})
    : _httpClient = httpClient ?? createCredentialsClient();

  final http.Client _httpClient;

  static const _sourceApp = 'cortex';

  String get _base => '${AppSettings.apiForAppsBaseUrl}/apps/support/v1';

  void _addCsrfHeader(Map<String, String> headers) {
    final csrfToken = readCsrfToken();
    if (csrfToken != null && csrfToken.isNotEmpty) {
      headers.putIfAbsent('X-CSRF-Token', () => csrfToken);
      headers.putIfAbsent('X-CSRFToken', () => csrfToken);
    }
  }

  Future<List<SupportTicket>> listTickets() async {
    final uri = Uri.parse(
      '$_base/tickets',
    ).replace(queryParameters: {'source_app': _sourceApp});
    final headers = <String, String>{'Accept': 'application/json'};
    _addCsrfHeader(headers);
    final response = await _httpClient.get(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ((payload['data'] as List? ?? const [])
            .cast<Map<String, dynamic>>())
        .map(SupportTicket.fromJson)
        .toList();
  }

  Future<SupportTicketDetail> createTicket({
    String? subject,
    required String body,
    String? attachmentReference,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    _addCsrfHeader(headers);
    final response = await _httpClient.post(
      Uri.parse('$_base/tickets'),
      headers: headers,
      body: jsonEncode({
        'source_app': _sourceApp,
        'subject': subject,
        'body': body,
        'attachment_reference': attachmentReference,
      }),
    );
    return SupportTicketDetail.fromJson(_data(response));
  }

  Future<SupportTicketDetail> getTicket(String ticketId) async {
    final headers = <String, String>{'Accept': 'application/json'};
    _addCsrfHeader(headers);
    final response = await _httpClient.get(
      Uri.parse('$_base/tickets/$ticketId'),
      headers: headers,
    );
    return SupportTicketDetail.fromJson(_data(response));
  }

  Future<SupportMessage> postMessage(
    String ticketId, {
    required String body,
    String? attachmentReference,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    _addCsrfHeader(headers);
    final response = await _httpClient.post(
      Uri.parse('$_base/tickets/$ticketId/messages'),
      headers: headers,
      body: jsonEncode({
        'body': body,
        'attachment_reference': attachmentReference,
      }),
    );
    return SupportMessage.fromJson(_data(response));
  }

  Future<void> markTicketRead(String ticketId) async {
    final headers = <String, String>{'Accept': 'application/json'};
    _addCsrfHeader(headers);
    final response = await _httpClient.patch(
      Uri.parse('$_base/tickets/$ticketId/read'),
      headers: headers,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
  }

  /// Uploads an attachment to FSM via api_for_apps and returns the
  /// attachment_reference to pass into [createTicket] or [postMessage].
  Future<String> uploadAttachment({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/attachments'),
    )..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );
    request.headers['Accept'] = 'application/json';
    _addCsrfHeader(request.headers);

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final data = _data(response);
    return data['attachment_reference'] as String;
  }

  Map<String, dynamic> _data(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
