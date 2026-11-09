import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/frontend/handlers/session_gate.dart';

class CortexApp extends StatefulWidget {
  const CortexApp({super.key});
  @override
  State<CortexApp> createState() => _CortexAppState();
}

class _CortexAppState extends State<CortexApp> {
  final _router = GoRouter(
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/v1/home'),
      GoRoute(path: '/sync', builder: (_, _) => const SessionGate()),
      GoRoute(path: '/v1/home', builder: (_, _) => const SessionGate()),
    ],
  );
  ThemeData theme(Brightness brightness) => ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'Ubuntu Sans',
    fontFamilyFallback: const ['IBM Plex Sans Thai'],
    colorScheme: ColorScheme.fromSeed(
      seedColor: brightness == Brightness.dark
          ? const Color(0xFF6EFF00)
          : const Color(0xFF7C3AED),
      brightness: brightness,
    ),
    scaffoldBackgroundColor: brightness == Brightness.dark
        ? const Color(0xFF090A0C)
        : const Color(0xFFECECEC),
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Cortex',
    routerConfig: _router,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
