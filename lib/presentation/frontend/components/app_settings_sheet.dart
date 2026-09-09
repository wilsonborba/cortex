import 'package:flutter/material.dart';

import '../../../core/settings.dart';
import '../../../dal/remote/auth_api_adapter.dart';
import '../../../domain/services/auth_service.dart';
import '../../../domain/services/session_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../handlers/app_preferences_scope.dart';

/// Minimal settings surface: lets the user pick the theme mode (Light,
/// Dark, System), the app language (English, Portuguese, Thai), the
/// improve-input preference, and sign out. Backed by [AppPreferencesScope]
/// (persisted across restarts) and [AuthService] (sign-out).
///
/// Opened as a bottom sheet from the chat screen's app bar, on both the
/// desktop and mobile layouts. Styled as a compact, iOS-style grouped
/// list: it hugs its own content height (see `show`'s constraints and this
/// build's `SingleChildScrollView` + `Column(mainAxisSize: min)`) instead
/// of always taking up a large fixed fraction of the screen.
class AppSettingsSheet extends StatelessWidget {
  const AppSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Sized to its own content (see `build`'s SingleChildScrollView +
      // Column(mainAxisSize: min)) rather than forced to a fixed fraction
      // of the screen; this only stops it from ever exceeding the screen
      // if content is unusually tall, it does not make it that tall by
      // default.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => const AppSettingsSheet(),
    );
  }

  void _confirmLogOut(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        title: Text(
          l10n.logOutTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          l10n.logOutConfirmation,
          style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel, style: TextStyle(color: scheme.onSurface)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              AuthService(AuthApiAdapter(), const SessionService()).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC53030),
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AppPreferencesScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCode = controller.locale?.languageCode ?? 'en';
    final cardColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final dividerColor = scheme.outline.withValues(alpha: isDark ? 0.15 : 0.2);

    final languages = [
      (code: 'en', label: 'English'),
      (code: 'pt', label: 'Português'),
      (code: 'th', label: 'ไทย'),
    ];

    Widget group(List<Widget> rows) => Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, indent: 16, color: dividerColor),
                rows[i],
              ],
            ],
          ),
        );

    Widget row({
      required Widget child,
      VoidCallback? onTap,
    }) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                l10n.settingsTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
              ),
            ),
            const SizedBox(height: 18),

            // Appearance
            group([
              row(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.themeLabel, style: const TextStyle(fontSize: 14)),
                    ),
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.transparent,
                        selectedBackgroundColor: scheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: dividerColor),
                      ),
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined, size: 15),
                          label: Text(l10n.themeLight, style: const TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined, size: 15),
                          label: Text(l10n.themeDark, style: const TextStyle(fontSize: 11)),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_outlined, size: 15),
                          label: Text(l10n.themeSystem, style: const TextStyle(fontSize: 11)),
                        ),
                      ],
                      selected: {controller.themeMode},
                      onSelectionChanged: (selection) => controller.setThemeMode(selection.first),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Language
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                l10n.languageLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: scheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            group([
              for (final lang in languages)
                row(
                  onTap: () => controller.setLocale(Locale(lang.code)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          lang.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: currentCode == lang.code ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (currentCode == lang.code)
                        Icon(Icons.check, size: 18, color: scheme.primary),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 20),

            // Preferences
            group([
              row(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.improveInputLabel, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            l10n.improveInputSubtitle,
                            style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: controller.improveInput,
                      onChanged: (val) => controller.setImproveInput(val),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // Account
            group([
              row(
                onTap: () => _confirmLogOut(context),
                child: Text(
                  l10n.logOut,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC53030),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 14),

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
