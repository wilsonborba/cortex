import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'dal/remote/auth_api_adapter.dart';
import 'domain/services/auth_service.dart';
import 'domain/services/session_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/frontend/preferences.dart';
import 'presentation/frontend/router.dart';
import 'presentation/frontend/theme/theme.dart';

class CortexApp extends StatefulWidget {
  const CortexApp({super.key, this.session, this.auth, this.initialLocation});
  final SessionController? session;
  final AuthService? auth;
  final String? initialLocation;
  @override
  State<CortexApp> createState() => _CortexAppState();
}

class _CortexAppState extends State<CortexApp> {
  late final SessionController _session = widget.session ?? SessionController();
  late final AuthService _auth = widget.auth ?? AuthService(AuthApiAdapter());
  GoRouter? _router;
  final _preferences = Preferences();

  @override
  void initState() {
    super.initState();
    // The first redirect needs the real session state.
    _session.refresh().then((_) {
      if (!mounted) return;
      setState(() {
        _router = buildRouter(
          session: _session,
          auth: _auth,
          initialLocation:
              widget.initialLocation ??
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        );
      });
    });
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const delegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];
    final router = _router;
    if (router == null) {
      return MaterialApp(
        theme: cortexTheme(Brightness.light),
        darkTheme: cortexTheme(Brightness.dark),
        localizationsDelegates: delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(),
      );
    }
    return PreferencesScope(
      preferences: _preferences,
      child: ListenableBuilder(
        listenable: _preferences,
        builder: (_, _) => MaterialApp.router(
          title: 'Cortex',
          routerConfig: router,
          locale: _preferences.locale,
          themeMode: _preferences.theme,
          theme: cortexTheme(Brightness.light),
          darkTheme: cortexTheme(Brightness.dark),
          localizationsDelegates: delegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
