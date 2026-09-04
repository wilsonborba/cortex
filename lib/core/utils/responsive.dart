import 'package:flutter/widgets.dart';

import '../settings.dart';

/// Breakpoint helpers shared by every screen that has to branch between the
/// desktop split-view and the mobile drawer layout.
class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppSettings.mobileBreakpoint;
  }

  static bool isDesktop(BuildContext context) => !isMobile(context);
}
