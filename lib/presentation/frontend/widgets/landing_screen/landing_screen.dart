import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/responsive.dart';
import '../../handlers/app_preferences_scope.dart';
import 'my_background.dart';

/// Neural Grid Landing Page matching the exact Asodya monochromatic design language from the preview.
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
                                  'AUTONOMOUS NEURAL WORKSPACE',
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
                                'Intelligence without distraction.',
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
                                  'High-throughput reasoning and persistent chat workspace. Built for deep focus with zero telemetry leakage.',
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
                                    const Text(
                                      '[ Get Started ]',
                                      style: TextStyle(
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
                                '[ Single Sign-On • Requires Account ]',
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
                                      'ASODYA CORTEX // TIER 0 WORKSPACE',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: scheme.onSurface.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    Text(
                                      '© 2026 ASODYA. ALL RIGHTS RESERVED.',
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
                'About',
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: isDark ? 'Light Theme' : 'Dark Theme',
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
              child: const Text('Log in'),
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

    return PopupMenuButton<String>(
      tooltip: 'Language',
      initialValue: currentCode,
      onSelected: (code) => prefs.setLocale(Locale(code)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentCode.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: scheme.onSurface),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'en', child: Text('English (EN)')),
        const PopupMenuItem(value: 'pt', child: Text('Português (PT)')),
        const PopupMenuItem(value: 'th', child: Text('ไทย (TH)')),
      ],
    );
  }
}

class _FeatureCardsGrid extends StatelessWidget {
  const _FeatureCardsGrid({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _FeatureCardData(
        num: '01 / ARCHITECTURE',
        title: 'Neural Engine',
        description:
            'Zero-latency contextual streaming backed by local Tier 0 inference and isolated execution parameters.',
      ),
      const _FeatureCardData(
        num: '02 / INTEGRITY',
        title: 'Zero Telemetry Leak',
        description:
            'System telemetry is isolated at the infrastructure boundary. User prompts and conversations remain private.',
      ),
      const _FeatureCardData(
        num: '03 / CONTINUITY',
        title: 'Persistent Drafts',
        description:
            'Local draft caching and resilient session recovery across devices through unified SSO token exchange.',
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
                title: const Text('About Asodya'),
                onTap: () {
                  Navigator.of(context).pop();
                  onAbout();
                },
              ),
              ListTile(
                leading: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                title: Text(isDark ? 'Light Theme' : 'Dark Theme'),
                onTap: () {
                  prefs.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'LANGUAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'pt', label: Text('PT')),
                  ButtonSegment(value: 'th', label: Text('TH')),
                ],
                selected: {prefs.locale?.languageCode ?? 'en'},
                onSelectionChanged: (val) => prefs.setLocale(Locale(val.first)),
              ),
              const Spacer(),
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
                child: const Text(
                  '[ Get Started ]',
                  style: TextStyle(fontWeight: FontWeight.w600),
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
