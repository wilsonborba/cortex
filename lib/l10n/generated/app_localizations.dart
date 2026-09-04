import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('th'),
  ];

  /// Brand name, kept the same across all languages.
  ///
  /// In en, this message translates to:
  /// **'Cortex'**
  String get appTitle;

  /// No description provided for @landingTagline.
  ///
  /// In en, this message translates to:
  /// **'A calm, monochrome place to think out loud, backed by the colour running wild behind it.'**
  String get landingTagline;

  /// No description provided for @signInWithAsodya.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Asodya'**
  String get signInWithAsodya;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @guestModeNotice.
  ///
  /// In en, this message translates to:
  /// **'Guest mode skips sign-in entirely: it is a local shortcut, not an Asodya account.'**
  String get guestModeNotice;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @sessionOptions.
  ///
  /// In en, this message translates to:
  /// **'Session options'**
  String get sessionOptions;

  /// No description provided for @tierZeroLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier 0 - Free & Fast'**
  String get tierZeroLabel;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message Cortex...'**
  String get messageHint;

  /// No description provided for @lockedFeatureNotice.
  ///
  /// In en, this message translates to:
  /// **'{tier}: this feature unlocks on a higher tier.'**
  String lockedFeatureNotice(String tier);

  /// No description provided for @attachFileLocked.
  ///
  /// In en, this message translates to:
  /// **'Attach file (locked on {tier})'**
  String attachFileLocked(String tier);

  /// No description provided for @webBrowsingLocked.
  ///
  /// In en, this message translates to:
  /// **'Web browsing (locked on {tier})'**
  String webBrowsingLocked(String tier);

  /// No description provided for @memoryRecallOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Memory recall on: this reply will use cortex_api\'s native /execute with server-side memory recall'**
  String get memoryRecallOnTooltip;

  /// No description provided for @memoryRecallOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn on memory recall (native /execute)'**
  String get memoryRecallOffTooltip;

  /// No description provided for @memoryRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory recall'**
  String get memoryRecallTitle;

  /// No description provided for @memoryRecallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses cortex_api\'s native /execute with server-side memory recall, available on Tier 0'**
  String get memoryRecallSubtitle;

  /// No description provided for @webBrowsingTitle.
  ///
  /// In en, this message translates to:
  /// **'Web browsing'**
  String get webBrowsingTitle;

  /// No description provided for @webBrowsingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Grounds the reply with a web search, available on Tier 0'**
  String get webBrowsingSubtitle;

  /// No description provided for @webSearchOnTooltip.
  ///
  /// In en, this message translates to:
  /// **'Web search on: this reply will be grounded with a web search (needs_web)'**
  String get webSearchOnTooltip;

  /// No description provided for @webSearchOffTooltip.
  ///
  /// In en, this message translates to:
  /// **'Turn on web search grounding (needs_web)'**
  String get webSearchOffTooltip;

  /// No description provided for @sourcesCount.
  ///
  /// In en, this message translates to:
  /// **'Sources ({count})'**
  String sourcesCount(int count);

  /// No description provided for @attachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach a file'**
  String get attachFile;

  /// No description provided for @attachImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get attachImage;

  /// No description provided for @attachDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get attachDocument;

  /// No description provided for @removeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// No description provided for @documentAttachmentBackendGap.
  ///
  /// In en, this message translates to:
  /// **'Document ingestion is not supported by the backend yet: only images are accepted today.'**
  String get documentAttachmentBackendGap;

  /// No description provided for @voiceStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Start voice recording'**
  String get voiceStartRecording;

  /// No description provided for @voiceStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording and insert transcript'**
  String get voiceStopRecording;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is unavailable or was denied.'**
  String get micPermissionDenied;

  /// No description provided for @incognitoModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Incognito chat'**
  String get incognitoModeTitle;

  /// No description provided for @incognitoModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral session: no history is saved and memory is explicitly off'**
  String get incognitoModeSubtitle;

  /// No description provided for @newIncognitoChat.
  ///
  /// In en, this message translates to:
  /// **'Start incognito chat'**
  String get newIncognitoChat;

  /// No description provided for @liveLogsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Live logs (local dev only)'**
  String get liveLogsTooltip;

  /// No description provided for @liveLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cortex live logs'**
  String get liveLogsTitle;

  /// No description provided for @liveLogsDescription.
  ///
  /// In en, this message translates to:
  /// **'Local dev only: connects directly to cortex_api\'s /logs/stream, this bypasses the api_for_apps proxy (it cannot carry a WebSocket).'**
  String get liveLogsDescription;

  /// No description provided for @liveLogsConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {error}'**
  String liveLogsConnectionError(String error);

  /// No description provided for @liveLogsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for log lines...'**
  String get liveLogsWaiting;

  /// No description provided for @couldNotSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not send message: {error}'**
  String couldNotSendMessage(String error);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @languageThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get languageThai;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
