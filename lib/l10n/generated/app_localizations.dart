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

  /// No description provided for @landingTag.
  ///
  /// In en, this message translates to:
  /// **'AUTONOMOUS NEURAL WORKSPACE'**
  String get landingTag;

  /// No description provided for @landingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Intelligence without distraction.'**
  String get landingHeroTitle;

  /// No description provided for @landingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-throughput reasoning and persistent chat workspace. Built for deep focus with zero telemetry leakage.'**
  String get landingHeroSubtitle;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @ssoAuthHint.
  ///
  /// In en, this message translates to:
  /// **'[ Single Sign-On • Requires Account ]'**
  String get ssoAuthHint;

  /// No description provided for @aboutAsodya.
  ///
  /// In en, this message translates to:
  /// **'About Asodya'**
  String get aboutAsodya;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @footerWorkspace.
  ///
  /// In en, this message translates to:
  /// **'ASODYA CORTEX // TIER 0 WORKSPACE'**
  String get footerWorkspace;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2026 ASODYA. ALL RIGHTS RESERVED.'**
  String get allRightsReserved;

  /// No description provided for @card1Number.
  ///
  /// In en, this message translates to:
  /// **'01 / ARCHITECTURE'**
  String get card1Number;

  /// No description provided for @card1Title.
  ///
  /// In en, this message translates to:
  /// **'Neural Engine'**
  String get card1Title;

  /// No description provided for @card1Description.
  ///
  /// In en, this message translates to:
  /// **'Zero-latency contextual streaming backed by local Tier 0 inference and isolated execution parameters.'**
  String get card1Description;

  /// No description provided for @card2Number.
  ///
  /// In en, this message translates to:
  /// **'02 / INTEGRITY'**
  String get card2Number;

  /// No description provided for @card2Title.
  ///
  /// In en, this message translates to:
  /// **'Zero Telemetry Leak'**
  String get card2Title;

  /// No description provided for @card2Description.
  ///
  /// In en, this message translates to:
  /// **'System telemetry is isolated at the infrastructure boundary. User prompts and conversations remain private.'**
  String get card2Description;

  /// No description provided for @card3Number.
  ///
  /// In en, this message translates to:
  /// **'03 / CONTINUITY'**
  String get card3Number;

  /// No description provided for @card3Title.
  ///
  /// In en, this message translates to:
  /// **'Persistent Drafts'**
  String get card3Title;

  /// No description provided for @card3Description.
  ///
  /// In en, this message translates to:
  /// **'Local draft caching and resilient session recovery across devices through unified SSO token exchange.'**
  String get card3Description;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get history;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear All Conversations'**
  String get clearAllTitle;

  /// No description provided for @clearAllConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete all conversations? This action cannot be undone.'**
  String get clearAllConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @webResearchPill.
  ///
  /// In en, this message translates to:
  /// **'Web Research'**
  String get webResearchPill;

  /// No description provided for @memoryEnginePill.
  ///
  /// In en, this message translates to:
  /// **'Memory Engine'**
  String get memoryEnginePill;

  /// No description provided for @attachTooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach files or images'**
  String get attachTooltip;

  /// No description provided for @userBadgePro.
  ///
  /// In en, this message translates to:
  /// **'PRO // ASODYA AUTH'**
  String get userBadgePro;

  /// No description provided for @tier0Badge.
  ///
  /// In en, this message translates to:
  /// **'TIER 0 // CORTEX-T0'**
  String get tier0Badge;

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
  /// **'Message Cortex (Tier 0)...'**
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

  /// No description provided for @scrollToBottomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get scrollToBottomTooltip;

  /// No description provided for @codeBlockPlainLabel.
  ///
  /// In en, this message translates to:
  /// **'code'**
  String get codeBlockPlainLabel;

  /// No description provided for @codeBlockCopyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get codeBlockCopyLabel;

  /// No description provided for @codeBlockCopiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get codeBlockCopiedLabel;

  /// No description provided for @continueGenerationLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue generation'**
  String get continueGenerationLabel;

  /// No description provided for @continueGenerationTooltip.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped mid-reply. This retries the request from scratch (cortex_api cannot resume a partial reply) and replaces this message once a new answer comes in.'**
  String get continueGenerationTooltip;

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
