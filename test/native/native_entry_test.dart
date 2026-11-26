import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cortex/app.dart';
import 'package:cortex/dal/local/native_session_store.dart';
import 'package:cortex/dal/remote/auth_api_adapter.dart';
import 'package:cortex/domain/models/session_status.dart';
import 'package:cortex/domain/services/auth_service.dart';
import 'package:cortex/domain/services/session_controller.dart';
import 'package:cortex/domain/services/session_service.dart';
import 'package:cortex/l10n/generated/app_localizations.dart';
import 'package:cortex/presentation/frontend/screens/native_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};
  bool failOnCsrfWrite = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failOnCsrfWrite && key == 'cortex.native.csrf') {
      throw Exception('Simulated Keystore write failure on CSRF key');
    }
    if (value != null) {
      values[key] = value;
    } else {
      values.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.clear();
  }
}

class DeleteFailureStorage extends FakeSecureStorage {
  final deletes = <String>[];
  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deletes.add(key);
    if (key == 'cortex.native.sid') {
      throw StateError('synthetic SID delete failure');
    }
    values.remove(key);
  }
}

class ReadFailureStorage extends FakeSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw StateError('synthetic vault read failure');
}

class DeleteBothFailureStorage extends FakeSecureStorage {
  final deletes = <String>[];
  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    deletes.add(key);
    throw StateError('synthetic independent credential delete failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cortex #85 Android Release Manifest', () {
    test('Release AndroidManifest.xml includes INTERNET permission', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);
      final content = manifestFile.readAsStringSync();
      expect(
        content.contains(
          '<uses-permission android:name="android.permission.INTERNET"/>',
        ),
        isTrue,
        reason:
            'Main AndroidManifest must contain INTERNET permission for release builds',
      );
    });
  });

  group('Cortex #85 Native Session Store & Partial Failure Cleanup', () {
    test(
      'writeSession rejects empty or whitespace session_id and csrf_token',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);

        expect(
          () => store.writeSession(sid: '', csrf: 'valid-csrf'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => store.writeSession(sid: 'valid-sid', csrf: '   '),
          throwsA(isA<FormatException>()),
        );
        expect(fakeStorage.values.isEmpty, isTrue);
      },
    );

    test(
      'writeSession cleans up partial credentials if CSRF storage write fails',
      () async {
        final fakeStorage = FakeSecureStorage();
        fakeStorage.failOnCsrfWrite = true;
        final store = NativeSessionStore(storage: fakeStorage);

        await expectLater(
          () => store.writeSession(
            sid: 'test-session-id',
            csrf: 'test-csrf-token',
          ),
          throwsException,
        );

        // Verify session ID was NOT left in storage after failure:
        final sid = await store.readSessionId();
        final csrf = await store.readCsrfToken();
        expect(sid, isNull);
        expect(csrf, isNull);
        expect(fakeStorage.values.isEmpty, isTrue);
      },
    );

    test(
      'SessionService.currentStatus returns none if sid or csrf is missing or empty',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        final sessionService = SessionService(
          isNative: true,
          sessionStore: store,
        );

        expect(await sessionService.currentStatus(), SessionStatus.none);

        // Only sid present
        fakeStorage.values['cortex.native.sid'] = 'some-sid';
        expect(await sessionService.currentStatus(), SessionStatus.none);

        // Both present but csrf empty string
        fakeStorage.values['cortex.native.csrf'] = '  ';
        expect(await sessionService.currentStatus(), SessionStatus.none);

        // Both valid
        fakeStorage.values['cortex.native.csrf'] = 'valid-csrf';
        expect(
          await sessionService.currentStatus(),
          SessionStatus.authenticated,
        );
      },
    );

    test(
      'partial write cleanup attempts both keys and cannot authenticate mixed pair',
      () async {
        final vault = DeleteFailureStorage()
          ..values['cortex.native.csrf'] = 'synthetic-old-csrf'
          ..failOnCsrfWrite = true;
        final store = NativeSessionStore(storage: vault);
        await expectLater(
          store.writeSession(
            sid: 'synthetic-new-sid',
            csrf: 'synthetic-new-csrf',
          ),
          throwsException,
        );
        final status = await SessionService(
          isNative: true,
          sessionStore: store,
        ).currentStatus();
        expect(status, SessionStatus.none);
        expect(vault.deletes, contains('cortex.native.csrf'));
      },
    );

    test(
      'known pre-clear failure cannot be ignored before credential writes',
      () async {
        final vault = DeleteBothFailureStorage()
          ..values['cortex.native.csrf'] = 'synthetic-old-csrf'
          ..failOnCsrfWrite = true;
        final store = NativeSessionStore(storage: vault);
        await expectLater(
          store.writeSession(
            sid: 'synthetic-new-sid',
            csrf: 'synthetic-new-csrf',
          ),
          throwsException,
        );
        final status = await SessionService(
          isNative: true,
          sessionStore: store,
        ).currentStatus();
        expect(
          status,
          SessionStatus.none,
          reason:
              'known failed credential write must never authenticate a mixed generation pair',
        );
        expect(vault.values['cortex.native.sid'], isNull);
      },
    );
  });

  group('Cortex #85 Native Vault Read Failure Recovery', () {
    testWidgets(
      'vault read failure still permits a usable native login route',
      (tester) async {
        final store = NativeSessionStore(storage: ReadFailureStorage());
        final sessionService = SessionService(
          isNative: true,
          sessionStore: store,
        );
        final session = SessionController(service: sessionService);
        final auth = AuthService(
          AuthApiAdapter(
            sessionStore: store,
            httpClient: MockClient((_) async => http.Response('{}', 200)),
          ),
          session: sessionService,
        );
        await tester.pumpWidget(
          CortexApp(session: session, auth: auth, initialLocation: '/v1/entry'),
        );
        await tester.pump(const Duration(milliseconds: 100));
        final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(
          app.routerConfig,
          isNotNull,
          reason:
              'vault read failure must not leave permanent startup Skeleton',
        );
        expect(find.byType(NativeEntryPage), findsOneWidget);
      },
    );
  });

  group('Cortex #85 AuthApiAdapter Native Handoff & Timeouts', () {
    test('prepareNativeLogin generates valid match-code vector', () async {
      final fakeStorage = FakeSecureStorage();
      final store = NativeSessionStore(storage: fakeStorage);
      final adapter = AuthApiAdapter(sessionStore: store);

      final attempt = await adapter.prepareNativeLogin();
      expect(attempt.handoffId.length, greaterThan(20));
      expect(attempt.secret.length, greaterThan(20));
      expect(attempt.challenge.length, greaterThan(20));
      expect(attempt.matchCode.length, 4);
      // Match code must use Base32 alphabet:
      final base32Regex = RegExp(r'^[A-Z2-7]{4}$');
      expect(base32Regex.hasMatch(attempt.matchCode), isTrue);

      // Pending handoff should be stored:
      final rawPending = await store.readPendingHandoff();
      expect(rawPending, isNotNull);
      final decoded = jsonDecode(rawPending!) as Map<String, dynamic>;
      expect(decoded['handoff_id'], attempt.handoffId);
    });

    test(
      'finishNativeLogin rejects empty string session_id or csrf_token',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'h-123',
            'secret': 's-123',
            'challenge': 'c-123',
          }),
        );

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {'session_id': '   ', 'csrf_token': ''},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final adapter = AuthApiAdapter(
          httpClient: mockClient,
          sessionStore: store,
        );

        expect(
          () => adapter.finishNativeLogin(),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'INVALID_RESPONSE',
            ),
          ),
        );
        // Credentials must not be saved:
        expect(await store.readSessionId(), isNull);
      },
    );

    test(
      'bounded timeout triggers on slow network in native status/finish/cancel',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'h-123',
            'secret': 's-123',
            'challenge': 'c-123',
          }),
        );

        final hangingClient = MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('{}', 200);
        });

        final adapter = AuthApiAdapter(
          httpClient: hangingClient,
          sessionStore: store,
        );

        // Using an explicit short timeout for deterministic test execution:
        const shortTimeout = Duration(milliseconds: 20);

        expect(
          () => adapter.nativeHandoffStatus(timeout: shortTimeout),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'TIMEOUT',
            ),
          ),
        );

        expect(
          () => adapter.finishNativeLogin(timeout: shortTimeout),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'TIMEOUT',
            ),
          ),
        );

        expect(
          () => adapter.cancelNativeLogin(timeout: shortTimeout),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'TIMEOUT',
            ),
          ),
        );
      },
    );

    test(
      'cancelNativeLogin issues cancel payload and clears pending handoff',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'h-cancel',
            'secret': 's-cancel',
            'challenge': 'c-cancel',
          }),
        );

        bool cancelSent = false;
        final mockClient = MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          if (body['cancel'] == true && body['handoff_id'] == 'h-cancel') {
            cancelSent = true;
          }
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {'status': 'cancelled'},
            }),
            200,
          );
        });

        final adapter = AuthApiAdapter(
          httpClient: mockClient,
          sessionStore: store,
        );

        await adapter.cancelNativeLogin();
        expect(cancelSent, isTrue);
        expect(await store.readPendingHandoff(), isNull);
      },
    );

    test(
      'successful finishNativeLogin stores clean credentials and clears pending',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'h-ok',
            'secret': 's-ok',
            'challenge': 'c-ok',
          }),
        );

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'session_id': 'real-session-sid-12345',
                'csrf_token': 'real-csrf-token-67890',
                'location': {'city': 'Bangkok', 'country': 'TH'},
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final adapter = AuthApiAdapter(
          httpClient: mockClient,
          sessionStore: store,
        );

        final location = await adapter.finishNativeLogin();
        expect(location, contains('Bangkok'));
        expect(await store.readSessionId(), 'real-session-sid-12345');
        expect(await store.readCsrfToken(), 'real-csrf-token-67890');
        expect(await store.readPendingHandoff(), isNull);

        final session = SessionService(isNative: true, sessionStore: store);
        expect(await session.currentStatus(), SessionStatus.authenticated);
      },
    );
  });

  group('Cortex #85 NativeEntryPage Widget Interaction', () {
    testWidgets(
      'Displays welcome and sign-in button when no handoff is active',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        final adapter = AuthApiAdapter(sessionStore: store);
        final session = SessionService(isNative: true, sessionStore: store);
        final sessionCtrl = SessionController(service: session);
        final auth = AuthService(adapter, session: session);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeEntryPage(auth: auth, session: sessionCtrl),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.text('Sign in with your Asodya account'), findsOneWidget);
      },
    );

    testWidgets(
      'Timeout on status check leaves action buttons enabled for retry',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'h-slow',
            'secret': 's-slow',
            'challenge': 'c-slow',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          }),
        );

        final hangingClient = MockClient((request) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return http.Response('{}', 200);
        });

        final adapter = AuthApiAdapter(
          httpClient: hangingClient,
          sessionStore: store,
        );
        final session = SessionService(isNative: true, sessionStore: store);
        final sessionCtrl = SessionController(service: session);
        final auth = AuthService(adapter, session: session);

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeEntryPage(auth: auth, session: sessionCtrl),
          ),
        );
        await tester.pumpAndSettle();

        // Verify match code card is visible:
        expect(find.byType(Card), findsOneWidget);
        // Buttons for finish and cancel must be present and enabled:
        final finishBtn = tester.widget<FilledButton>(
          find.byType(FilledButton),
        );
        final cancelBtn = tester.widget<TextButton>(find.byType(TextButton));
        expect(finishBtn.onPressed, isNotNull);
        expect(cancelBtn.onPressed, isNotNull);
      },
    );
  });

  group('Cortex #85 30-Minute No-Record Expiry & Clock Control', () {
    test(
      'fresh attempt (<30m) preserves HANDOFF_NOT_FINISHED status',
      () async {
        final baseTime = DateTime.utc(2026, 11, 26, 12, 0, 0);
        var currentTime = baseTime;
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        final adapter = AuthApiAdapter(
          sessionStore: store,
          clock: () => currentTime,
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'data': {'code': 'HANDOFF_NOT_FINISHED'},
              }),
              400,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        await adapter.prepareNativeLogin();
        // Advance clock by 10 minutes (fresh):
        currentTime = baseTime.add(const Duration(minutes: 10));

        await expectLater(
          adapter.finishNativeLogin(),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'HANDOFF_NOT_FINISHED',
            ),
          ),
        );
      },
    );

    test('exact 30 minute boundary maps to HANDOFF_EXPIRED', () async {
      final baseTime = DateTime.utc(2026, 11, 26, 12, 0, 0);
      var currentTime = baseTime;
      final fakeStorage = FakeSecureStorage();
      final store = NativeSessionStore(storage: fakeStorage);
      final adapter = AuthApiAdapter(
        sessionStore: store,
        clock: () => currentTime,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'error',
              'data': {'code': 'HANDOFF_NOT_FINISHED'},
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await adapter.prepareNativeLogin();
      // Advance clock by exactly 30 minutes:
      currentTime = baseTime.add(const Duration(minutes: 30));

      await expectLater(
        adapter.finishNativeLogin(),
        throwsA(
          isA<NativeHandoffException>().having(
            (e) => e.code,
            'code',
            'HANDOFF_EXPIRED',
          ),
        ),
      );
    });

    test('expired attempt (>30m) maps to HANDOFF_EXPIRED', () async {
      final baseTime = DateTime.utc(2026, 11, 26, 12, 0, 0);
      var currentTime = baseTime;
      final fakeStorage = FakeSecureStorage();
      final store = NativeSessionStore(storage: fakeStorage);
      final adapter = AuthApiAdapter(
        sessionStore: store,
        clock: () => currentTime,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'error',
              'data': {'code': 'HANDOFF_NOT_FINISHED'},
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      await adapter.prepareNativeLogin();
      // Advance clock by 35 minutes:
      currentTime = baseTime.add(const Duration(minutes: 35));

      await expectLater(
        adapter.finishNativeLogin(),
        throwsA(
          isA<NativeHandoffException>().having(
            (e) => e.code,
            'code',
            'HANDOFF_EXPIRED',
          ),
        ),
      );
    });

    test('restored valid old attempt respects 30m boundary', () async {
      final baseTime = DateTime.utc(2026, 11, 26, 12, 0, 0);
      var currentTime = baseTime;
      final fakeStorage = FakeSecureStorage();
      final store = NativeSessionStore(storage: fakeStorage);
      final adapter = AuthApiAdapter(
        sessionStore: store,
        clock: () => currentTime,
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'status': 'error',
              'data': {'code': 'HANDOFF_NOT_FINISHED'},
            }),
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      );

      // Write pre-existing valid handoff timestamped at baseTime:
      await store.writePendingHandoff(
        jsonEncode({
          'handoff_id': 'valid-old-handoff',
          'secret': 'valid-old-secret',
          'challenge': 'Yw3NKWbEM2aRElRIu7JbT_QSpJxzLbLIq8G4WBvXEN0',
          'created_at': baseTime.toIso8601String(),
        }),
      );

      // 1. Restored when 15 minutes old:
      currentTime = baseTime.add(const Duration(minutes: 15));
      final freshRestored = await adapter.restoreNativeLogin();
      expect(freshRestored, isNotNull);
      expect(freshRestored!.matchCode, 'MMG4');
      await expectLater(
        adapter.finishNativeLogin(),
        throwsA(
          isA<NativeHandoffException>().having(
            (e) => e.code,
            'code',
            'HANDOFF_NOT_FINISHED',
          ),
        ),
      );

      // 2. Clock moves to 31 minutes old:
      currentTime = baseTime.add(const Duration(minutes: 31));
      await expectLater(
        adapter.finishNativeLogin(),
        throwsA(
          isA<NativeHandoffException>().having(
            (e) => e.code,
            'code',
            'HANDOFF_EXPIRED',
          ),
        ),
      );
    });

    test(
      'legacy or malformed timestamp is not assumed fresh and maps to HANDOFF_EXPIRED',
      () async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        final adapter = AuthApiAdapter(
          sessionStore: store,
          httpClient: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'status': 'error',
                'data': {'code': 'HANDOFF_NOT_FINISHED'},
              }),
              400,
              headers: {'content-type': 'application/json'},
            );
          }),
        );

        // Legacy payload with no created_at:
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'legacy-handoff',
            'secret': 'legacy-secret',
            'challenge': 'Yw3NKWbEM2aRElRIu7JbT_QSpJxzLbLIq8G4WBvXEN0',
          }),
        );

        final legacyRestored = await adapter.restoreNativeLogin();
        expect(legacyRestored, isNotNull);
        expect(legacyRestored!.matchCode, 'MMG4');

        await expectLater(
          adapter.finishNativeLogin(),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'HANDOFF_EXPIRED',
            ),
          ),
        );

        // Malformed timestamp:
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'malformed-handoff',
            'secret': 'malformed-secret',
            'challenge': 'Yw3NKWbEM2aRElRIu7JbT_QSpJxzLbLIq8G4WBvXEN0',
            'created_at': 'not-a-valid-date-string',
          }),
        );

        await expectLater(
          adapter.finishNativeLogin(),
          throwsA(
            isA<NativeHandoffException>().having(
              (e) => e.code,
              'code',
              'HANDOFF_EXPIRED',
            ),
          ),
        );
      },
    );

    test('restored handoff uses exact FINAL MMG4 match-code vector', () async {
      final fakeStorage = FakeSecureStorage();
      final store = NativeSessionStore(storage: fakeStorage);
      await store.writePendingHandoff(
        jsonEncode({
          'handoff_id': 'synthetic-handoff',
          'secret': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8',
          'challenge': 'Yw3NKWbEM2aRElRIu7JbT_QSpJxzLbLIq8G4WBvXEN0',
        }),
      );
      final attempt = await AuthApiAdapter(
        sessionStore: store,
      ).restoreNativeLogin();
      expect(attempt!.matchCode, 'MMG4');
    });

    testWidgets(
      'genuine hanging status times out at 15s and enables finish and cancel',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final store = NativeSessionStore(storage: fakeStorage);
        await store.writePendingHandoff(
          jsonEncode({
            'handoff_id': 'synthetic-handoff',
            'secret': 'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8',
            'challenge': 'Yw3NKWbEM2aRElRIu7JbT_QSpJxzLbLIq8G4WBvXEN0',
          }),
        );
        final client = MockClient((_) => Completer<http.Response>().future);
        final service = SessionService(isNative: true, sessionStore: store);
        final auth = AuthService(
          AuthApiAdapter(sessionStore: store, httpClient: client),
          session: service,
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NativeEntryPage(
              auth: auth,
              session: SessionController(service: service),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.pump(const Duration(seconds: 15));
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        expect(
          tester.widget<TextButton>(find.byType(TextButton)).onPressed,
          isNotNull,
        );
        expect(await store.readPendingHandoff(), isNotNull);
      },
    );
  });
}
