import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../handlers/app_preferences_scope.dart';

/// Minimal settings surface: lets the user pick the theme mode (Light,
/// Dark, System) and the app language (English, Portuguese, Thai), both
/// backed by [AppPreferencesScope] and persisted across restarts.
///
/// Opened as a bottom sheet from the chat screen's app bar, on both the
/// desktop and mobile layouts.
class AppSettingsSheet extends StatelessWidget {
  const AppSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const AppSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppPreferencesScope.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            Text(l10n.themeLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (selection) =>
                  controller.setThemeMode(selection.first),
            ),
            const SizedBox(height: 24),
            Text(l10n.languageLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String?>(
              segments: [
                ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                ButtonSegment(value: 'pt', label: Text(l10n.languagePortuguese)),
                ButtonSegment(value: 'th', label: Text(l10n.languageThai)),
              ],
              selected: {controller.locale?.languageCode ?? 'en'},
              onSelectionChanged: (selection) =>
                  controller.setLocale(Locale(selection.first!)),
            ),
          ],
        ),
      ),
    );
  }
}
