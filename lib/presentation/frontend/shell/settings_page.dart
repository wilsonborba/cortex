import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../preferences.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../widgets/common/surfaces.dart';
import 'account_menu.dart';

/// One tab of the Settings page: its path, icons and label (#62).
class SettingsTab {
  const SettingsTab(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon, selectedIcon;
  final String Function(AppLocalizations) label;
}

final settingsTabs = [
  SettingsTab(
    '/v1/settings',
    AppIcons.settings,
    AppIcons.settingsSelected,
    (l) => l.settingsGeneral,
  ),
  SettingsTab(
    '/v1/settings/memory',
    AppIcons.memory,
    AppIcons.memorySelected,
    (l) => l.memory,
  ),
  SettingsTab(
    '/v1/settings/personas',
    AppIcons.personas,
    AppIcons.personasSelected,
    (l) => l.personas,
  ),
];

/// The selected tab: the longest tab path that the location starts with.
SettingsTab settingsTabFor(String location) => settingsTabs.reversed.firstWhere(
  (t) => location == t.path || location.startsWith('${t.path}/'),
  orElse: () => settingsTabs.first,
);

/// Settings page (#62): title `title3`, a vertical tab list (width 200) at
/// medium and expanded width, a scrollable tab row at compact width, and the
/// content of the selected tab.
class SettingsFrame extends StatelessWidget {
  const SettingsFrame({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    final selected = settingsTabFor(location);
    final tabs = [
      for (final t in settingsTabs)
        _Tab(
          tab: t,
          selected: t == selected,
          vertical: !compact,
          onTap: () => context.go(t.path),
        ),
    ];
    final gutter = compact ? Space.s16 : Space.s24;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, Space.s16),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.settings,
                    style: TextStyles.title3.copyWith(color: p.text),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (compact) ...[
          SingleChildScrollView(
            key: const Key('settings-tabs'),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: Row(children: tabs),
          ),
          const SizedBox(height: Space.s8),
          Expanded(child: child),
        ] else
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: gutter),
                  child: SizedBox(
                    key: const Key('settings-tabs'),
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final t in tabs) ...[
                          t,
                          const SizedBox(height: Space.s2),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: Space.s8),
                Expanded(child: child),
              ],
            ),
          ),
      ],
    );
  }
}

/// A Fluent tab: height 40, padding 10 10 10 8, radius 4, icon 20, gap 8,
/// `body1` `text2`. Selected: `selected` fill, `body1Strong` `text`, filled
/// icon and a 3 px `brandForeground1` bar (left when vertical, bottom when
/// horizontal).
class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.selected,
    required this.vertical,
    required this.onTap,
  });
  final SettingsTab tab;
  final bool selected, vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final bar = Container(
      width: vertical ? Strokes.thicker : null,
      height: vertical ? Space.s20 : Strokes.thicker,
      decoration: BoxDecoration(
        color: selected ? p.brandForeground1 : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.circular),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.control),
        child: InkWell(
          key: Key('settings-tab-${tab.path}'),
          borderRadius: BorderRadius.circular(Radii.control),
          hoverColor: p.subtleHover,
          onTap: onTap,
          child: SizedBox(
            height: Space.s40,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.s10,
                    Space.s10,
                    Space.s10,
                    Space.s8,
                  ),
                  child: Row(
                    mainAxisSize: vertical
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? tab.selectedIcon : tab.icon,
                        size: IconSizes.navigation,
                        color: selected ? p.text : p.text2,
                      ),
                      const SizedBox(width: Space.s8),
                      Text(
                        tab.label(l),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: selected
                            ? TextStyles.body1Strong.copyWith(color: p.text)
                            : TextStyles.body1.copyWith(color: p.text2),
                      ),
                    ],
                  ),
                ),
                if (vertical)
                  Positioned(left: 0, top: Space.s10, child: bar)
                else
                  Positioned(left: 0, right: 0, bottom: 0, child: bar),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings > General (#62): theme and language as Fluent fields in a card.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final prefs = PreferencesScope.of(context);
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    Widget field(String label, String description, Widget control) {
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyles.body1Strong.copyWith(color: p.text)),
          const SizedBox(height: Space.s2),
          Text(
            description,
            style: TextStyles.caption1.copyWith(color: p.muted),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.s8),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: Space.s8),
                  control,
                ],
              )
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: Space.s16),
                  control,
                ],
              ),
      );
    }

    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          compact ? Space.s16 : Space.s8,
          0,
          compact ? Space.s16 : Space.s24,
          Space.s24,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Space.personaFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      field(
                        l.themeSwitch,
                        l.themeDescription,
                        ThemeSwitch(preferences: prefs),
                      ),
                      field(
                        l.language,
                        l.languageDescription,
                        LanguageSwitch(preferences: prefs),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Space.s12),
                Text(
                  l.browserPreferenceNote,
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
