import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/settings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/app_preferences_scope.dart';
import 'my_background.dart';

/// Neural Grid Landing Page matching the exact Asodya monochromatic design language.
class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onSignIn,
  });

  final Future<void> Function() onSignIn;

  Future<void> _openAbout() async {
    final uri = Uri.parse('https://asodya.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      endDrawer: isMobile ? _LandingMobileDrawer(onSignIn: onSignIn, onAbout: _openAbout) : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MyBackground(),
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                _LandingNavBar(
                  onSignIn: onSignIn,
                  onAbout: _openAbout,
                ),
                // Main Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 20 : 32,
                            vertical: isMobile ? 32 : 56,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Pill Tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.5),
                                  ),
                                ),
                                child: Text(
                                  l10n.landingTag,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5,
                                    color: scheme.onSurface.withValues(alpha: 0.75),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Hero Title
                              Text(
                                l10n.landingHeroTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 32 : 54,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1.5,
                                  height: 1.1,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Hero Description
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 580),
                                child: Text(
                                  l10n.landingHeroSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobile ? 15 : 18,
                                    height: 1.6,
                                    color: scheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                              // CTA Box
                              ElevatedButton(
                                onPressed: () => onSignIn(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: scheme.primary,
                                  foregroundColor: scheme.onPrimary,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '[ ${l10n.getStarted} ]',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward,
                                      size: 16,
                                      color: scheme.onPrimary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.ssoAuthHint,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: scheme.onSurface.withValues(alpha: 0.45),
                                ),
                              ),
                              const SizedBox(height: 64),
                              // 3 Feature Cards Grid
                              _FeatureCardsGrid(isMobile: isMobile),
                              const SizedBox(height: 48),
                              // Footer
                              const Divider(height: 32),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  runAlignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    Text(
                                      '${l10n.footerWorkspace} (${AppSettings.buildVersion})',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: scheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    Text(
                                      l10n.allRightsReserved,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: scheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingNavBar extends StatelessWidget {
  const _LandingNavBar({
    required this.onSignIn,
    required this.onAbout,
  });

  final Future<void> Function() onSignIn;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final scheme = Theme.of(context).colorScheme;
    final prefs = AppPreferencesScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 32,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: scheme.outline.withValues(alpha: isDark ? 0.2 : 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo & Brand
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'lib/presentation/assets/img/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.hub, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                'CORTEX',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            )
          else ...[
            TextButton(
              onPressed: onAbout,
              child: Text(
                l10n.aboutAsodya,
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: isDark ? l10n.themeLight : l10n.themeDark,
              icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined, size: 18),
              onPressed: () {
                prefs.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              },
            ),
            const SizedBox(width: 8),
            _LanguageDropdown(prefs: prefs),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: () => onSignIn(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(l10n.logIn),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.prefs});

  final AppPreferencesController prefs;

  @override
  Widget build(BuildContext context) {
    final currentCode = prefs.locale?.languageCode ?? 'en';
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    final languages = [
      (code: 'en', label: l10n.languageEnglish, native: 'English'),
      (code: 'pt', label: l10n.languagePortuguese, native: 'Português'),
      (code: 'th', label: l10n.languageThai, native: 'ไทย'),
    ];

    return PopupMenuButton<String>(
      tooltip: l10n.languageLabel,
      initialValue: currentCode,
      elevation: 6,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
      ),
      onSelected: (code) => prefs.setLocale(Locale(code)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: scheme.outline.withValues(alpha: isDark ? 0.25 : 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language_rounded, size: 15, color: scheme.onSurface.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              currentCode.toUpperCase(),
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 15, color: scheme.onSurface.withValues(alpha: 0.6)),
          ],
        ),
      ),
      itemBuilder: (context) => languages.map((lang) {
        final isSelected = currentCode == lang.code;
        return PopupMenuItem<String>(
          value: lang.code,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      lang.native,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check,
                  size: 16,
                  color: scheme.primary,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FeatureCardsGrid extends StatelessWidget {
  const _FeatureCardsGrid({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cards = [
      _FeatureCardData(
        num: l10n.card1Number,
        title: l10n.card1Title,
        description: l10n.card1Description,
      ),
      _FeatureCardData(
        num: l10n.card2Number,
        title: l10n.card2Title,
        description: l10n.card2Description,
      ),
      _FeatureCardData(
        num: l10n.card3Number,
        title: l10n.card3Title,
        description: l10n.card3Description,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _FeatureCard(data: c),
        )).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards.map((c) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _FeatureCard(data: c),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FeatureCardData {
  const _FeatureCardData({
    required this.num,
    required this.title,
    required this.description,
  });

  final String num;
  final String title;
  final String description;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.data});

  final _FeatureCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Architectural Corner Crosshairs
          const Positioned(top: -6, left: -4, child: _Crosshair()),
          const Positioned(bottom: -6, right: -4, child: _Crosshair()),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.num,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.description,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingMobileDrawer extends StatelessWidget {
  const _LandingMobileDrawer({
    required this.onSignIn,
    required this.onAbout,
  });

  final Future<void> Function() onSignIn;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    final prefs = AppPreferencesScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final currentCode = prefs.locale?.languageCode ?? 'en';
    final l10n = AppLocalizations.of(context);

    final languages = [
      (code: 'en', label: l10n.languageEnglish, native: 'English'),
      (code: 'pt', label: l10n.languagePortuguese, native: 'Português'),
      (code: 'th', label: l10n.languageThai, native: 'ไทย'),
    ];

    return Drawer(
      backgroundColor: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'lib/presentation/assets/img/logo.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.hub, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CORTEX',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutAsodya),
                onTap: () {
                  Navigator.of(context).pop();
                  onAbout();
                },
              ),
              ListTile(
                leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                title: Text(isDark ? l10n.themeLight : l10n.themeDark),
                onTap: () {
                  prefs.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.languageLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
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
                        onTap: () => prefs.setLocale(Locale(lang.code)),
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
              const Spacer(),
              Text(
                'BUILD // ${AppSettings.buildVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSignIn();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  '[ ${l10n.getStarted} ]',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Crosshair extends StatelessWidget {
  const _Crosshair();

  @override
  Widget build(BuildContext context) {
    return Text(
      '+',
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
