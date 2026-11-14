import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../preferences.dart';
import '../theme/app_icons.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/common/buttons.dart';
import '../widgets/common/states.dart';
import 'account_menu.dart';
import 'details_panel.dart';

class _Destination {
  const _Destination(this.path, this.icon, this.selectedIcon, this.label);
  final String path;

  /// Regular glyph at rest, filled glyph when selected (Fluent rule).
  final IconData icon, selectedIcon;
  IconData iconFor(bool selected) => selected ? selectedIcon : icon;
  final String Function(AppLocalizations) label;
}

/// Chats is a rail item only: the sidebar shows the chat history instead.
/// Memory and Personas are tabs of Settings (#62 update).
final _chats = _Destination(
  '/v1/chats',
  AppIcons.chats,
  AppIcons.chatsSelected,
  (l) => l.chats,
);
final _usage = _Destination(
  '/v1/usage',
  AppIcons.usage,
  AppIcons.usageSelected,
  (l) => l.usage,
);

const _logo = 'lib/presentation/frontend/assets/img/logo.png';

/// The 4 x 20 px selected indicator bar with a circular radius (#62).
class _Indicator extends StatelessWidget {
  const _Indicator({required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Container(
      width: Strokes.navIndicator,
      height: Space.s20,
      decoration: BoxDecoration(
        color: selected ? p.brandForeground1 : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.circular),
      ),
    );
  }
}

