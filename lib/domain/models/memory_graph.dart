/// Domain models for the memory graph view (`GET {proxyBase}/memory-graph`).
///
/// Parsing is deliberately lenient: an unrecognized `node_type`/`edge_type`
/// string from the backend degrades to a generic fallback instead of
/// throwing, since hippocampus is free to add new types server-side without
/// this client needing a matching release first.
enum MemoryGraphNodeType {
  memory,
  attachment,
  tag,
  entity,
  resource,
  cluster,
  unknown;

  static MemoryGraphNodeType fromJson(String? value) {
    switch (value) {
      case 'memory':
        return MemoryGraphNodeType.memory;
      case 'attachment':
        return MemoryGraphNodeType.attachment;
      case 'tag':
        return MemoryGraphNodeType.tag;
      case 'entity':
        return MemoryGraphNodeType.entity;
      case 'resource':
        return MemoryGraphNodeType.resource;
      case 'cluster':
        return MemoryGraphNodeType.cluster;
      default:
        return MemoryGraphNodeType.unknown;
    }
  }
}

/// Any edge type not explicitly known (`tagged_with`, `mentions`, plus
/// whatever memory-relationship types hippocampus emits) is treated as a
/// generic "related" edge, per the backend contract: this client never
/// hardcodes an exhaustive edge-type list.
class MemoryGraphNode {
  const MemoryGraphNode({
    required this.id,
    required this.nodeType,
    required this.label,
    this.subtitle,
    this.metadata = const {},
  });

  final String id;
  final MemoryGraphNodeType nodeType;
  final String label;
  final String? subtitle;
  final Map<String, dynamic> metadata;

  /// The ids collapsed into this node when hippocampus' clustering kicked
  /// in (`metadata.cluster_of`), empty for every non-cluster node.
  List<String> get clusterOf {
    final raw = metadata['cluster_of'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  factory MemoryGraphNode.fromJson(Map<String, dynamic> json) {
    return MemoryGraphNode(
      id: json['id'] as String? ?? '',
      nodeType: MemoryGraphNodeType.fromJson(json['node_type'] as String?),
      label: json['label'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
    );
  }
}

class MemoryGraphEdge {
  const MemoryGraphEdge({
    required this.sourceId,
    required this.targetId,
    required this.edgeType,
    this.confidence,
  });

  final String sourceId;
  final String targetId;

  /// Raw edge type string from the backend (`tagged_with`, `mentions`, or
  /// any memory-relationship type); never validated against a fixed enum
  /// since new relationship types can appear at any time.
  final String edgeType;
  final double? confidence;

  factory MemoryGraphEdge.fromJson(Map<String, dynamic> json) {
    final rawConfidence = json['confidence'];
    return MemoryGraphEdge(
      sourceId: json['source_id'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      edgeType: json['edge_type'] as String? ?? 'related',
      confidence: rawConfidence is num ? rawConfidence.toDouble() : null,
    );
  }
}

class MemoryGraph {
  const MemoryGraph({
    required this.nodes,
    required this.edges,
    required this.rootIds,
    required this.truncated,
  });

  final List<MemoryGraphNode> nodes;
  final List<MemoryGraphEdge> edges;
  final List<String> rootIds;
  final bool truncated;

  static const empty = MemoryGraph(
    nodes: [],
    edges: [],
    rootIds: [],
    truncated: false,
  );

  factory MemoryGraph.fromJson(Map<String, dynamic> json) {
    final nodesJson = json['nodes'] as List<dynamic>? ?? const [];
    final edgesJson = json['edges'] as List<dynamic>? ?? const [];
    final rootIdsJson = json['root_ids'] as List<dynamic>? ?? const [];
    return MemoryGraph(
      nodes: nodesJson
          .map((e) => MemoryGraphNode.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      edges: edgesJson
          .map((e) => MemoryGraphEdge.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      rootIds: rootIdsJson.map((e) => e.toString()).toList(),
      truncated: json['truncated'] as bool? ?? false,
    );
  }
}
