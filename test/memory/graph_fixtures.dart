import 'package:cortex/domain/models/memory_graph.dart';

MemoryGraphData graphFixture(
  int count, {
  bool loose = false,
  bool stack = false,
}) {
  final nodes = [
    for (var i = 0; i < count; i++)
      GraphNode(
        'synthetic-$i',
        i == 0 && count > 1 ? 'chat' : 'memory',
        stack && i > 0
            ? 'Synthetic saved note'
            : 'Example ${i == 0 && count > 1 ? 'chat' : 'note'} $i',
        {
          'created_at': '2030-01-02T12:00:00Z',
          'app_id': 'cortex',
          if (i == 0 && count > 1) ...{
            'source_system': 'cortex',
            'external_id': '00000000-0000-4000-8000-000000000001',
          },
        },
      ),
  ];
  return MemoryGraphData(
    nodes,
    [
      if (!loose)
        for (var i = 1; i < count; i++)
          GraphEdge(
            'synthetic-$i',
            stack ? 'synthetic-0' : 'synthetic-${i ~/ 6}',
            'created_in',
          ),
    ],
    false,
    null,
  );
}