/// Fluent nav item (#62): height 40, padding 10 10 10 8, radius 4, icon 20,
/// gap 8, `body1` `text2`. Hover `subtleHover`. Selected: `selected` fill,
/// `body1Strong` `text`, filled icon and the indicator bar.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });
  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected ? p.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.control),
        child: InkWell(
          key: Key('nav-${destination.path}'),
          borderRadius: BorderRadius.circular(Radii.control),
          hoverColor: p.subtleHover,
          onTap: onTap,
          child: SizedBox(
            height: Space.s40,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Space.s10,
                    Space.s10,
                    Space.s10,
                    Space.s8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        destination.iconFor(selected),
                        size: IconSizes.navigation,
                        color: selected ? p.text : p.text2,
                      ),
                      const SizedBox(width: Space.s8),
                      Expanded(
                        child: Text(
                          destination.label(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: selected
                              ? TextStyles.body1Strong.copyWith(color: p.text)
                              : TextStyles.body1.copyWith(color: p.text2),
                        ),
                      ),
                    ],
                  ),
                ),
                _Indicator(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rail item (#62): a 40 x 40 icon only button with a tooltip; selected uses
/// the filled icon and the indicator bar.
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.itemKey,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final Key? itemKey;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return SizedBox(
      width: Space.railWidth,
      height: Space.s40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            key: itemKey,
            tooltip: tooltip,
            isSelected: selected,
            style: IconButton.styleFrom(
              fixedSize: const Size.square(Space.s40),
              minimumSize: const Size.square(Space.s40),
              backgroundColor: selected ? p.selected : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.control),
              ),
            ),
            icon: Icon(
              icon,
              size: IconSizes.navigation,
              color: selected ? p.text : p.text2,
            ),
            onPressed: onPressed,
          ),
          Positioned(
            left: Space.s4,
            child: _Indicator(selected: selected),
          ),
        ],
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
    required this.details,
    required this.onLogOut,
    this.chatList,
    this.emailLoader,
  });
  final String location;
  final Widget child;
  final DetailsController details;
  final VoidCallback onLogOut;
  final Widget? chatList;
  final Future<String?> Function()? emailLoader;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final fallback = Preferences();
  String? email;
  int emailGeneration = 0;
  @override
  void initState() {
    super.initState();
    final generation = emailGeneration;
    widget.emailLoader
        ?.call()
        .then((value) {
          if (mounted && generation == emailGeneration) {
            setState(() => email = value);
          }
        })
        .catchError((Object _) {});
  }

  @override
  void dispose() {
    fallback.dispose();
    super.dispose();
  }

  Widget _account(
    Preferences preferences, {
    bool iconOnly = false,
    VoidCallback? onSettings,
  }) => AccountMenu(
    preferences: preferences,
    onSettings: onSettings,
    email: email,
    iconOnly: iconOnly,
    onLogOut: () {
      setState(() => email = null);
      widget.onLogOut();
    },
  );

  bool _at(String path) =>
      widget.location == path || widget.location.startsWith('$path/');

  /// Sidebar (#62): width 260, `surface`, 1 px `divider` on the right, no
  /// shadow and no radius. Logo and hamburger, New chat (the one primary
  /// button), Temporary chat, Usage, the chat history and the account menu.
  Widget _sidebar(
    BuildContext context,
    Preferences prefs, {
    bool drawer = false,
  }) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    void go(String path) {
      if (drawer) Navigator.of(context).pop();
      context.go(path);
    }

    return Container(
      key: const Key('sidebar'),
      width: Space.sidebarWidth,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.divider)),
      ),
      padding: const EdgeInsets.all(Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                _logo,
                width: Space.s28,
                height: Space.s28,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: Space.s8),
              Expanded(
                child: Text(
                  'Cortex',
                  style: TextStyles.subtitle2.copyWith(color: p.text),
                ),
              ),
              IconButton(
                key: const Key('sidebar-toggle'),
                tooltip: drawer ? l.close : l.collapseSidebar,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(Space.s32),
                  minimumSize: const Size.square(Space.s32),
                ),
                icon: Icon(
                  drawer ? AppIcons.close : AppIcons.menu,
                  size: IconSizes.navigation,
                ),
                onPressed: () {
                  if (drawer) {
                    Navigator.of(context).pop();
                  } else {
                    prefs.collapsed = true;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: Space.s16),
          AppButton.primary(
            label: l.newChat,
            icon: AppIcons.newChat,
            size: ButtonSize.medium,
            onPressed: () => go('/v1/chats'),
          ),
          const SizedBox(height: Space.s8),
          AppButton(
            label: l.temporaryChat,
            kind: ButtonKind.subtle,
            icon: AppIcons.temporaryChat,
            size: ButtonSize.medium,
            onPressed: () => go('/v1/chats/temporary'),
          ),
          const SizedBox(height: Space.s16),
          _NavItem(
            destination: _usage,
            selected: _at(_usage.path),
            onTap: () => go(_usage.path),
          ),
          Expanded(
            child:
                widget.chatList ??
                EmptyState(title: l.noChatsYet, icon: AppIcons.chats),
          ),
          const SizedBox(height: Space.s8),
          _account(
            prefs,
            onSettings: () {
              if (drawer) Navigator.of(context).pop();
              context.push('/v1/settings');
            },
          ),
        ],
      ),
    );
  }

  /// Rail (#62): 48 wide, icon only items 40 x 40 with tooltips.
  Widget _rail(BuildContext context, Preferences prefs, bool expandable) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Container(
      key: const Key('rail'),
      width: Space.railWidth,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: Space.s12),
      child: Column(
        children: [
          if (expandable) ...[
            _RailItem(
              itemKey: const Key('sidebar-toggle'),
              tooltip: l.expandSidebar,
              icon: AppIcons.menu,
              onPressed: () => prefs.collapsed = false,
            ),
            const SizedBox(height: Space.s8),
          ],
          _RailItem(
            tooltip: l.newChat,
            icon: AppIcons.newChat,
            onPressed: () => context.go('/v1/chats'),
          ),
          const SizedBox(height: Space.s2),
          _RailItem(
            tooltip: l.temporaryChat,
            icon: AppIcons.temporaryChat,
            onPressed: () => context.go('/v1/chats/temporary'),
          ),
          const SizedBox(height: Space.s8),
          for (final d in [_chats, _usage]) ...[
            _RailItem(
              tooltip: d.label(l),
              icon: d.iconFor(_at(d.path)),
              selected: _at(d.path),
              onPressed: () => context.go(d.path),
            ),
            const SizedBox(height: Space.s2),
          ],
          const Spacer(),
          _account(prefs, iconOnly: true),
        ],
      ),
    );
  }

  /// Inline details panel (#62): width 320, `surface`, 1 px `divider` on the
  /// left, header `subtitle2` with a subtle 32 close button.
  Widget _details(BuildContext context) => ValueListenableBuilder<Widget?>(
    valueListenable: widget.details,
    builder: (context, content, _) {
      if (content == null) return const SizedBox();
      final p = Palette.from(context);
      return Container(
        key: const Key('details-panel'),
        width: Space.detailsWidth,
        decoration: BoxDecoration(
          color: p.surface,
          border: Border(left: BorderSide(color: p.divider)),
        ),
        child: _DetailsBody(details: widget.details, content: content),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final prefs = PreferencesScope.maybeOf(context) ?? fallback;
    return PreferencesScope(
      preferences: prefs,
      child: ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final size = SizeClass.of(MediaQuery.sizeOf(context).width);
          final compact = size == SizeClass.compact;
          final expanded = size == SizeClass.expanded;
          final l = AppLocalizations.of(context);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape):
                  widget.details.close,
            },
            child: Scaffold(
              appBar: compact
                  ? AppBar(
                      title: const Text('Cortex'),
                      leading: Builder(
                        builder: (context) => IconButton(
                          key: const Key('drawer-button'),
                          tooltip: l.menu,
                          icon: const Icon(AppIcons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    )
                  : null,
              drawer: compact
                  ? Drawer(
                      width: Space.sidebarWidth,
                      // List rows are 44 high at compact width (#61).
                      child: ListTileTheme.merge(
                        minTileHeight: Controls.minTouch,
                        child: Builder(
                          builder: (context) => SafeArea(
                            child: _sidebar(context, prefs, drawer: true),
                          ),
                        ),
                      ),
                    )
                  : null,
              body: Row(
                children: [
                  if (!compact)
                    expanded && !prefs.collapsed
                        ? _sidebar(context, prefs)
                        : _rail(context, prefs, expanded),
                  Expanded(
                    key: const ValueKey('workspace'),
                    child: expanded
                        ? widget.child
                        : _DetailsSheet(
                            details: widget.details,
                            child: SafeArea(child: widget.child),
                          ),
                  ),
                  if (expanded) _details(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Header (`subtitle2` and a subtle 32 close button) and the scrolling
/// content of the details panel, drawer and sheet (#62).
class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.details,
    required this.content,
    this.onClose,
    this.sheet = false,
  });
  final DetailsController details;
  final Widget content;
  final VoidCallback? onClose;
  final bool sheet;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final body = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.s16, 0, Space.s16, Space.s16),
      child: content,
    );
    return Column(
      mainAxisSize: sheet ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s16,
            Space.s12,
            Space.s8,
            Space.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l.details,
                    style: TextStyles.subtitle2.copyWith(color: p.text),
                  ),
                ),
              ),
              IconButton(
                tooltip: l.close,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(Space.s32),
                  minimumSize: const Size.square(Space.s32),
                ),
                icon: const Icon(AppIcons.close, size: IconSizes.action),
                onPressed: onClose ?? details.close,
              ),
            ],
          ),
        ),
        if (sheet) Flexible(child: body) else Expanded(child: body),
      ],
    );
  }
}

