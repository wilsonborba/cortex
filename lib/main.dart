import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  // Path-based URLs (no `#/`) on web: required for `auth_apps` to be able to
  // redirect back to `<origin>/sync?auth_exchange_token=...` and have this
  // app actually receive that path.
  usePathUrlStrategy();
  runApp(const CortexApp());
}
