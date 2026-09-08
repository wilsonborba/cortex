import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/utils/responsive.dart';
import '../../handlers/app_preferences_scope.dart';
import 'my_background.dart';

/// Neural Grid Landing Page matching the Asodya monochromatic design language.
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
                // Hero Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: isMobile ? 420 : 640),
                        child: _LandingHeroContent(
                          onSignIn: onSignIn,
                          isDark: isDark,
                          scheme: scheme,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.onSurface.withValues(alpha: 0.08),
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
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
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
                  Text(
                    'CORTEX',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: scheme.onSurface,
                    ),
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
                leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
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
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingHeroContent extends StatelessWidget {
  const _LandingHeroContent({
    required this.onSignIn,
    required this.isDark,
    required this.scheme,
  });

  final Future<void> Function() onSignIn;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.35 : 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Micro Crosshairs at container corners
          const Positioned(top: -42, left: -42, child: _Crosshair()),
          const Positioned(top: -42, right: -42, child: _Crosshair()),
          const Positioned(bottom: -42, left: -42, child: _Crosshair()),
          const Positioned(bottom: -42, right: -42, child: _Crosshair()),

          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: scheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'TIER 0 // AUTONOMOUS WORKSPACE',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'CORTEX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Autonomous agent workspace built with high-determinism execution and unified memory orchestration.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => onSignIn(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '[ Get Started ]',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

