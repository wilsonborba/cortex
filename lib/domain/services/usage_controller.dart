import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';
import '../models/telemetry.dart';

/// Values and row access come from the API. Pages keep the server order.
class UsageController extends ChangeNotifier {
  UsageController({required this.api});
  final CortexApi api;
  UsageView view = UsageView.usage;
  UsageData? usage;
  List<TimingAverage>? timing;
  List<GroupStats>? stats;
  List<CallEvent>? events;
  ApiError? error;
  bool loading = false, hasMore = true, _disposed = false;
  int _request = 0;
  static const pageSize = 20;
  Future<void> load(UsageView next, {bool more = false}) async {
    final request = ++_request;
    view = next;
    loading = true;
    error = null;
    notifyListeners();
    try {
      switch (next) {
        case UsageView.usage:
          final value = await api.usage();
          if (_disposed || request != _request) return;
          usage = value;
        case UsageView.timing:
          final value = await api.timing();
          if (_disposed || request != _request) return;
          timing = value;
        case UsageView.stats:
          final value = await api.stats();
          if (_disposed || request != _request) return;
          stats = value;
        case UsageView.events:
          final value = await api.callEvents(
            before: more ? events?.lastOrNull?.cursor : null,
            limit: pageSize,
          );
          if (_disposed || request != _request) return;
          events = [if (more) ...?events, ...value];
          hasMore = value.length == pageSize;
      }
    } on ApiError catch (e) {
      if (_disposed || request != _request) return;
      error = e;
    } catch (_) {
      if (_disposed || request != _request) return;
      error = const ApiError(0, null, '');
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
