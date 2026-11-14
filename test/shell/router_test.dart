import 'package:cortex/presentation/frontend/theme/tokens.dart';
import 'package:cortex/core/utils/return_path.dart';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/shell/details_panel.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

bool signedIn = false;

class FakeAuth extends AuthService {
  FakeAuth() : super(AuthApiAdapter());
  final returns = <String?>[];
  @override
  Future<void> signIn({String? returnPath}) async {
    returns.add(returnPath);
    if (returnPath != null) saveReturnPath(returnPath);
  }

  @override
  Future<bool> consumeReturn(Uri uri) async {
    signedIn = uri.queryParameters['auth_exchange_token'] == 'good';
    return signedIn;
  }

  @override
  Future<void> signOut() async {}
}

const sid = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e0f';
const oid = '0190d3c6-1b2c-7a3d-8e4f-5a6b7c8d9e10';

Future<(GoRouter, FakeAuth, DetailsController)> pump(
  WidgetTester tester,
  String location, {
  Size size = const Size(1200, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    service: SessionService(cookieReader: () => signedIn ? 'csrf' : null),
  );
  await session.refresh();
  final auth = FakeAuth();
  final details = DetailsController();
  final router = buildRouter(
    session: session,
    auth: auth,
    details: details,
    initialLocation: location,
    emailLoader: () async => null,
    screen: (_, title) => Center(child: Text('screen: $title')),
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: cortexTheme(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
  return (router, auth, details);
}

String path(GoRouter r) => r.routerDelegate.currentConfiguration.uri.toString();

void main() {
  setUp(() => signedIn = true);

  testWidgets('every signed-in path opens its screen', (tester) async {
    final cases = {
      '/v1/chats': 'Chats',
      '/v1/chats/temporary': 'Temporary chat',
      '/v1/chats/$sid': 'Chats',
      '/v1/chats/$sid/outputs/$oid': 'Output',
      '/v1/memory': 'Memory',
      '/v1/memory/tag:t1': 'Memory',
      '/v1/personas': 'Personas',
      '/v1/personas/new': 'New persona',
      '/v1/personas/p-1': 'Personas',
      '/v1/usage': 'Usage',
      '/v1/usage/timing': 'Timing',
      '/v1/usage/stats': 'Statistics',
      '/v1/usage/events': 'Events',
    };
    for (final MapEntry(key: location, value: title) in cases.entries) {
      final (router, _, _) = await pump(tester, location);
      expect(find.text('screen: $title'), findsOneWidget, reason: location);
      expect(path(router), location);
    }
  });

  testWidgets('home paths, the root redirect and unknown paths', (
    tester,
  ) async {
    var (router, _, _) = await pump(tester, '/');
    expect(path(router), '/v1/home');
    for (final section in homeSections) {
      (router, _, _) = await pump(tester, '/v1/home/$section');
      expect(find.text('Page not found'), findsNothing, reason: section);
    }
    for (final bad in [
      '/v1/nothing',
      '/v1/home/other',
      '/v1/chats/not-a-uuid',
      '/v1/chats/$sid/outputs/x',
    ]) {
      await pump(tester, bad);
      expect(find.text('Page not found'), findsOneWidget, reason: bad);
      expect(find.text('Go to chats'), findsOneWidget);
    }
  });

  testWidgets('a signed-out visitor logs in and returns to the same path', (
    tester,
  ) async {
    signedIn = false;
    var (router, auth, _) = await pump(tester, '/v1/memory/tag:t1?view=list');
    expect(auth.returns, ['/v1/memory/tag:t1?view=list']);
    expect(find.text('Opening the login'), findsOneWidget);
    // The SSO comes back to /sync with the token; the token then leaves the URL.
    (router, auth, _) = await pump(tester, '/sync?auth_exchange_token=good');
    expect(path(router), '/v1/memory/tag:t1?view=list');
    expect(path(router), isNot(contains('auth_exchange_token')));
    expect(find.text('screen: Memory'), findsOneWidget);
  });

  testWidgets(
    'expanded: 260 px sidebar, one primary, log out at the bottom, 320 px details',
    (tester) async {
      final (_, _, details) = await pump(tester, '/v1/chats');
      expect(
        tester.getSize(find.byKey(const Key('sidebar'))).width,
        Space.sidebarWidth,
      );
      expect(find.text('New chat'), findsOneWidget);
      expect(find.text('Log out'), findsNothing);
      expect(find.byKey(const Key('account-button')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('account-button'))).dy,
        greaterThan(tester.getTopLeft(find.text('Usage')).dy),
      );
      details.show(const Text('step detail'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(const Key('details-panel'))).width, 320);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('details-panel')), findsNothing);
    },
  );

  testWidgets('medium: icon rail and details in a sheet', (tester) async {
    final (_, _, details) = await pump(
      tester,
      '/v1/usage',
      size: const Size(800, 800),
    );
    expect(find.byKey(const Key('rail')), findsOneWidget);
    expect(find.byKey(const Key('sidebar')), findsNothing);
    details.show(const Text('source detail'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('details-sheet')), findsOneWidget);
  });

  testWidgets('compact: drawer navigation and account footer', (tester) async {
    final (router, _, _) = await pump(
      tester,
      '/v1/chats',
      size: const Size(400, 800),
    );
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byKey(const Key('drawer-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-button')), findsOneWidget);
    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();
    expect(path(router), '/v1/personas');
  });
}
