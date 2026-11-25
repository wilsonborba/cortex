/// One CLI session owned by the signed-in account.
class RemoteCliSession {
  const RemoteCliSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.lastSeen,
    required this.online,
  });

  final String id;
  final String deviceName;
  final String platform;
  final DateTime lastSeen;
  final bool online;

  factory RemoteCliSession.fromJson(Map<String, dynamic> json) =>
      RemoteCliSession(
        id: '${json['session_id'] ?? ''}',
        deviceName: '${json['device_name'] ?? ''}',
        platform: '${json['platform'] ?? ''}',
        lastSeen: DateTime.fromMillisecondsSinceEpoch(
          (json['last_seen_ms'] as num?)?.toInt() ?? 0,
        ),
        online: json['online'] == true,
      );
}

/// An event stored by cortex_api for the CLI command or controller stream.
class RemoteCliEvent {
  const RemoteCliEvent({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
  });

  final int id;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory RemoteCliEvent.fromJson(Map<String, dynamic> json) => RemoteCliEvent(
    id: (json['id'] as num).toInt(),
    kind: '${json['kind'] ?? ''}',
    payload: ((json['payload'] as Map?) ?? const {}).cast(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (json['created_at_ms'] as num?)?.toInt() ?? 0,
    ),
  );
}

class RemoteCliFailure implements Exception {
  const RemoteCliFailure(this.status, this.message, {this.number});

  final int status;
  final int? number;
  final String message;

  bool get expired => number == 1051 || status == 404;

  @override
  String toString() => message.isEmpty ? 'Remote CLI request failed' : message;
}
