import 'package:flutter/material.dart';
import '../../../../core/settings.dart';
import '../../../../l10n/generated/app_localizations.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    super.key,
    required this.signedIn,
    required this.onSignIn,
    this.section,
  });
  final bool signedIn;
  final VoidCallback onSignIn;

  /// Section of the one-page landing to show (#29).
  final String? section;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Cortex'),
      actions: [
        if (!signedIn)
          TextButton(
            onPressed: onSignIn,
            child: Text(AppLocalizations.of(context).logIn),
          ),
      ],
    ),
    bottomNavigationBar: const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(AppSettings.buildVersion),
      ),
    ),
  );
}
