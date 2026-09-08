import 'package:flutter/material.dart';

import '../../../core/settings.dart';
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AppSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppPreferencesScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCode = controller.locale?.languageCode ?? 'en';

    final languages = [
      (code: 'en', label: 'English', native: 'English'),
      (code: 'pt', label: 'Português', native: 'Português'),
      (code: 'th', label: 'Thai', native: 'ไทย'),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settingsTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
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
            const SizedBox(height: 20),
            Text(l10n.languageLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: languages.map((lang) {
                    final isSelected = currentCode == lang.code;
                    return InkWell(
                      onTap: () => controller.setLocale(Locale(lang.code)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.surfaceContainerHighest
                              : Colors.transparent,
                          border: lang != languages.last
                              ? Border(
                                  bottom: BorderSide(
                                    color: scheme.outline.withValues(alpha: 0.2),
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.language_rounded,
                              size: 16,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${lang.label} (${lang.native})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, size: 16, color: scheme.primary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text(
                'BUILD // ${AppSettings.buildVersion}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
