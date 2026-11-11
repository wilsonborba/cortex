/// One node of `GET /memory-graph`: memory, tag, entity or file.
class GraphNode {
  const GraphNode(this.id, this.type, this.label, this.metadata);
  factory GraphNode.fromJson(Map<String, dynamic> j) => GraphNode(
    '${j['id']}',
    '${j['node_type']}',
    '${j['label'] ?? j['id']}',
    ((j['metadata'] as Map?) ?? const {}).cast(),
  );
  final String id;
  final String type;
  final String label;
  final Map<String, dynamic> metadata;
  String get displayType =>
      type == 'entity' && ['person', 'bot'].contains(metadata['entity_type'])
      ? 'persona'
      : type;
}

class GraphEdge {
  const GraphEdge(this.source, this.target, this.type);
  final String source;
  final String target;
  final String type;
}

/// Nodes and edges in the API order; `node` is set for a node request.
class MemoryGraphData {
  const MemoryGraphData(this.nodes, this.edges, this.truncated, this.node);
  factory MemoryGraphData.fromJson(Map<String, dynamic> j) {
    final nodes = [
      for (final n in (j['nodes'] as List? ?? const []))
        GraphNode.fromJson((n as Map).cast()),
    ];
    final focus = j['node'] is Map ? '${(j['node'] as Map)['id']}' : null;
    return MemoryGraphData(
      nodes,
      [
        for (final e in (j['edges'] as List? ?? const []))
          GraphEdge(
            '${(e as Map)['source_id']}',
            '${e['target_id']}',
            '${e['edge_type']}',
          ),
      ],
      j['truncated'] == true,
      focus == null ? null : nodes.where((n) => n.id == focus).firstOrNull,
    );
  }
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool truncated;
  final GraphNode? node;

  /// Nodes joined to [id] by one edge, in the API order.
  List<GraphNode> linked(String id) {
    final ids = {
      for (final e in edges)
        if (e.source == id) e.target else if (e.target == id) e.source,
    };
    return [
      for (final n in nodes)
        if (ids.contains(n.id)) n,
    ];
  }
}
