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
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.settingsTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.themeLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F3F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.4),
                ),
              ),
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  selectedBackgroundColor: scheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide.none,
                ),
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    icon: const Icon(Icons.light_mode_outlined, size: 15),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    icon: const Icon(Icons.dark_mode_outlined, size: 15),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    icon: const Icon(Icons.brightness_auto_outlined, size: 15),
                  ),
                ],
                selected: {controller.themeMode},
                onSelectionChanged: (selection) =>
                    controller.setThemeMode(selection.first),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.languageLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F3F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.4),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: languages.map((lang) {
                    final isSelected = currentCode == lang.code;
                    return InkWell(
                      onTap: () => controller.setLocale(Locale(lang.code)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary.withValues(alpha: isDark ? 0.12 : 0.08)
                              : Colors.transparent,
                          border: lang != languages.last
                              ? Border(
                                  bottom: BorderSide(
                                    color: scheme.outline.withValues(alpha: isDark ? 0.15 : 0.25),
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 16,
                              color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${lang.label} (${lang.native})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141416) : const Color(0xFFF3F3F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.4),
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  l10n.improveInputLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  l10n.improveInputSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                value: controller.improveInput,
                onChanged: (val) => controller.setImproveInput(val),
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
