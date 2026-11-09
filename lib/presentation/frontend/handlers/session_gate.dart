import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import '../../../dal/remote/auth_api_adapter.dart';
import '../../../domain/services/auth_service.dart';
import '../../../domain/models/session_status.dart';
import '../../../domain/services/session_service.dart';
import '../widgets/home/desktop_home.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  final _auth = AuthService(AuthApiAdapter());
  bool? _signedIn;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('auth_exchange_token')) {
      await _auth.consumeReturn(uri);
      urlStrategy?.replaceState(null, 'Cortex', '/v1/home');
    }
    final status = await const SessionService().currentStatus();
    if (!mounted) return;
    if (uri.path == '/sync') context.go('/v1/home');
    setState(() => _signedIn = status.canEnterChat);
  }

  @override
  Widget build(BuildContext context) => _signedIn == null
      ? const Scaffold(body: Center(child: CircularProgressIndicator()))
      : HomeShell(signedIn: _signedIn!, onSignIn: _auth.signIn);
}
