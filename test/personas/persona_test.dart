import 'dart:convert';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/dal/remote/cortex_api.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/router.dart';
import 'package:cortex/presentation/frontend/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> persona(
  String id,
  String name,
  String type, {
  bool self = false,
}) => {
  'persona_id': id,
  'name': name,
  'type': type,
  'aliases': ['Alias $name'],
  'is_self': self,
  'attributes': {'nickname': 'Saved value'},
};

class Api {
  int version = 1;
  int rejects = 0;
  int deleteFailures = 0;
  final requests = <(String, Uri, Map<String, dynamic>?)>[];
  final items = [
    persona('p1', 'Zeta', 'person', self: true),
    persona('p2', 'Alpha', 'bot'),
  ];
  List<Map<String, dynamic>> fields = [
    {
      'name': 'nickname',
      'type': 'string',
      'required': true,
      'in_context': true,
    },
    {
      'name': 'years',
      'type': 'integer',
      'required': false,
      'in_context': false,
    },
    {'name': 'score', 'type': 'float', 'required': false, 'in_context': true},
    {
      'name': 'enabled',
      'type': 'boolean',
      'required': false,
      'in_context': true,
    },
    {
      'name': 'birthday',
      'type': 'date',
      'required': false,
      'in_context': false,
    },
    {
      'name': 'interests',
      'type': 'array',
      'required': false,
      'in_context': true,
    },
    {'name': 'home', 'type': 'object', 'required': false, 'in_context': false},
    {
      'name': 'home.city',
      'type': 'string',
      'required': false,
      'in_context': false,
    },
    {'name': 'friends', 'type': 'array', 'required': false, 'in_context': true},
    {
      'name': 'friends[].name',
      'type': 'string',
      'required': true,
      'in_context': true,
    },
  ];
  late final client = MockClient((request) async {
    final path = request.url.path.replaceFirst('/apps/cortex/v1', '');
    final body = request.body.isEmpty
        ? null
        : (jsonDecode(request.body) as Map).cast<String, dynamic>();
    requests.add((request.method, request.url, body));
    http.Response reply(Object data, [int status = 200]) => http.Response(
      jsonEncode({'message': '', 'data': data}),
      status,
      headers: {'content-type': 'application/json'},
    );
    if (path == '/chats') return reply([]);
    if (path.startsWith('/personas/schemas/')) {
      return reply({
        'type': path.split('/').last,
        'version': version,
        'fields': fields,
      });
    }
    if (path == '/personas' && request.method == 'GET') return reply(items);
    if ((request.method == 'POST' || request.method == 'PATCH') &&
        path.startsWith('/personas')) {
      if (rejects > 0) {
        rejects--;
        return reply({
          'error_number': 1046,
          'errors': [
            {'field_path': 'nickname', 'message': 'Missing required field'},
          ],
        }, 400);
      }
      final id = request.method == 'POST' ? 'p-new' : path.split('/').last;
      final row = {
        'persona_id': id,
        'name': body!['name'],
        'type':
            body['type'] ??
            items.firstWhere((p) => p['persona_id'] == id)['type'],
        'aliases': body['aliases'],
        'is_self': body['is_self'],
        'attributes': body['attributes'],
      };
      items.removeWhere((p) => p['persona_id'] == id);
      items.add(row);
      return reply(row, request.method == 'POST' ? 201 : 200);
    }
    if (request.method == 'DELETE') {
      if (deleteFailures > 0) {
        deleteFailures--;
        return reply({'error_number': 1041}, 503);
      }
      items.removeWhere((p) => p['persona_id'] == path.split('/').last);
      return reply({});
    }
    final row = items
        .where((p) => p['persona_id'] == path.split('/').last)
        .firstOrNull;
    return row == null ? reply({'error_number': 1040}, 404) : reply(row);
  });
  CortexApi get cortex =>
      CortexApi(baseUrl: 'https://api.test/apps/cortex/v1', client: client);
}

class Auth extends AuthService {
  Auth() : super(AuthApiAdapter());
}

