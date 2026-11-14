import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../preferences.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../widgets/common/segmented_switch.dart';
import '../widgets/common/surfaces.dart';

/// The three languages of the switch, as short codes (#62).
const _languages = [
  ('en', Locale('en'), 'EN'),
  ('pt', Locale('pt', 'BR'), 'PT'),
  ('th', Locale('th'), 'TH'),
];

/// Language switch "EN | PT | TH" (#62). With no saved choice it shows the
/// language in use: the browser language when it is one of the three, else
/// English.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key, required this.preferences});
  final Preferences preferences;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final code = Localizations.localeOf(context).languageCode;
    final names = {
      'en': l.languageEnglish,
      'pt': l.languagePortugueseBrazil,
      'th': l.languageThai,
    };
    return SegmentedSwitch<String>(
      key: const Key('language-switch'),
      label: l.language,
      selected: _languages.any((e) => e.$1 == code) ? code : 'en',
      onChanged: (v) =>
          preferences.locale = _languages.firstWhere((e) => e.$1 == v).$2,
      options: [
        for (final (code, _, text) in _languages)
          SegmentOption(value: code, text: text, tooltip: names[code]!),
      ],
    );
  }
}

/// Theme switch with 3 icon options: System, Light, Dark (#62).
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key, required this.preferences});
  final Preferences preferences;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SegmentedSwitch<ThemeMode>(
      key: const Key('theme-switch'),
      label: l.themeSwitch,
      selected: preferences.theme,
      onChanged: (v) => preferences.theme = v,
      options: [
        SegmentOption(
          value: ThemeMode.system,
          icon: AppIcons.systemTheme,
          tooltip: l.systemChoice,
        ),
        SegmentOption(
          value: ThemeMode.light,
          icon: AppIcons.lightTheme,
          tooltip: l.lightChoice,
        ),
        SegmentOption(
          value: ThemeMode.dark,
          icon: AppIcons.darkTheme,
          tooltip: l.darkChoice,
        ),
      ],
    );
  }
}

/// 32 px circular avatar: the first letter of the email in `caption1Strong`
/// on `tagBackground`, or the account icon when there is no email.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, this.email});
  final String? email;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final letter = (email ?? '').trim();
    return Container(
      width: Space.s32,
      height: Space.s32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.tagBackground, shape: BoxShape.circle),
      child: letter.isEmpty
          ? Icon(AppIcons.account, size: IconSizes.small, color: p.text2)
          : Text(
              letter.characters.first.toUpperCase(),
              style: TextStyles.caption1Strong.copyWith(color: p.text),
            ),
    );
  }
}

/// Account menu at the bottom of the sidebar (#62): avatar, "Account" and the
/// email. The menu has Settings, the theme and language switches (one row
/// each, no submenu), a divider and Log out.
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
  final first = FocusNode(debugLabel: 'account-settings');
  @override
  void dispose() {
    focus.dispose();
    first.dispose();
    super.dispose();
  }

  /// A menu opened with the keyboard puts focus on its first item (Fluent).
  void _focusFirst() {
    if (FocusManager.instance.highlightMode != FocusHighlightMode.traditional) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && first.context != null) first.requestFocus();
    });
  }

  /// One menu row with a label and a switch. Arrow keys move in tab order
  /// here: the default directional search would also see the pages under a
  /// pushed page.
  Widget _switchRow(String label, Widget control) => Actions(
    actions: {
      DirectionalFocusIntent: CallbackAction<DirectionalFocusIntent>(
        onInvoke: (intent) {
          final node = FocusManager.instance.primaryFocus;
          switch (intent.direction) {
            case TraversalDirection.down || TraversalDirection.right:
              node?.nextFocus();
            case TraversalDirection.up || TraversalDirection.left:
              node?.previousFocus();
          }
          return null;
        },
      ),
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.s8,
        vertical: Space.s6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyles.body1.copyWith(
                color: Palette.from(context).text,
              ),
            ),
          ),
          const SizedBox(width: Space.s12),
          control,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final prefs = widget.preferences;
    final style = Theme.of(context).menuTheme.style ?? const MenuStyle();
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => MenuAnchor(
        clipBehavior: Clip.none,
        childFocusNode: focus,
        onOpen: _focusFirst,
        style: style.copyWith(
          alignment: Alignment.topLeft,
          minimumSize: const WidgetStatePropertyAll(Size(200, 0)),
        ),
        menuChildren: [
          if (widget.iconOnly) ...[
            Padding(
              padding: const EdgeInsets.all(Space.s8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Space.sidebarWidth),
                child: Text(
                  widget.email ?? l.account,
                  key: const Key('account-email'),
                  style: TextStyles.caption1.copyWith(color: p.muted),
                  softWrap: true,
                ),
              ),
            ),
            const MenuGroupDivider(),
          ],
          MenuItemButton(
            focusNode: first,
            leadingIcon: const Icon(AppIcons.settings),
            onPressed: widget.onSettings ?? () => context.push('/v1/settings'),
            child: Text(l.settings),
          ),
          _switchRow(l.themeSwitch, ThemeSwitch(preferences: prefs)),
          _switchRow(l.language, LanguageSwitch(preferences: prefs)),
          const MenuGroupDivider(),
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
              icon: AccountAvatar(email: widget.email),
            );
          }
          return TextButton(
            key: const Key('account-button'),
            focusNode: focus,
            onPressed: toggle,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.all(Space.s8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.control),
              ),
            ),
            child: Row(
              children: [
                AccountAvatar(email: widget.email),
                const SizedBox(width: Space.s8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.account,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.body1.copyWith(color: p.text),
                      ),
                      if (widget.email != null)
                        Text(
                          widget.email!,
                          key: const Key('account-email'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.caption1.copyWith(color: p.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
