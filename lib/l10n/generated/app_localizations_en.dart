// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cortex';

  @override
  String get landingTagline =>
      'A calm, monochrome place to think out loud, backed by the colour running wild behind it.';

  @override
  String get signInWithAsodya => 'Sign in with Asodya';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get guestModeNotice =>
      'Guest mode skips sign-in entirely: it is a local shortcut, not an Asodya account.';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get openSettings => 'Settings';

  @override
  String get sessionOptions => 'Session options';

  @override
  String get tierZeroLabel => 'Tier 0 - Free & Fast';

  @override
  String get messageHint => 'Message Cortex...';

  @override
  String lockedFeatureNotice(String tier) {
    return '$tier: this feature unlocks on a higher tier.';
  }

  @override
  String attachFileLocked(String tier) {
    return 'Attach file (locked on $tier)';
  }

  @override
  String webBrowsingLocked(String tier) {
    return 'Web browsing (locked on $tier)';
  }

  @override
  String get memoryRecallOnTooltip =>
      'Memory recall on: this reply will use cortex_api\'s native /execute with server-side memory recall';

  @override
  String get memoryRecallOffTooltip =>
      'Turn on memory recall (native /execute)';

  @override
  String get memoryRecallTitle => 'Memory recall';

  @override
  String get memoryRecallSubtitle =>
      'Uses cortex_api\'s native /execute with server-side memory recall, available on Tier 0';

  @override
  String get webBrowsingTitle => 'Web browsing';

  @override
  String get webBrowsingSubtitle => 'Locked on Tier 0';

  @override
  String get liveLogsTooltip => 'Live logs (local dev only)';

  @override
  String get liveLogsTitle => 'Cortex live logs';

  @override
  String get liveLogsDescription =>
      'Local dev only: connects directly to cortex_api\'s /logs/stream, this bypasses the api_for_apps proxy (it cannot carry a WebSocket).';

  @override
  String liveLogsConnectionError(String error) {
    return 'Could not connect: $error';
  }

  @override
  String get liveLogsWaiting => 'Waiting for log lines...';

  @override
  String couldNotSendMessage(String error) {
    return 'Could not send message: $error';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get languageThai => 'Thai';
}
