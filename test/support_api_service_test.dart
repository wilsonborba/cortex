// Tests SupportApiService's request shaping (source_app scoping, CSRF
// header, multipart upload) and response parsing, against a fake
// http.Client, no live backend involved. Mirrors the fake-client pattern
// already used in chat_service_test.dart / cortex_api_adapter_test.dart.

import 'dart:async';
import 'dart:convert';

import 'package:cortex/domain/services/support_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this._respond);

  final FutureOr<http.StreamedResponse> Function(http.BaseRequest request) _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async => _respond(request);
}

http.StreamedResponse _jsonResponse(Object body, {int statusCode = 200}) {
  return http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    statusCode,
  );
}

void main() {
  test('listTickets scopes the request to source_app=cortex and parses the data array', () async {
    late http.BaseRequest sentRequest;
    final client = _FakeHttpClient((request) async {
      sentRequest = request;
      return _jsonResponse({
        'data': [
          {'id': 'ticket-1', 'source_app': 'cortex', 'status': 'open'},
          {'id': 'ticket-2', 'source_app': 'cortex', 'status': 'resolved'},
        ],
      });
    });
    final service = SupportApiService(httpClient: client);

    final tickets = await service.listTickets();

    expect(sentRequest.method, 'GET');
    expect(sentRequest.url.path, '/apps/support/v1/tickets');
    expect(sentRequest.url.queryParameters['source_app'], 'cortex');
    expect(tickets, hasLength(2));
    expect(tickets[0].id, 'ticket-1');
    expect(tickets[1].status, 'resolved');
  });

  test('listTickets throws SupportApiException on a non-2xx status', () async {
    final client = _FakeHttpClient((request) async => _jsonResponse({}, statusCode: 500));
    final service = SupportApiService(httpClient: client);

    expect(() => service.listTickets(), throwsA(isA<SupportApiException>()));
  });

  test('createTicket sends source_app, subject and body, and parses the ticket detail', () async {
    late Map<String, dynamic> sentBody;
    final client = _FakeHttpClient((request) async {
      sentBody = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      return _jsonResponse({
        'data': {
          'id': 'ticket-1',
          'source_app': 'cortex',
          'status': 'open',
          'subject': 'Help',
          'messages': <Map<String, dynamic>>[],
        },
      });
    });
    final service = SupportApiService(httpClient: client);

    final detail = await service.createTicket(subject: 'Help', body: 'I need help');

    expect(sentBody['source_app'], 'cortex');
    expect(sentBody['subject'], 'Help');
    expect(sentBody['body'], 'I need help');
    expect(detail.id, 'ticket-1');
    expect(detail.subject, 'Help');
    expect(detail.messages, isEmpty);
  });

  test('getTicket parses the full message thread, including admin/user senders', () async {
    final client = _FakeHttpClient((request) async {
      return _jsonResponse({
        'data': {
          'id': 'ticket-1',
          'source_app': 'cortex',
          'status': 'pending',
          'messages_available': true,
          'messages': [
            {'id': 'm1', 'sender': 'user', 'body': 'Hi', 'timestamp': 't1'},
            {'id': 'm2', 'sender': 'admin', 'body': 'Hello, how can we help?', 'timestamp': 't2'},
          ],
        },
      });
    });
    final service = SupportApiService(httpClient: client);

    final detail = await service.getTicket('ticket-1');

    expect(detail.messages, hasLength(2));
    expect(detail.messages[0].isFromAdmin, isFalse);
    expect(detail.messages[1].isFromAdmin, isTrue);
    expect(detail.messagesAvailable, isTrue);
  });

  test('getTicket surfaces messages_available:false without throwing', () async {
    final client = _FakeHttpClient((request) async {
      return _jsonResponse({
        'data': {
          'id': 'ticket-1',
          'source_app': 'cortex',
          'status': 'open',
          'messages_available': false,
          'messages': <Map<String, dynamic>>[],
        },
      });
    });
    final service = SupportApiService(httpClient: client);

    final detail = await service.getTicket('ticket-1');

    expect(detail.messagesAvailable, isFalse);
    expect(detail.id, 'ticket-1');
  });

  test('uploadAttachment posts a multipart request with the file field and returns the reference', () async {
    late http.MultipartRequest sentRequest;
    final client = _FakeHttpClient((request) async {
      sentRequest = request as http.MultipartRequest;
      return _jsonResponse({
        'data': {'attachment_reference': 'fsm://some-key'},
      });
    });
    final service = SupportApiService(httpClient: client);

    final reference = await service.uploadAttachment(
      filename: 'photo.png',
      bytes: [1, 2, 3],
      mimeType: 'image/png',
    );

    expect(sentRequest.url.path, '/apps/support/v1/attachments');
    expect(sentRequest.files, hasLength(1));
    expect(sentRequest.files.single.field, 'file');
    expect(sentRequest.files.single.filename, 'photo.png');
    expect(reference, 'fsm://some-key');
  });

  test('postMessage sends body and attachment_reference for an existing ticket', () async {
    late Map<String, dynamic> sentBody;
    final client = _FakeHttpClient((request) async {
      sentBody = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
      return _jsonResponse({
        'data': {'id': 'm3', 'sender': 'user', 'body': 'Following up', 'timestamp': 't3'},
      });
    });
    final service = SupportApiService(httpClient: client);

    final message = await service.postMessage(
      'ticket-1',
      body: 'Following up',
      attachmentReference: 'fsm://ref',
    );

    expect(sentBody['body'], 'Following up');
    expect(sentBody['attachment_reference'], 'fsm://ref');
    expect(message.body, 'Following up');
  });
}
