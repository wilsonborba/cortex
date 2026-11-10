import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/common/buttons.dart';
import '../widgets/common/states.dart';
import 'details_panel.dart';

class _Destination {
  const _Destination(this.path, this.icon, this.label);
  final String path;
  final IconData icon;
  final String Function(AppLocalizations) label;
}

final _destinations = [
  _Destination('/v1/chats', Icons.chat_bubble_outline, (l) => l.chats),
  _Destination('/v1/memory', Icons.hub_outlined, (l) => l.memory),
  _Destination('/v1/personas', Icons.person_outline, (l) => l.personas),
  _Destination('/v1/usage', Icons.insights_outlined, (l) => l.usage),
];

int _selected(String location) {
  final i = _destinations.indexWhere((d) => location.startsWith(d.path));
  return i < 0 ? 0 : i;
}

/// Signed-in shell by width (28.6 to 28.9).
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
    required this.details,
    required this.onLogOut,
    this.chatList,
  });
  final String location;
  final Widget child;
  final DetailsController details;
  final VoidCallback onLogOut;

  /// The chat list of the sidebar (#31 fills it).
  final Widget? chatList;

  @override
  Widget build(BuildContext context) {
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    return switch (size) {
      SizeClass.expanded => _Expanded(shell: this),
      SizeClass.medium => _Medium(shell: this),
      SizeClass.compact => _Compact(shell: this),
    };
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.shell});
  final AppShell shell;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final selected = _selected(shell.location);
    return Container(
      key: const Key('sidebar'),
      width: 280,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(right: BorderSide(color: p.border)),
      ),
      padding: const EdgeInsets.all(Space.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton.primary(
            label: l.newChat,
            icon: Icons.add,
            onPressed: () => context.go('/v1/chats'),
          ),
          const SizedBox(height: Space.s8),
          AppButton(
            label: l.temporaryChat,
            icon: Icons.visibility_off_outlined,
            onPressed: () => context.go('/v1/chats/temporary'),
          ),
          const SizedBox(height: Space.s16),
          Expanded(
            child:
                shell.chatList ??
                EmptyState(
                  title: l.noChatsYet,
                  icon: Icons.chat_bubble_outline,
                ),
          ),
          const Divider(),
          for (final (i, d) in _destinations.indexed.skip(1))
            ListTile(
              dense: true,
              leading: Icon(d.icon, color: i == selected ? p.accent : p.text),
              title: Text(d.label(l), style: TextStyles.compact),
              selected: i == selected,
              onTap: () => context.go(d.path),
            ),
          const Divider(),
          // Log out only here, at the bottom of the sidebar (28.9).
          ListTile(
            dense: true,
            leading: Icon(Icons.logout, color: p.text),
            title: Text(l.logOut, style: TextStyles.compact),
            onTap: shell.onLogOut,
          ),
        ],
      ),
    );
  }
}

class _Expanded extends StatelessWidget {
  const _Expanded({required this.shell});
  final AppShell shell;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(shell: shell),
          Expanded(child: shell.child),
          ValueListenableBuilder<Widget?>(
            valueListenable: shell.details,
            builder: (context, details, _) => details == null
                ? const SizedBox.shrink()
                : Container(
                    key: const Key('details-panel'),
                    width: 320,
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border(left: BorderSide(color: p.border)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ListTile(
                          title: Text(l.details, style: TextStyles.subsection),
                          trailing: IconButton(
                            tooltip: l.close,
                            icon: const Icon(Icons.close),
                            onPressed: shell.details.close,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(Space.s16),
                            child: details,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
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
      builder: (_) => Padding(
        key: const Key('details-sheet'),
        padding: const EdgeInsets.fromLTRB(Space.s24, 0, Space.s24, Space.s24),
        child: SingleChildScrollView(child: content),
      ),
    );
    widget.details.close();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Medium extends StatelessWidget {
  const _Medium({required this.shell});
  final AppShell shell;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: _DetailsSheet(
        details: shell.details,
        child: Row(
          children: [
            NavigationRail(
              key: const Key('rail'),
              selectedIndex: _selected(shell.location),
              labelType: NavigationRailLabelType.all,
              leading: IconButton.filled(
                tooltip: l.newChat,
                icon: const Icon(Icons.add),
                onPressed: () => context.go('/v1/chats'),
              ),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Space.s16),
                    child: IconButton(
                      tooltip: l.logOut,
                      icon: const Icon(Icons.logout),
                      onPressed: shell.onLogOut,
                    ),
                  ),
                ),
              ),
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label(l)),
                  ),
              ],
              onDestinationSelected: (i) => context.go(_destinations[i].path),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell.child),
          ],
        ),
      ),
    );
  }
}

class _Compact extends StatelessWidget {
  const _Compact({required this.shell});
  final AppShell shell;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: _DetailsSheet(
        details: shell.details,
        child: SafeArea(child: shell.child),
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('bottom-bar'),
        selectedIndex: _selected(shell.location),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label(l)),
        ],
        onDestinationSelected: (i) => context.go(_destinations[i].path),
      ),
    );
  }
}
