import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/generated/app_localizations.dart';
import 'presentation/frontend/components/app_theme.dart';
import 'presentation/frontend/handlers/app_preferences_scope.dart';
import 'presentation/frontend/handlers/session_gate.dart';

/// Root widget: wires the monochrome [AppTheme] (light/dark/system) and the
/// tri-lingual [AppLocalizations] (en/pt/th), both driven by
/// [AppPreferencesScope], and hands routing to [SessionGate], which decides
/// between the landing page and the chat screen depending on whether a
/// session (or guest flag) is present.
class CortexApp extends StatefulWidget {
  const CortexApp({super.key});

  @override
  State<CortexApp> createState() => _CortexAppState();
}

class _CortexAppState extends State<CortexApp> {
  late final AppPreferencesController _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = AppPreferencesController();
  }

  @override
  void dispose() {
    _preferences.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPreferencesScope(
      controller: _preferences,
      child: AnimatedBuilder(
        animation: _preferences,
        builder: (context, _) {
          return MaterialApp(
            title: 'Cortex',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _preferences.themeMode,
            locale: _preferences.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SessionGate(),
          );
        },
      ),
    );
  }
}
