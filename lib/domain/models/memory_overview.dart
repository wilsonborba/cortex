/// Memory overview data from cortex_api #121. The backend groups, merges and
/// labels the memories; the frontend only draws them (cortex #65).
library;

DateTime? _time(Object? v) =>
    v is String ? DateTime.tryParse(v)?.toLocal() : null;
int _int(Object? v) => v is num ? v.toInt() : 0;
Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : const {};
List<Map<String, dynamic>> _list(Object? v) => [
  for (final e in (v is List ? v : const []))
    if (e is Map) e.cast<String, dynamic>(),
];

/// A plain label with its id (topics, people, files).
class MemoryLabel {
  const MemoryLabel(this.id, this.label);
  factory MemoryLabel.fromJson(Map<String, dynamic> j) =>
      MemoryLabel('${j['id']}', '${j['label'] ?? j['name'] ?? ''}');
  final String id, label;
}

/// One facet row: a key and a count.
class FacetCount {
  const FacetCount(this.key, this.label, this.count);
  final String key, label;
  final int count;
}

/// `GET /memory-graph/overview`.
class MemoryOverview {
  const MemoryOverview({
    required this.memories,
    required this.sizeBytes,
    required this.chats,
    required this.files,
    required this.people,
    required this.topics,
    required this.notes,
    required this.lastAt,
    required this.added7Days,
    required this.used7Days,
    required this.sources,
    required this.months,
    required this.truncated,
  });
  factory MemoryOverview.fromJson(Map<String, dynamic> j) {
    final s = _map(j['summary']), f = _map(j['facets']);
    return MemoryOverview(
      memories: _int(s['memories']),
      sizeBytes: _int(s['size_bytes']),
      chats: _int(s['chats']),
      files: _int(s['files']),
      people: _int(s['people']),
      topics: _int(s['topics']),
      notes: _int(s['notes']),
      lastAt: _time(s['last_at']),
      added7Days: _int(s['added_7_days']),
      used7Days: _int(s['used_7_days']),
      sources: {
        for (final e in _list(f['sources'])) '${e['kind']}': _int(e['count']),
      },
      months: [
        for (final e in _list(f['months']))
          FacetCount('${e['month']}', '${e['month']}', _int(e['count'])),
      ],
      truncated: j['truncated'] == true,
    );
  }
  final int memories, sizeBytes, chats, files, people, topics, notes;
  final int added7Days, used7Days;
  final DateTime? lastAt;

  /// Count per source kind: chat, file, note.
  final Map<String, int> sources;

  /// The last 12 months, oldest first ("2026-11").
  final List<FacetCount> months;
  final bool truncated;
}

/// Several memories with the same title and source, shown as one row.
class MemoryStack {
  const MemoryStack(this.count, this.ids);
  final int count;
  final List<String> ids;
}

/// One row of `GET /memory-graph/items`.
class MemoryItem {
  const MemoryItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.type,
    required this.sourceKind,
    required this.sourceId,
    required this.sourceTitle,
    required this.createdAt,
    required this.updatedAt,
    required this.sizeBytes,
    required this.words,
    required this.usedInAnswers,
    required this.lastUsedAt,
    required this.stack,
  });
  factory MemoryItem.fromJson(Map<String, dynamic> j) {
    final source = _map(j['source']), stack = _map(j['stack']);
    return MemoryItem(
      id: '${j['id']}',
      title: '${j['title'] ?? ''}',
      summary: '${j['summary'] ?? ''}',
      type: '${j['type'] ?? ''}',
      sourceKind: '${source['kind'] ?? 'note'}',
      sourceId: source['id'] as String?,
      sourceTitle: source['title'] as String?,
      createdAt: _time(j['created_at']),
      updatedAt: _time(j['updated_at']),
      sizeBytes: _int(j['size_bytes']),
      words: _int(j['words']),
      usedInAnswers: _int(j['used_in_answers']),
      lastUsedAt: _time(j['last_used_at']),
      stack: stack.isEmpty
          ? null
          : MemoryStack(_int(stack['count']), [
              for (final id in (stack['ids'] as List? ?? const [])) '$id',
            ]),
    );
  }
  final String id, title, summary, type, sourceKind;
  final String? sourceId, sourceTitle;
  final DateTime? createdAt, updatedAt, lastUsedAt;
  final int sizeBytes, words, usedInAnswers;
  final MemoryStack? stack;
}

