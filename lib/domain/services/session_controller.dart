import 'package:flutter/foundation.dart';
import '../models/session_status.dart';
import 'session_service.dart';

/// Live sign-in state for the router (28.2). It reads the real cookie each time.
class SessionController extends ChangeNotifier {
  SessionController({this.service = const SessionService()});
  final SessionService service;
  bool _signedIn = false;
  bool get signedIn => _signedIn;

  Future<void> refresh() async {
    final value = (await service.currentStatus()).canEnterChat;
    if (value != _signedIn) {
      _signedIn = value;
      notifyListeners();
    }
  }
}
