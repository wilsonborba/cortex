import 'package:flutter/foundation.dart';
import '../../dal/remote/cortex_api.dart';
import '../models/api.dart';
import '../models/persona.dart';

class PersonaController extends ChangeNotifier {
  PersonaController({required this.api});
  final CortexApi api;
  List<Persona>? items;
  String query = '';
  String? type;
  bool loading = false;
  ApiError? error;
  int _request = 0;
  bool _disposed = false;
  Future<void> load() async {
    final request = ++_request;
    loading = true;
    notifyListeners();
    try {
      final result = await api.personas(
        query: query.isEmpty ? null : query,
        type: type,
      );
      if (_disposed || request != _request) return;
      items = result;
      error = null;
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
