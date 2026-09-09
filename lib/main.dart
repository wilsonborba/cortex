import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/logs.dart';
import 'core/settings.dart';
import 'domain/services/client_telemetry_service.dart';

void main() {
  // Path-based URLs (no `#/`) on web: required for `auth_apps` to be able to
  // redirect back to `<origin>/sync?auth_exchange_token=...` and have this
  // app actually receive that path.
  usePathUrlStrategy();
  ClientTelemetryService().initialize();
  // Printed to the browser console on every load, so which build is
  // actually running can be confirmed without digging into the settings
  // sheet (issue: no visible confirmation a deploy/restart took effect).
  AppLogger.info('Cortex build ${AppSettings.buildVersion} starting');
  runApp(const CortexApp());
}
