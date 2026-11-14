import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';
import '../models/memory_overview.dart';

/// Source facet of the memory overview (cortex_api #121 `source`).
enum MemorySource { all, chat, file, note, person, topic }

/// Period facet (`period`).
enum MemoryPeriod { today, week, month, all }

extension MemoryPeriodQuery on MemoryPeriod {
  String get query => switch (this) {
    MemoryPeriod.today => 'today',
    MemoryPeriod.week => '7d',
    MemoryPeriod.month => '30d',
    MemoryPeriod.all => 'all',
  };
}

/// The memory overview screen state (cortex #65): the overview numbers, the
/// filtered item pages or groups, and the open memory. The backend groups,
/// merges and labels; this controller only keeps the filters and pages.
class MemoryController extends ChangeNotifier {
  MemoryController({required this.api});
  final CortexApi api;
  MemorySource source = MemorySource.all;
  MemoryPeriod period = MemoryPeriod.all;
  String query = '';

  /// The open group (a chat, file, person or topic) of a grouped source.
  MemoryGroup? group;
  MemoryOverview? overview;
  final items = <MemoryItem>[];
  final groups = <MemoryGroup>[];
  String? nextCursor;
  int total = 0;
  bool loading = false, loadingMore = false;
  ApiError? error;
  MemoryDetail? detail;
  bool detailLoading = false;
  ApiError? detailError;
  int _listRequest = 0, _detailRequest = 0;
  bool _disposed = false;

  bool get grouped => source != MemorySource.all && source != MemorySource.note;

  /// True when filters differ from the default view.
  bool get filtered =>
      source != MemorySource.all ||
      period != MemoryPeriod.all ||
      query.isNotEmpty;

  ApiError _error(Object e) => e is ApiError ? e : const ApiError(0, null, '');

  Future<void> load() async {
    await Future.wait([_loadOverview(), reload()]);
  }

  Future<void> _loadOverview() async {
    try {
      final result = await api.memoryOverview();
      if (_disposed) return;
      overview = result;
    } catch (e) {
      if (_disposed) return;
      error ??= _error(e);
    }
    notifyListeners();
  }

  /// First page for the current filters.
  Future<void> reload() async {
    final request = ++_listRequest;
    loading = true;
    notifyListeners();
    try {
      final page = await api.memoryItems(
        source: source.name,
        groupId: group?.id,
        period: period.query,
        query: query,
      );
      if (_disposed || request != _listRequest) return;
      items
        ..clear()
        ..addAll(page.items);
      groups
        ..clear()
        ..addAll(page.groups);
      nextCursor = page.nextCursor;
      total = page.total;
      error = null;
    } catch (e) {
      if (_disposed || request != _listRequest) return;
      error = _error(e);
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    final cursor = nextCursor;
    if (cursor == null || loadingMore) return;
    final request = _listRequest;
    loadingMore = true;
    notifyListeners();
    try {
      final page = await api.memoryItems(
        source: source.name,
        groupId: group?.id,
        period: period.query,
        query: query,
        cursor: cursor,
      );
      if (_disposed || request != _listRequest) return;
      items.addAll(page.items);
      nextCursor = page.nextCursor;
    } catch (e) {
      if (_disposed || request != _listRequest) return;
      error = _error(e);
    }
    loadingMore = false;
    notifyListeners();
  }

  void setSource(MemorySource value) {
    source = value;
    group = null;
    reload();
  }

  void setPeriod(MemoryPeriod value) {
    period = value;
    reload();
  }

  void setQuery(String value) {
    query = value.trim();
    reload();
  }

  void openGroup(MemoryGroup? value) {
    group = value;
    reload();
  }

  void clearFilters() {
    source = MemorySource.all;
    period = MemoryPeriod.all;
    query = '';
    group = null;
    reload();
  }

  Future<void> open(String? id) async {
    final request = ++_detailRequest;
    if (id == null) {
      detail = null;
      detailError = null;
      detailLoading = false;
      notifyListeners();
      return;
    }
    detailLoading = true;
    notifyListeners();
    try {
      final result = await api.memoryDetail(id);
      if (_disposed || request != _detailRequest) return;
      detail = result;
      detailError = null;
    } catch (e) {
      if (_disposed || request != _detailRequest) return;
      detail = null;
      detailError = _error(e);
    }
    detailLoading = false;
    notifyListeners();
  }

  /// The copies of a merged row: time and text, read once when the row
  /// opens (at most 20).
  final stacks = <String, List<MemoryDetail>>{};

  Future<void> loadStack(MemoryItem item) async {
    final ids = item.stack?.ids ?? const <String>[];
    if (ids.isEmpty || stacks.containsKey(item.id)) return;
    stacks[item.id] = const [];
    notifyListeners();
    final copies = <MemoryDetail>[];
    for (final id in ids.take(20)) {
      try {
        copies.add(await api.memoryDetail(id));
      } catch (_) {}
      if (_disposed) return;
    }
    stacks[item.id] = copies;
    notifyListeners();
  }

  /// Delete one memory, then reload the numbers and the list.
  Future<void> delete(String id) async {
    await api.deleteMemory(id);
    if (_disposed) return;
    detail = null;
    await load();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
