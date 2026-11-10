import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';
import '../models/memory_graph.dart';

enum MemoryView { graph, list }

/// The memory screen state (issue #32): the scope graph and the open node.
class MemoryController extends ChangeNotifier {
  MemoryController({required this.api});
  final CortexApi api;
  static const depths = [1, 2, 3];
  static const limits = [50, 100, 200];
  int depth = 1;
  int limit = 100;
  MemoryView view = MemoryView.graph;
  int _graphRequest = 0;
  int _nodeRequest = 0;
  bool _disposed = false;
  MemoryGraphData? graph;
  MemoryGraphData? node;
  bool loading = false;
  bool nodeLoading = false;
  ApiError? error;
  ApiError? nodeError;

  Future<void> load() async {
    final request = ++_graphRequest;
    loading = true;
    notifyListeners();
    try {
      final result = await api.memoryGraph(depth: depth, limit: limit);
      if (_disposed || request != _graphRequest) return;
      graph = result;
      error = null;
    } on ApiError catch (e) {
      if (_disposed || request != _graphRequest) return;
      error = e;
    } catch (_) {
      if (_disposed || request != _graphRequest) return;
      error = const ApiError(0, null, '');
    }
    loading = false;
    notifyListeners();
  }

  Future<void> open(String? id) async {
    final request = ++_nodeRequest;
    if (id == null) {
      node = null;
      nodeError = null;
      nodeLoading = false;
      notifyListeners();
      return;
    }
    nodeLoading = true;
    notifyListeners();
    try {
      final result = await api.memoryNode(id, depth: 1);
      if (_disposed || request != _nodeRequest) return;
      node = result;
      nodeError = null;
    } on ApiError catch (e) {
      if (_disposed || request != _nodeRequest) return;
      node = null;
      nodeError = e;
    } catch (_) {
      if (_disposed || request != _nodeRequest) return;
      node = null;
      nodeError = const ApiError(0, null, '');
    }
    nodeLoading = false;
    notifyListeners();
  }

  void setView(MemoryView value) {
    view = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setDepth(int value) {
    depth = value;
    load();
  }

  void setLimit(int value) {
    limit = value;
    load();
  }
}
