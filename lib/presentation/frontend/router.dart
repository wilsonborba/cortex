import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../dal/remote/cortex_api.dart';
import '../../domain/services/auth_service.dart';
import '../../domain/services/session_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import 'screens/basic_pages.dart';
import '../../domain/services/chat_list_controller.dart';
import '../../domain/services/memory_controller.dart';
import 'screens/chat/chat_list.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/memory/memory_screen.dart';
import 'shell/app_shell.dart';
import 'shell/details_panel.dart';
import 'screens/landing/landing_page.dart';

const homeSections = {'how-it-works', 'memory', 'engineering', 'faq'};
const _protected = ['/v1/chats', '/v1/memory', '/v1/personas', '/v1/usage'];
final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool isProtected(String path) =>
    _protected.any((p) => path == p || path.startsWith('$p/'));

/// Every screen has a path (28.1, 28.5). Screen content comes in #29 to #34.
GoRouter buildRouter({
  required SessionController session,
  required AuthService auth,
  DetailsController? details,
  Widget Function(BuildContext, String)? screen,
  String initialLocation = '/v1/home',
  CortexApi? api,
}) {
  final panel = details ?? DetailsController();
  final cortex = api ?? CortexApi();
  final chats = ChatListController(api: cortex);
  final memory = MemoryController(api: cortex);
  Widget screenPage(
    BuildContext c,
    String Function(AppLocalizations) title,
    Widget Function() build,
  ) => screen?.call(c, title(AppLocalizations.of(c))) ?? build();
  Widget page(BuildContext c, String Function(AppLocalizations) title) =>
      screen?.call(c, title(AppLocalizations.of(c))) ??
      ScreenFrame(
        title: title(AppLocalizations.of(c)),
        child: const SizedBox(),
      );
  Widget uuidPage(
    GoRouterState s,
    List<String> keys,
    Widget Function() build,
  ) => keys.every((k) => _uuid.hasMatch(s.pathParameters[k] ?? ''))
      ? build()
      : const NotFoundPage();
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: session,
    errorBuilder: (_, _) => const NotFoundPage(),
    redirect: (context, state) {
      final path = state.uri.path;
      if (isProtected(path) && !session.signedIn) {
        return Uri(
          path: '/v1/login',
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/v1/home'),
      GoRoute(
        path: '/sync',
        builder: (_, s) => SyncPage(auth: auth, session: session, uri: s.uri),
      ),
      GoRoute(
        path: '/v1/login',
        builder: (_, s) => LoginRedirectPage(
          auth: auth,
          from: s.uri.queryParameters['from'] ?? '/v1/chats',
        ),
      ),
      GoRoute(
        path: '/v1/home',
        builder: (_, _) =>
            LandingPage(onSignIn: () => auth.signIn(returnPath: '/v1/chats')),
      ),
      // Not nested: one landing page per section path.
      GoRoute(
        path: '/v1/home/:section',
        builder: (_, s) => homeSections.contains(s.pathParameters['section'])
            ? LandingPage(
                key: ValueKey(s.pathParameters['section']),
                onSignIn: () => auth.signIn(returnPath: '/v1/chats'),
                section: s.pathParameters['section'],
              )
            : const NotFoundPage(),
      ),
      ShellRoute(
        builder: (c, s, child) => AppShell(
          location: s.uri.path,
          details: panel,
          onLogOut: auth.signOut,
          // Test screens replace the content, so they get no live list.
          chatList: screen == null
              ? ChatList(controller: chats, location: s.uri.path)
              : null,
          child: child,
        ),
        routes: [
          // Flat routes: one chat screen per path, never a stacked new-chat page.
          GoRoute(
            path: '/v1/chats',
            builder: (c, _) => screenPage(
              c,
              (l) => l.chats,
              () => ChatScreen(
                key: const ValueKey('new'),
                api: cortex,
                details: panel,
              ),
            ),
          ),
          GoRoute(
            path: '/v1/chats/temporary',
            builder: (c, _) => screenPage(
              c,
              (l) => l.temporaryChat,
              () => ChatScreen(
                key: const ValueKey('temporary'),
                api: cortex,
                details: panel,
                temporary: true,
              ),
            ),
          ),
          GoRoute(
            path: '/v1/chats/:session_id',
            builder: (c, s) => uuidPage(
              s,
              ['session_id'],
              () => screenPage(
                c,
                (l) => l.chats,
                () => ChatScreen(
                  key: ValueKey(s.pathParameters['session_id']),
                  api: cortex,
                  details: panel,
                  sessionId: s.pathParameters['session_id'],
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/v1/chats/:session_id/outputs/:output_id',
            builder: (c, s) => uuidPage(
              s,
              ['session_id', 'output_id'],
              () => screenPage(
                c,
                (l) => l.output,
                () => ChatScreen(
                  key: ValueKey(s.pathParameters['session_id']),
                  api: cortex,
                  details: panel,
                  sessionId: s.pathParameters['session_id'],
                ),
              ),
            ),
          ),
          // Flat: one memory screen; the node path only opens its card.
          GoRoute(
            path: '/v1/memory',
            builder: (c, _) => screenPage(
              c,
              (l) => l.memory,
              () => MemoryScreen(controller: memory),
            ),
          ),
          GoRoute(
            path: '/v1/memory/:node_id',
            builder: (c, s) => screenPage(
              c,
              (l) => l.memory,
              () => MemoryScreen(
                controller: memory,
                nodeId: s.pathParameters['node_id'],
              ),
            ),
          ),
          GoRoute(
            path: '/v1/personas',
            builder: (c, _) => page(c, (l) => l.personas),
            routes: [
              GoRoute(
                path: 'new',
                builder: (c, _) => page(c, (l) => l.newPersona),
              ),
              GoRoute(
                path: ':persona_id',
                builder: (c, _) => page(c, (l) => l.personas),
              ),
            ],
          ),
          GoRoute(
            path: '/v1/usage',
            builder: (c, _) => page(c, (l) => l.usage),
            routes: [
              GoRoute(
                path: 'timing',
                builder: (c, _) => page(c, (l) => l.timing),
              ),
              GoRoute(
                path: 'stats',
                builder: (c, _) => page(c, (l) => l.stats),
              ),
              GoRoute(
                path: 'events',
                builder: (c, _) => page(c, (l) => l.events),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
