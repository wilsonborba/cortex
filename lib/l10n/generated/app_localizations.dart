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
  /// **'EXPERIMENTAL NEURAL MVP'**
  String get landingTag;

  /// No description provided for @landingHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Intelligence without distraction.'**
  String get landingHeroTitle;

  /// No description provided for @landingHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'An early-stage, experimental workspace for high-focus reasoning and persistent chat. Designed for deep thinking with strict privacy.'**
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
  /// **'ASODYA CORTEX // EXPERIMENTAL MVP (TIER 0)'**
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
  /// **'Neural Reasoning'**
  String get card1Title;

  /// No description provided for @card1Description.
  ///
  /// In en, this message translates to:
  /// **'Real-time contextual token streaming powered by lightweight Tier 0 models and isolated execution parameters.'**
  String get card1Description;

  /// No description provided for @card2Number.
  ///
  /// In en, this message translates to:
  /// **'02 / INTEGRITY'**
  String get card2Number;

  /// No description provided for @card2Title.
  ///
  /// In en, this message translates to:
  /// **'Privacy by Default'**
  String get card2Title;

  /// No description provided for @card2Description.
  ///
  /// In en, this message translates to:
  /// **'System telemetry is strictly isolated at the infrastructure boundary. Your prompts and conversations remain private.'**
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
  /// **'Local draft caching and resilient session recovery across devices through unified Asodya SSO token exchange.'**
  String get card3Description;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @noConversationsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYetTitle;

  /// No description provided for @noConversationsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation to begin chatting with Cortex.'**
  String get noConversationsYetBody;

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

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOutTitle;

  /// No description provided for @logOutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out of Cortex on this device and need to sign in again.'**
  String get logOutConfirmation;

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
  /// **'Supported files: images, audio, PDF, Word (.docx), and plain text/JSON/XML.'**
  String get documentAttachmentBackendGap;

  /// No description provided for @voiceStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Record a voice message'**
  String get voiceStartRecording;

  /// No description provided for @voiceFeatureNotReady.
  ///
  /// In en, this message translates to:
  /// **'Voice messages: not ready yet'**
  String get voiceFeatureNotReady;

  /// No description provided for @suggestionSystemTag.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM ANALYSIS'**
  String get suggestionSystemTag;

  /// No description provided for @suggestionSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Analyze system telemetry & bottlenecks'**
  String get suggestionSystemTitle;

  /// No description provided for @suggestionSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Identify latency bottlenecks and profile memory usage.'**
  String get suggestionSystemSubtitle;

  /// No description provided for @suggestionSystemPrompt.
  ///
  /// In en, this message translates to:
  /// **'Analyze current system metrics and identify memory/latency bottlenecks.'**
  String get suggestionSystemPrompt;

  /// No description provided for @suggestionArchitectureTag.
  ///
  /// In en, this message translates to:
  /// **'ARCHITECTURE'**
  String get suggestionArchitectureTag;

  /// No description provided for @suggestionArchitectureTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore distributed architecture tradeoffs'**
  String get suggestionArchitectureTitle;

  /// No description provided for @suggestionArchitectureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compare streaming facades against batch execution models.'**
  String get suggestionArchitectureSubtitle;

  /// No description provided for @suggestionArchitecturePrompt.
  ///
  /// In en, this message translates to:
  /// **'Explain the architectural tradeoffs between token streaming facades vs RPC execute.'**
  String get suggestionArchitecturePrompt;

  /// No description provided for @suggestionPipelineTag.
  ///
  /// In en, this message translates to:
  /// **'PIPELINE CODE'**
  String get suggestionPipelineTag;

  /// No description provided for @suggestionPipelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft an asynchronous API gateway'**
  String get suggestionPipelineTitle;

  /// No description provided for @suggestionPipelineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build a resilient service with streaming SSE & health guards.'**
  String get suggestionPipelineSubtitle;

  /// No description provided for @suggestionPipelinePrompt.
  ///
  /// In en, this message translates to:
  /// **'Write a Python FastAPI service connecting to an isolated AI gateway with health checks.'**
  String get suggestionPipelinePrompt;

  /// No description provided for @voiceCancelRecording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get voiceCancelRecording;

  /// No description provided for @voiceSendRecording.
  ///
  /// In en, this message translates to:
  /// **'Send voice message'**
  String get voiceSendRecording;

  /// No description provided for @micPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is unavailable or was denied.'**
  String get micPermissionDenied;

  /// No description provided for @voiceMessageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Recording was too short to send.'**
  String get voiceMessageTooShort;

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

  /// No description provided for @exportChatTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export chat as Markdown'**
  String get exportChatTooltip;

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

  /// No description provided for @improveInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Improve my input'**
  String get improveInputLabel;

  /// No description provided for @improveInputSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically rewrites and clarifies prompts with local reasoning model before generation'**
  String get improveInputSubtitle;

  /// No description provided for @incognitoBadge.
  ///
  /// In en, this message translates to:
  /// **'INCOGNITO'**
  String get incognitoBadge;

  /// No description provided for @startIncognito.
  ///
  /// In en, this message translates to:
  /// **'Start Incognito Chat'**
  String get startIncognito;

  /// No description provided for @exitIncognito.
  ///
  /// In en, this message translates to:
  /// **'Exit Incognito'**
  String get exitIncognito;

  /// No description provided for @memoryGraphTooltip.
  ///
  /// In en, this message translates to:
  /// **'Memory graph'**
  String get memoryGraphTooltip;

  /// No description provided for @memoryGraphTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory graph'**
  String get memoryGraphTitle;

  /// No description provided for @memoryGraphEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get memoryGraphEmptyTitle;

  /// No description provided for @memoryGraphEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Once Cortex remembers something, it will show up here as a graph.'**
  String get memoryGraphEmptyBody;

  /// No description provided for @memoryGraphTruncatedNotice.
  ///
  /// In en, this message translates to:
  /// **'This view does not show the full graph, some nodes were left out.'**
  String get memoryGraphTruncatedNotice;

  /// No description provided for @memoryGraphNoContextAvailable.
  ///
  /// In en, this message translates to:
  /// **'No context available for this node.'**
  String get memoryGraphNoContextAvailable;

  /// No description provided for @memoryGraphTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get memoryGraphTimeJustNow;

  /// No description provided for @memoryGraphTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String memoryGraphTimeMinutesAgo(int count);

  /// No description provided for @memoryGraphTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String memoryGraphTimeHoursAgo(int count);

  /// No description provided for @memoryGraphTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String memoryGraphTimeDaysAgo(int count);

  /// No description provided for @memoryGraphTypeMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryGraphTypeMemory;

  /// No description provided for @memoryGraphTypeAttachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get memoryGraphTypeAttachment;

  /// No description provided for @memoryGraphTypeTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get memoryGraphTypeTag;

  /// No description provided for @memoryGraphTypeEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get memoryGraphTypeEntity;

  /// No description provided for @memoryGraphTypeResource.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get memoryGraphTypeResource;

  /// No description provided for @memoryGraphTypeCluster.
  ///
  /// In en, this message translates to:
  /// **'Cluster'**
  String get memoryGraphTypeCluster;

  /// No description provided for @memoryGraphClusterCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String memoryGraphClusterCount(int count);

  /// No description provided for @memoryGraphClusterExpandedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shown'**
  String memoryGraphClusterExpandedCount(int count);

  /// No description provided for @memoryGraphResetPositionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset positions'**
  String get memoryGraphResetPositionsTooltip;
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
