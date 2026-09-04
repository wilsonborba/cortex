// Regression guard for computeAppProof (lib/core/utils/app_proof.dart).
//
// The expected hex digest below was computed independently in Python,
// mirroring api_for_apps' server-side algorithm exactly
// (`cortex_attestation_handler.py`, `_digest`):
//
//   import hmac, hashlib
//   secret = 'test-secret-value'
//   app_id = 'cortex_web_app'
//   date_utc = '2026-09-04'
//   message = f'{date_utc}:{app_id}'.encode('utf-8')
//   hmac.new(secret.encode('utf-8'), message, hashlib.sha256).hexdigest()
//   # => '41a4ddf1f891995b8e88add12ae3223265efe2f253e1748c26628a07b27e0efd'
//
// This is not just re-deriving the same value through computeAppProof
// itself: the expected string was hardcoded from that independent Python
// computation, so a change to the Dart HMAC scheme (wrong date format,
// wrong encoding, wrong message layout) will actually fail this test.

import 'package:cortex/core/utils/app_proof.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeAppProof', () {
    test('matches an independently computed HMAC-SHA256 hex digest', () {
      final proof = computeAppProof(
        date: DateTime.utc(2026, 9, 4),
        appId: 'cortex_web_app',
        secret: 'test-secret-value',
      );

      expect(
        proof,
        '41a4ddf1f891995b8e88add12ae3223265efe2f253e1748c26628a07b27e0efd',
      );
    });

    test('returns null when the secret is empty', () {
      final proof = computeAppProof(
        date: DateTime.utc(2026, 9, 4),
        appId: 'cortex_web_app',
        secret: '',
      );

      expect(proof, isNull);
    });

    test('formats single-digit months and days with zero padding', () {
      final proof = computeAppProof(
        date: DateTime.utc(2026, 1, 5),
        appId: 'cortex_web_app',
        secret: 'another-secret',
      );

      // Independently computed for date_utc '2026-01-05':
      //   hmac.new(b'another-secret', b'2026-01-05:cortex_web_app',
      //            hashlib.sha256).hexdigest()
      expect(
        proof,
        '570c61c40d69d46b9952f31a824c186c211fdcf670853d98fe81119f0bab060e',
      );
    });

    test('converts a non-UTC date to UTC before formatting', () {
      // A local time far enough from midnight UTC that the UTC calendar
      // date genuinely differs, to prove toUtc() is actually applied.
      final localLate = DateTime(2026, 9, 4, 23, 30).toLocal();
      final asUtc = localLate.toUtc();
      final expectedProof = computeAppProof(
        date: asUtc,
        appId: 'cortex_web_app',
        secret: 'test-secret-value',
      );

      final proof = computeAppProof(
        date: localLate,
        appId: 'cortex_web_app',
        secret: 'test-secret-value',
      );

      expect(proof, expectedProof);
    });
  });
}