/// Details on medium width open in a modal drawer from the right, and on
/// compact width in a bottom sheet with top corners 12 (#62). Both use
/// `shadow64`, the `overlay` scrim and a 300 ms decelerateMid enter.
class _DetailsSheet extends StatefulWidget {
  const _DetailsSheet({required this.details, required this.child});
  final DetailsController details;
  final Widget child;
  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  @override
  void initState() {
    super.initState();
    widget.details.addListener(_open);
  }

  @override
  void dispose() {
    widget.details.removeListener(_open);
    super.dispose();
  }

  Widget _keys(BuildContext context, Widget child) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () =>
          Navigator.pop(context),
    },
    child: Focus(autofocus: true, child: child),
  );

  Future<void> _open() async {
    final content = widget.details.value;
    if (content == null || !mounted) return;
    final p = Palette.from(context);
    final b = Theme.of(context).brightness;
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    final duration = MediaQuery.maybeDisableAnimationsOf(context) == true
        ? Duration.zero
        : MotionDurations.slow;
    if (compact) {
      await showModalBottomSheet<void>(
        context: context,
        barrierColor: p.overlay,
        backgroundColor: Colors.transparent,
        elevation: 0,
        isScrollControlled: true,
        sheetAnimationStyle: AnimationStyle(
          curve: MotionCurves.decelerateMid,
          duration: duration,
        ),
        builder: (sheetContext) => _keys(
          sheetContext,
          Container(
            key: const Key('details-sheet'),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.9,
            ),
            decoration: BoxDecoration(
              color: p.raised,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.sheet),
              ),
              boxShadow: Shadows.shadow64(b),
            ),
            child: SafeArea(
              top: false,
              child: _DetailsBody(
                details: widget.details,
                content: content,
                sheet: true,
                onClose: () => Navigator.pop(sheetContext),
              ),
            ),
          ),
        ),
      );
    } else {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: AppLocalizations.of(context).close,
        barrierColor: p.overlay,
        transitionDuration: duration,
        pageBuilder: (dialogContext, _, _) => Align(
          alignment: Alignment.centerRight,
          child: _keys(
            dialogContext,
            Material(
              key: const Key('details-sheet'),
              color: p.raised,
              child: Container(
                width: Space.detailsWidth,
                height: double.infinity,
                decoration: BoxDecoration(boxShadow: Shadows.shadow64(b)),
                child: SafeArea(
                  child: _DetailsBody(
                    details: widget.details,
                    content: content,
                    onClose: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ),
          ),
        ),
        transitionBuilder: (_, animation, _, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: MotionCurves.decelerateMid,
              reverseCurve: MotionCurves.accelerateMid,
            ),
          ),
          child: child,
        ),
      );
    }
    widget.details.close();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
