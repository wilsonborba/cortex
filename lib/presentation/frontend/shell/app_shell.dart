import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../preferences.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.dart';
import '../widgets/common/buttons.dart';
import '../widgets/common/states.dart';
import 'account_menu.dart';
import 'details_panel.dart';

class _Destination {
  const _Destination(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

final _destinations = [
  _Destination('/v1/chats', AppIcons.chats, (l) => l.chats),
  _Destination('/v1/memory', AppIcons.memory, (l) => l.memory),
  _Destination('/v1/personas', AppIcons.personas, (l) => l.personas),
  _Destination('/v1/usage', AppIcons.usage, (l) => l.usage),
];

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
        border: Border(right: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.all(Space.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Cortex', style: TextStyles.subsection)),
              IconButton(
                tooltip: drawer ? l.close : l.collapseSidebar,
                icon: Icon(drawer ? AppIcons.close : AppIcons.collapse),
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
          AppButton(
            kind:
                widget.location.startsWith('/v1/chats') ||
                    widget.location.startsWith('/v1/personas')
                ? ButtonKind.secondary
                : ButtonKind.primary,
            label: l.newChat,
            icon: AppIcons.newChat,
            onPressed: () => go('/v1/chats'),
          ),
          const SizedBox(height: Space.s8),
          AppButton(
            label: l.temporaryChat,
            kind: ButtonKind.quiet,
            icon: AppIcons.temporaryChat,
            onPressed: () => go('/v1/chats/temporary'),
          ),
          const SizedBox(height: Space.s16),
          for (final d in _destinations.skip(1))
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: widget.location.startsWith(d.path)
                        ? p.accent
                        : Colors.transparent,
                    width: Controls.focusRing,
                  ),
                ),
              ),
              child: ListTile(
                title: Text(d.label(l)),
                leading: Icon(d.icon, size: IconSizes.navigation),
                selected: widget.location.startsWith(d.path),
                onTap: () => go(d.path),
              ),
            ),
          const SizedBox(height: Space.s16),
          Text(l.chats, style: TextStyles.label),
          const SizedBox(height: Space.s8),
          Expanded(
            child:
                widget.chatList ??
                EmptyState(title: l.noChatsYet, icon: AppIcons.chats),
          ),
          const SizedBox(height: Space.s12),
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

  Widget _rail(BuildContext context, Preferences prefs, bool expandable) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Container(
      key: const Key('rail'),
      width: Space.railWidth,
      color: p.surface,
      child: Column(
        children: [
          if (expandable)
            IconButton(
              tooltip: l.expandSidebar,
              icon: const Icon(AppIcons.expand),
              onPressed: () => prefs.collapsed = false,
            ),
          IconButton(
            tooltip: l.newChat,
            icon: const Icon(AppIcons.newChat, size: IconSizes.navigation),
            onPressed: () => context.go('/v1/chats'),
          ),
          for (final d in _destinations)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: widget.location.startsWith(d.path)
                        ? p.accent
                        : Colors.transparent,
                    width: Controls.focusRing,
                  ),
                ),
              ),
              child: IconButton(
                tooltip: d.label(l),
                icon: Icon(d.icon, size: IconSizes.navigation),
                onPressed: () => context.go(d.path),
              ),
            ),
          const Spacer(),
          _account(prefs, iconOnly: true),
          const SizedBox(height: Space.s16),
        ],
      ),
    );
  }

  Widget _details(BuildContext context) => ValueListenableBuilder<Widget?>(
    valueListenable: widget.details,
    builder: (context, content, _) => content == null
        ? const SizedBox()
        : SizedBox(
            key: const Key('details-panel'),
            width: Space.detailsWidth,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: AppLocalizations.of(context).close,
                    icon: const Icon(AppIcons.close),
                    onPressed: widget.details.close,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(Space.s16),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
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
                      child: Builder(
                        builder: (context) => SafeArea(
                          child: _sidebar(context, prefs, drawer: true),
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

/// Details open in a sheet on medium and compact widths (28.7).
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

  Future<void> _open() async {
    final content = widget.details.value;
    if (content == null || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(sheetContext),
        },
        child: Focus(
          autofocus: true,
          child: Padding(
            key: const Key('details-sheet'),
            padding: const EdgeInsets.fromLTRB(
              Space.s24,
              0,
              Space.s24,
              Space.s24,
            ),
            child: SingleChildScrollView(child: content),
          ),
        ),
      ),
    );
    widget.details.close();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
