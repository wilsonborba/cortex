import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import '../../../dal/local/local_storage_adapter.dart';
import '../../../dal/remote/auth_api_adapter.dart';
import '../../../domain/models/session_status.dart';
import '../../../domain/services/auth_service.dart';
import '../../../domain/services/session_service.dart';
import '../widgets/chat_screen/chat_screen.dart';
import '../widgets/landing_screen/landing_screen.dart';

/// Routing widget: decides whether the visitor sees the [LandingScreen] or
/// the [ChatScreen], and owns the [AuthService] both the landing page and (in
/// the future) the chat screen's sign-out affordance depend on.
///
/// No business/session logic lives in the widgets themselves: this handler
/// resolves the initial `SessionStatus` (checking `auth_apps`'s `/sync`
/// return route first, then the locally persisted flags), and hands the
/// result down as a simple `canEnterChat` boolean.
class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final AuthService _authService;
  SessionStatus? _status;

  @override
  void initState() {
    super.initState();
    const storage = LocalStorageAdapter();
    final sessionService = SessionService(storage);
    _authService = AuthService(AuthApiAdapter(), sessionService);
    _resolveInitialStatus(sessionService);
  }

  Future<void> _resolveInitialStatus(SessionService sessionService) async {
    final consumed = await _authService.tryConsumeReturnUri(Uri.base);
    if (consumed && kIsWeb) {
      // Drop `?auth_exchange_token=...` from the address bar: the token is
      // single-use and already redeemed, keeping it around only invites a
      // confusing failure on refresh.
      urlStrategy?.replaceState(null, 'Cortex', '/');
    }

    final status = await sessionService.currentStatus();
    if (!mounted) return;
    setState(() => _status = status);
  }

  void _onGuestContinue() {
    _authService.continueAsGuest().then((_) {
      if (!mounted) return;
      setState(() => _status = SessionStatus.guest);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (status.canEnterChat) {
      return const ChatScreen();
    }

    return LandingScreen(
      onSignIn: _authService.signInWithSso,
      onContinueAsGuest: _onGuestContinue,
    );
  }
}