/// One group of `/items` (a chat, a file, a person or a topic).
class MemoryGroup {
  const MemoryGroup(
    this.id,
    this.kind,
    this.title,
    this.count,
    this.firstAt,
    this.lastAt,
  );
  factory MemoryGroup.fromJson(Map<String, dynamic> j) => MemoryGroup(
    '${j['id']}',
    '${j['kind']}',
    '${j['title'] ?? ''}',
    _int(j['count']),
    _time(j['first_at']),
    _time(j['last_at']),
  );
  final String id, kind, title;
  final int count;
  final DateTime? firstAt, lastAt;
}

/// One page of `/items`.
class MemoryPage {
  const MemoryPage(this.items, this.groups, this.nextCursor, this.total);
  factory MemoryPage.fromJson(Map<String, dynamic> j) => MemoryPage(
    [for (final e in _list(j['items'])) MemoryItem.fromJson(e)],
    [for (final e in _list(j['groups'])) MemoryGroup.fromJson(e)],
    j['next_cursor'] as String?,
    _int(j['total']),
  );
  final List<MemoryItem> items;
  final List<MemoryGroup> groups;
  final String? nextCursor;
  final int total;
}

/// One answer that used a memory.
class MemoryUsage {
  const MemoryUsage(this.sessionId, this.chatTitle, this.outputId, this.usedAt);
  final String sessionId, chatTitle, outputId;
  final DateTime? usedAt;
}

/// One direct link of a memory: `source_chat`, `file`, `person`, `topic`,
/// `relation` (with [relationType]) or `same_title` (with [count]).
class MemoryConnection {
  const MemoryConnection({
    required this.kind,
    this.relationType,
    this.targetId,
    this.targetLabel = '',
    this.targetType,
    this.count = 0,
  });
  factory MemoryConnection.fromJson(Map<String, dynamic> j) {
    final t = _map(j['target']);
    return MemoryConnection(
      kind: '${j['kind']}',
      relationType: j['relation_type'] as String?,
      targetId: t['id'] as String?,
      targetLabel: '${t['label'] ?? ''}',
      targetType: t['node_type'] as String?,
      count: _int(j['count']),
    );
  }
  final String kind;
  final String? relationType, targetId, targetType;
  final String targetLabel;
  final int count;
}

/// A node of the tiny map.
class MapNode {
  const MapNode(this.id, this.type, this.label);
  final String id, type, label;
}

/// `GET /memory-graph/nodes/{node_id}`: the readable detail.
class MemoryDetail {
  const MemoryDetail({
    required this.item,
    required this.content,
    required this.usage,
    required this.connections,
    required this.mapNodes,
    required this.mapEdges,
  });
  factory MemoryDetail.fromJson(Map<String, dynamic> j) {
    final map = _map(j['map']);
    return MemoryDetail(
      item: MemoryItem.fromJson(_map(j['item'])),
      content: '${j['content'] ?? ''}',
      usage: [
        for (final u in _list(j['usage']))
          MemoryUsage(
            '${u['session_id']}',
            '${u['chat_title'] ?? ''}',
            '${u['output_id']}',
            _time(u['used_at']),
          ),
      ],
      connections: [
        for (final c in _list(j['connections'])) MemoryConnection.fromJson(c),
      ],
      mapNodes: [
        for (final n in _list(map['nodes']))
          MapNode('${n['id']}', '${n['node_type']}', '${n['label'] ?? ''}'),
      ],
      mapEdges: [
        for (final e in _list(map['edges']))
          ('${e['source_id']}', '${e['target_id']}'),
      ],
    );
  }
  final MemoryItem item;
  final String content;
  final List<MemoryUsage> usage;
  final List<MemoryConnection> connections;
  final List<MapNode> mapNodes;
  final List<(String, String)> mapEdges;
}
