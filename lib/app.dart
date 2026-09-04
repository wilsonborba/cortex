import 'package:flutter/material.dart';

import 'presentation/frontend/components/app_theme.dart';
import 'presentation/frontend/widgets/chat_screen/chat_screen.dart';

/// Root widget: wires the monochrome [AppTheme] (light/dark) and hosts the
/// responsive chat screen.
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
      home: const ChatScreen(),
    );
  }
}
