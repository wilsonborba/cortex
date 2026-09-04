import 'package:flutter/material.dart';

import 'presentation/frontend/components/app_theme.dart';
import 'presentation/frontend/handlers/session_gate.dart';

/// Root widget: wires the monochrome [AppTheme] (light/dark) and hands
/// routing to [SessionGate], which decides between the landing page and the
/// chat screen depending on whether a session (or guest flag) is present.
class CortexApp extends StatelessWidget {
  const CortexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cortex',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const SessionGate(),
    );
  }
}
