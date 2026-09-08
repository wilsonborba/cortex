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
  String get landingTag => 'EXPERIMENTAL NEURAL MVP';

  @override
  String get landingHeroTitle => 'Intelligence without distraction.';

  @override
  String get landingHeroSubtitle =>
      'An early-stage, experimental workspace for high-focus reasoning and persistent chat. Designed for deep thinking with strict privacy.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get ssoAuthHint => '[ Single Sign-On • Requires Account ]';

  @override
  String get aboutAsodya => 'About Asodya';

  @override
  String get logIn => 'Log in';

  @override
  String get signUp => 'Sign up';

  @override
  String get footerWorkspace => 'ASODYA CORTEX // EXPERIMENTAL MVP (TIER 0)';

  @override
  String get allRightsReserved => '© 2026 ASODYA. ALL RIGHTS RESERVED.';

  @override
  String get card1Number => '01 / ARCHITECTURE';

  @override
  String get card1Title => 'Neural Reasoning';

  @override
  String get card1Description =>
      'Real-time contextual token streaming powered by lightweight Tier 0 models and isolated execution parameters.';

  @override
  String get card2Number => '02 / INTEGRITY';

  @override
  String get card2Title => 'Privacy by Default';

  @override
  String get card2Description =>
      'System telemetry is strictly isolated at the infrastructure boundary. Your prompts and conversations remain private.';

  @override
  String get card3Number => '03 / CONTINUITY';

  @override
  String get card3Title => 'Persistent Drafts';

  @override
  String get card3Description =>
      'Local draft caching and resilient session recovery across devices through unified Asodya SSO token exchange.';

  @override
  String get newConversation => 'New Conversation';

  @override
  String get history => 'HISTORY';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearAllTitle => 'Clear All Conversations';

  @override
  String get clearAllConfirmation =>
      'Are you sure you want to permanently delete all conversations? This action cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get webResearchPill => 'Web Research';

  @override
  String get memoryEnginePill => 'Memory Engine';

  @override
  String get attachTooltip => 'Attach files or images';

  @override
  String get userBadgePro => 'PRO // ASODYA AUTH';

  @override
  String get tier0Badge => 'TIER 0 // CORTEX-T0';

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
  String get messageHint => 'Message Cortex (Tier 0)...';

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
  String get webBrowsingSubtitle =>
      'Grounds the reply with a web search, available on Tier 0';

  @override
  String get webSearchOnTooltip =>
      'Web search on: this reply will be grounded with a web search (needs_web)';

  @override
  String get webSearchOffTooltip => 'Turn on web search grounding (needs_web)';

  @override
  String sourcesCount(int count) {
    return 'Sources ($count)';
  }

  @override
  String get attachFile => 'Attach a file';

  @override
  String get attachImage => 'Image';

  @override
  String get attachDocument => 'Document';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get documentAttachmentBackendGap =>
      'Document ingestion is not supported by the backend yet: only images are accepted today.';

  @override
  String get voiceStartRecording => 'Record a voice message';

  @override
  String get voiceCancelRecording => 'Cancel recording';

  @override
  String get voiceSendRecording => 'Send voice message';

  @override
  String get micPermissionDenied =>
      'Microphone access is unavailable or was denied.';

  @override
  String get voiceMessageTooShort => 'Recording was too short to send.';

  @override
  String get incognitoModeTitle => 'Incognito chat';

  @override
  String get incognitoModeSubtitle =>
      'Ephemeral session: no history is saved and memory is explicitly off';

  @override
  String get newIncognitoChat => 'Start incognito chat';

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
  String get scrollToBottomTooltip => 'Scroll to bottom';

  @override
  String get codeBlockPlainLabel => 'code';

  @override
  String get codeBlockCopyLabel => 'Copy';

  @override
  String get codeBlockCopiedLabel => 'Copied!';

  @override
  String get continueGenerationLabel => 'Continue generation';

  @override
  String get continueGenerationTooltip =>
      'The connection dropped mid-reply. This retries the request from scratch (cortex_api cannot resume a partial reply) and replaces this message once a new answer comes in.';

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
