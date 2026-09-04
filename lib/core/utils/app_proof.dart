import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../settings.dart';

/// Header name api_for_apps' cortex proxy inspects for client-app
/// attestation (see `cortex_attestation_handler.py`, `CORTEX_PROOF_HEADER`
/// in api_for_apps, read-only reference).
const String appProofHeaderName = 'X-Asodya-App-Proof';

/// Computes the `X-Asodya-App-Proof` header value for [date], mirroring
/// api_for_apps' `compute_app_proof`/`_digest`
/// (`src/presentation/handler/cortex_attestation_handler.py`) exactly:
///
/// ```python
/// message = f"{date_utc}:{app_id}".encode("utf-8")
/// hmac.new(secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
/// ```
///
/// - `date_utc` is `date.toIso8601String()`'s date part in `YYYY-MM-DD`
///   form (matches Python's `datetime.strftime("%Y-%m-%d")` for a UTC
///   moment).
/// - The digest is hex-encoded (`hexdigest()`), not base64: the server
///   compares the raw hex string with `hmac.compare_digest`.
///
/// Returns `null` when [secret] is empty: callers must omit the header
/// entirely in that case rather than sending an empty/invalid value, so the
/// request simply falls back to api_for_apps' unproven-traffic quota.
String? computeAppProof({
  required DateTime date,
  String appId = AppSettings.cortexAppId,
  String secret = AppSettings.cortexProofSecret,
}) {
  if (secret.isEmpty) return null;

  final utcDate = date.toUtc();
  final dateUtc =
      '${utcDate.year.toString().padLeft(4, '0')}-'
      '${utcDate.month.toString().padLeft(2, '0')}-'
      '${utcDate.day.toString().padLeft(2, '0')}';

  final message = utf8.encode('$dateUtc:$appId');
  final hmac = Hmac(sha256, utf8.encode(secret));
  return hmac.convert(message).toString();
}