Future<GoRouter> pump(
  WidgetTester tester,
  Api api, {
  String path = '/v1/personas',
  Locale locale = const Locale('en'),
  double scale = 1,
  Size size = const Size(1200, 950),
  Brightness brightness = Brightness.dark,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final session = SessionController(
    service: SessionService(cookieReader: () => 'fixture-csrf'),
  );
  await session.refresh();
  final router = buildRouter(
    session: session,
    auth: Auth(),
    initialLocation: path,
    api: api.cortex,
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: locale,
      debugShowCheckedModeBanner: false,
      theme: cortexTheme(brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('save-persona')));
  await tester.tap(find.byKey(const Key('save-persona')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'invalid save retains typed identity and focuses the first wrong schema field',
    (tester) async {
      final api = Api()..rejects = 1;
      await pump(tester, api, path: '/v1/personas/new');
      await enter(tester, 'persona-name', 'Synthetic reader');
      await enter(tester, 'attribute-nickname', 'Typed value');
      await save(tester);
      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('attribute-nickname')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.focusNode!.hasFocus, isTrue);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('persona-name')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Synthetic reader',
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const Key('attribute-nickname')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Typed value',
      );
    },
  );
  testWidgets(
    'compact list has no overflow in Thai and Portuguese at 200 percent',
    (tester) async {
      for (final locale in [const Locale('th'), const Locale('pt', 'BR')]) {
        await pump(
          tester,
          Api(),
          locale: locale,
          scale: 2,
          size: const Size(390, 844),
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'list uses API order, aliases, self label, search and type filter',
    (tester) async {
      final api = Api();
      final router = await pump(tester, api);
      expect(
        tester.getTopLeft(find.byKey(const Key('persona-p1'))).dy,
        lessThan(tester.getTopLeft(find.byKey(const Key('persona-p2'))).dy),
      );
      expect(find.text('You'), findsOneWidget);
      expect(find.text('Alias Zeta'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Zeta');
      await tester.tap(find.byTooltip('Search personas'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('persona-filter')),
          matching: find.text('Bot'),
        ),
      );
      await tester.pumpAndSettle();
      final last = api.requests
          .where((r) => r.$2.path.endsWith('/personas'))
          .last;
      expect(last.$2.queryParameters, containsPair('q', 'Zeta'));
      expect(last.$2.queryParameters, containsPair('type', 'bot'));
      expect(
        find.byKey(const Key('persona-p1')),
        findsOneWidget,
      ); // No client-side filter.
      await tester.tap(find.byKey(const Key('persona-p1')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/v1/personas/p1');
    },
  );
  testWidgets('two published schema versions change the form', (tester) async {
    final api = Api();
    final router = await pump(tester, api, path: '/v1/personas/new');
    expect(find.byKey(const Key('attribute-nickname')), findsOneWidget);
    expect(find.byKey(const Key('attribute-years')), findsOneWidget);
    router.go('/v1/personas');
    await tester.pumpAndSettle();
    api.version = 2;
    api.fields = [
      {'name': 'tone', 'type': 'string', 'required': true, 'in_context': true},
    ];
    router.go('/v1/personas/new');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('attribute-nickname')), findsNothing);
    expect(find.byKey(const Key('attribute-tone')), findsOneWidget);
  });
  testWidgets(
    'API guardrail maps field errors and creation sends typed values',
    (tester) async {
      final api = Api()..rejects = 1;
      final router = await pump(tester, api, path: '/v1/personas/new');
      await save(tester);
      expect(
        api.requests.where((r) => r.$1 == 'POST').length,
        1,
      ); // No frontend validator blocks the API.
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('attribute-nickname')),
                matching: find.byType(TextField),
              ),
            )
            .decoration!
            .errorText,
        'This field is required.',
      );
      await enter(tester, 'persona-name', 'New persona');
      await enter(tester, 'attribute-nickname', 'Short name');
      await enter(tester, 'attribute-years', '12');
      await enter(tester, 'attribute-score', '1.5');
      await tester.ensureVisible(find.byKey(const Key('attribute-enabled')));
      await tester.tap(find.byKey(const Key('attribute-enabled')));
      await tester.pump();
      final aliases = find.descendant(
        of: find.byKey(const Key('persona-aliases')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(aliases);
      await tester.enterText(aliases, 'Nick');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('persona-aliases')),
          matching: find.byTooltip('Add item'),
        ),
      );
      await tester.pump();
      final interest = find.descendant(
        of: find.byKey(const Key('attribute-interests')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(interest);
      await tester.enterText(interest, 'Rust');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('attribute-interests')),
          matching: find.byTooltip('Add item'),
        ),
      );
      await tester.pump();
      await enter(tester, 'attribute-home.city', 'Bangkok');
      await save(tester);
      expect(
        router.routeInformationProvider.value.uri.path,
        '/v1/personas/p-new',
      );
      final body = api.requests.lastWhere((r) => r.$1 == 'POST').$3!;
      expect(body['type'], 'person');
      expect(body['aliases'], ['Nick']);
      expect(body['attributes']['years'], 12);
      expect(body['attributes']['score'], 1.5);
      expect(body['attributes']['enabled'], true);
      expect(body['attributes']['interests'], ['Rust']);
      expect(body['attributes']['home'], {'city': 'Bangkok'});
      expect(
        api.requests
            .where((r) => r.$2.path.contains('/personas'))
            .every((r) => r.$2.queryParameters['app_id'] == 'cortex'),
        isTrue,
      );
    },
  );
  testWidgets(
    'edit keeps saved attributes and delete requires confirmation and survives failure',
    (tester) async {
      final api = Api()..deleteFailures = 1;
      final router = await pump(tester, api, path: '/v1/personas/p1');
      await enter(tester, 'persona-name', 'Changed');
      await save(tester);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      final patch = api.requests.lastWhere((r) => r.$1 == 'PATCH').$3!;
      expect(patch.containsKey('type'), isFalse);
      expect(patch['attributes']['nickname'], 'Saved value');
      Future<void> remove() async {
        await tester.ensureVisible(find.byKey(const Key('delete-persona')));
        await tester.tap(find.byKey(const Key('delete-persona')));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await tester.pumpAndSettle();
      }

      await remove();
      expect(router.routeInformationProvider.value.uri.path, '/v1/personas/p1');
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('persona-name')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'Changed',
      );
      await remove();
      expect(router.routeInformationProvider.value.uri.path, '/v1/personas');
      expect(find.byKey(const Key('persona-p1')), findsNothing);
    },
  );
  testWidgets('date picker and object-list chips edit their declared values', (
    tester,
  ) async {
    final api = Api();
    await pump(tester, api, path: '/v1/personas/new');
    final date = find.byTooltip('Choose a date');
    await tester.ensureVisible(date);
    await tester.tap(date);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    final add = find.descendant(
      of: find.byKey(const Key('attribute-friends')),
      matching: find.text('Add item'),
    );
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await enter(tester, 'attribute-friends[].name', 'Ana');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add item'),
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(InputChip, 'name: Ana');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    await enter(tester, 'attribute-friends[].name', 'João');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Add item'),
      ),
    );
    await tester.pumpAndSettle();
    await save(tester);
    final attributes =
        api.requests.lastWhere((r) => r.$1 == 'POST').$3!['attributes'] as Map;
    expect(attributes['birthday'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    expect(attributes['friends'], [
      {'name': 'João'},
    ]);
  });
  testWidgets('static persona text and compact form work in EN, PT-BR and TH', (
    tester,
  ) async {
    for (final entry in [
      (const Locale('en'), 'Name *'),
      (const Locale('pt', 'BR'), 'Nome *'),
      (const Locale('th'), 'ชื่อ *'),
    ]) {
      await pump(
        tester,
        Api(),
        path: '/v1/personas/new',
        locale: entry.$1,
        scale: 2,
        size: const Size(390, 844),
      );
      expect(find.text(entry.$2), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
