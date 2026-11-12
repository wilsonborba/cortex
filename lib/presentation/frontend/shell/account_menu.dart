import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../preferences.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';

List<(ThemeMode, String)> themes(AppLocalizations l) => [
  (ThemeMode.system, l.systemChoice),
  (ThemeMode.light, l.lightChoice),
  (ThemeMode.dark, l.darkChoice),
];
List<(Locale?, String)> languages(AppLocalizations l) => [
  (null, l.systemChoice),
  (const Locale('en'), l.languageEnglish),
  (const Locale('pt', 'BR'), l.languagePortugueseBrazil),
  (const Locale('th'), l.languageThai),
];

class AccountMenu extends StatefulWidget {
  const AccountMenu({
    super.key,
    required this.preferences,
    required this.onLogOut,
    this.email,
    this.iconOnly = false,
    this.onSettings,
  });
  final Preferences preferences;
  final VoidCallback onLogOut;
  final String? email;
  final bool iconOnly;
  final VoidCallback? onSettings;
  @override
  State<AccountMenu> createState() => _AccountMenuState();
}

class _AccountMenuState extends State<AccountMenu> {
  final focus = FocusNode();
  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = widget.preferences;
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => MenuAnchor(
        childFocusNode: focus,
        style: const MenuStyle(alignment: Alignment.topLeft),
        menuChildren: [
          Padding(
            padding: const EdgeInsets.all(Space.s12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Space.sidebarWidth),
              child: Text(
                widget.email ?? l.account,
                key: const Key('account-email'),
                softWrap: true,
              ),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(Space.s8),
            child: Text(l.appearance, style: TextStyles.label),
          ),
          for (final (mode, label) in themes(l))
            MenuItemButton(
              closeOnActivate: false,
              leadingIcon: Icon(
                prefs.theme == mode
                    ? AppIcons.copied
                    : mode == ThemeMode.dark
                    ? AppIcons.darkTheme
                    : mode == ThemeMode.light
                    ? AppIcons.lightTheme
                    : AppIcons.systemTheme,
              ),
              onPressed: () => prefs.theme = mode,
              child: Text(label),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(Space.s8),
            child: Text(l.language, style: TextStyles.label),
          ),
          for (final (locale, label) in languages(l))
            MenuItemButton(
              closeOnActivate: false,
              leadingIcon: Icon(
                prefs.locale == locale ? AppIcons.copied : AppIcons.language,
              ),
              onPressed: () => prefs.locale = locale,
              child: Text(label),
            ),
          const Divider(),
          MenuItemButton(
            leadingIcon: const Icon(AppIcons.settings),
            onPressed: widget.onSettings ?? () => context.push('/v1/settings'),
            child: Text(l.settings),
          ),
          MenuItemButton(
            leadingIcon: const Icon(AppIcons.logOut),
            onPressed: widget.onLogOut,
            child: Text(l.logOut),
          ),
        ],
        builder: (context, controller, _) {
          void toggle() =>
              controller.isOpen ? controller.close() : controller.open();
          if (widget.iconOnly) {
            return IconButton(
              key: const Key('account-button'),
              focusNode: focus,
              tooltip: l.account,
              onPressed: toggle,
              icon: const Icon(AppIcons.account, size: IconSizes.navigation),
            );
          }
          return TextButton(
            key: const Key('account-button'),
            focusNode: focus,
            onPressed: toggle,
            child: Row(
              children: [
                const Icon(AppIcons.account, size: IconSizes.navigation),
                const SizedBox(width: Space.s8),
                Expanded(
                  child: Text(
                    widget.email ?? l.account,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(AppIcons.expand, size: IconSizes.action),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = PreferencesScope.of(context);
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(Space.s24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BackButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/v1/chats'),
                    ),
                    const SizedBox(width: Space.s8),
                    Expanded(
                      child: Text(l.settings, style: TextStyles.section),
                    ),
                  ],
                ),
                const SizedBox(height: Space.s24),
                Text(l.appearance, style: TextStyles.subsection),
                for (final (mode, label) in themes(l))
                  ListTile(
                    title: Text(label),
                    leading: Icon(
                      prefs.theme == mode
                          ? AppIcons.copied
                          : AppIcons.systemTheme,
                    ),
                    onTap: () => prefs.theme = mode,
                  ),
                const SizedBox(height: Space.s24),
                Text(l.language, style: TextStyles.subsection),
                for (final (locale, label) in languages(l))
                  ListTile(
                    title: Text(label),
                    leading: Icon(
                      prefs.locale == locale
                          ? AppIcons.copied
                          : AppIcons.language,
                    ),
                    onTap: () => prefs.locale = locale,
                  ),
                const SizedBox(height: Space.s24),
                Text(l.browserPreferenceNote, style: TextStyles.compact),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
