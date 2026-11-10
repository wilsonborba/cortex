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

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChat;

  /// No description provided for @temporaryChat.
  ///
  /// In en, this message translates to:
  /// **'Temporary chat'**
  String get temporaryChat;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memory;

  /// No description provided for @personas.
  ///
  /// In en, this message translates to:
  /// **'Personas'**
  String get personas;

  /// No description provided for @usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usage;

  /// No description provided for @timing.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timing;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get stats;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @newPersona.
  ///
  /// In en, this message translates to:
  /// **'New persona'**
  String get newPersona;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @notFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get notFoundTitle;

  /// No description provided for @notFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This path or item does not exist.'**
  String get notFoundMessage;

  /// No description provided for @goToChats.
  ///
  /// In en, this message translates to:
  /// **'Go to chats'**
  String get goToChats;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Opening the login'**
  String get signingIn;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChatsYet;

  /// No description provided for @output.
  ///
  /// In en, this message translates to:
  /// **'Output'**
  String get output;

  /// No description provided for @product.
  ///
  /// In en, this message translates to:
  /// **'Product'**
  String get product;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @engineering.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get engineering;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeSwitch.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeSwitch;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @heroLabel.
  ///
  /// In en, this message translates to:
  /// **'AI chat workspace'**
  String get heroLabel;

  /// No description provided for @heroTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat with your memory, files and the web'**
  String get heroTitle;

  /// No description provided for @heroLead.
  ///
  /// In en, this message translates to:
  /// **'Cortex answers with a local model and shows each step: memory, files, web sources and thinking.'**
  String get heroLead;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start a chat'**
  String get startChat;

  /// No description provided for @seeHow.
  ///
  /// In en, this message translates to:
  /// **'See how it works'**
  String get seeHow;

  /// No description provided for @example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// No description provided for @demoMemoryPrompt.
  ///
  /// In en, this message translates to:
  /// **'What did I decide about the usage balancer?'**
  String get demoMemoryPrompt;

  /// No description provided for @demoFastPrompt.
  ///
  /// In en, this message translates to:
  /// **'What is the latest stable Rust version?'**
  String get demoFastPrompt;

  /// No description provided for @demoDeepPrompt.
  ///
  /// In en, this message translates to:
  /// **'Compare SQLite and PostgreSQL for a small web app.'**
  String get demoDeepPrompt;

  /// No description provided for @demoThinkPrompt.
  ///
  /// In en, this message translates to:
  /// **'A train leaves at 09:40 and arrives at 13:05. How many minutes?'**
  String get demoThinkPrompt;

  /// No description provided for @demoMemoryAnswer.
  ///
  /// In en, this message translates to:
  /// **'You decided on a fair share per user over 24 hours, with a base weight of 1 for new users.'**
  String get demoMemoryAnswer;

  /// No description provided for @demoFastAnswer.
  ///
  /// In en, this message translates to:
  /// **'The answer comes from the pages read now, and each source is listed below the answer.'**
  String get demoFastAnswer;

  /// No description provided for @demoDeepAnswer.
  ///
  /// In en, this message translates to:
  /// **'For one small app with few writers, SQLite is simpler; for many writers at the same time, PostgreSQL is safer.'**
  String get demoDeepAnswer;

  /// No description provided for @demoThinkAnswer.
  ///
  /// In en, this message translates to:
  /// **'The trip takes 205 minutes.'**
  String get demoThinkAnswer;

  /// No description provided for @demoReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get demoReplay;

  /// No description provided for @stepSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security check OK'**
  String get stepSecurity;

  /// No description provided for @stepMemorySearch.
  ///
  /// In en, this message translates to:
  /// **'Searching your memory'**
  String get stepMemorySearch;

  /// No description provided for @stepMemoriesFound.
  ///
  /// In en, this message translates to:
  /// **'Memories found'**
  String get stepMemoriesFound;

  /// No description provided for @stepQueries.
  ///
  /// In en, this message translates to:
  /// **'Preparing search queries'**
  String get stepQueries;

  /// No description provided for @stepWebSearch.
  ///
  /// In en, this message translates to:
  /// **'Searching the web'**
  String get stepWebSearch;

  /// No description provided for @stepPageRead.
  ///
  /// In en, this message translates to:
  /// **'Reading the web page'**
  String get stepPageRead;

  /// No description provided for @stepThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking step'**
  String get stepThinking;

  /// No description provided for @stepAnswer.
  ///
  /// In en, this message translates to:
  /// **'Writing the answer'**
  String get stepAnswer;

  /// No description provided for @sources.
  ///
  /// In en, this message translates to:
  /// **'Sources'**
  String get sources;

  /// No description provided for @whatTitle.
  ///
  /// In en, this message translates to:
  /// **'What it does'**
  String get whatTitle;

  /// No description provided for @whatMemory.
  ///
  /// In en, this message translates to:
  /// **'Chat with memory'**
  String get whatMemory;

  /// No description provided for @whatMemoryText.
  ///
  /// In en, this message translates to:
  /// **'Cortex finds up to 5 of your memories that match the question and shows which ones it used.'**
  String get whatMemoryText;

  /// No description provided for @whatWeb.
  ///
  /// In en, this message translates to:
  /// **'Web research'**
  String get whatWeb;

  /// No description provided for @whatWebText.
  ///
  /// In en, this message translates to:
  /// **'Fast, medium or deep: more queries and more pages for harder questions, with every source shown.'**
  String get whatWebText;

  /// No description provided for @whatFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get whatFiles;

  /// No description provided for @whatFilesText.
  ///
  /// In en, this message translates to:
  /// **'PDF (with OCR for scanned pages), DOCX with tables, audio up to 10 minutes and images.'**
  String get whatFilesText;

  /// No description provided for @whatThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get whatThinking;

  /// No description provided for @whatThinkingText.
  ///
  /// In en, this message translates to:
  /// **'Plan, work and check steps before the final answer, at most 2 rounds, and you can stop thinking at any time.'**
  String get whatThinkingText;

  /// No description provided for @pipelineTitle.
  ///
  /// In en, this message translates to:
  /// **'How one request works'**
  String get pipelineTitle;

  /// No description provided for @stageAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get stageAccept;

  /// No description provided for @stageGather.
  ///
  /// In en, this message translates to:
  /// **'Gather'**
  String get stageGather;

  /// No description provided for @stageAssemble.
  ///
  /// In en, this message translates to:
  /// **'Assemble'**
  String get stageAssemble;

  /// No description provided for @stageThink.
  ///
  /// In en, this message translates to:
  /// **'Think'**
  String get stageThink;

  /// No description provided for @stageAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get stageAnswer;

  /// No description provided for @stageSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get stageSave;

  /// No description provided for @stageAcceptText.
  ///
  /// In en, this message translates to:
  /// **'Size and token checks, then the security check.'**
  String get stageAcceptText;

  /// No description provided for @stageGatherText.
  ///
  /// In en, this message translates to:
  /// **'Files, memory and web at the same time.'**
  String get stageGatherText;

  /// No description provided for @stageAssembleText.
  ///
  /// In en, this message translates to:
  /// **'Fills the 8192-token context in a fixed order.'**
  String get stageAssembleText;

  /// No description provided for @stageThinkText.
  ///
  /// In en, this message translates to:
  /// **'Optional plan, work and check.'**
  String get stageThinkText;

  /// No description provided for @stageAnswerText.
  ///
  /// In en, this message translates to:
  /// **'One model call, streamed token by token.'**
  String get stageAnswerText;

  /// No description provided for @stageSaveText.
  ///
  /// In en, this message translates to:
  /// **'History, memory, usage and the run record.'**
  String get stageSaveText;

  /// No description provided for @pipelineDescription.
  ///
  /// In en, this message translates to:
  /// **'Diagram of the six stages of one request: Accept, Gather with files, memory and web in parallel, Assemble, Think, Answer and Save.'**
  String get pipelineDescription;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @memoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory with Hippocampus'**
  String get memoryTitle;

  /// No description provided for @memoryScope.
  ///
  /// In en, this message translates to:
  /// **'Every memory has a scope: workspace, app and user. A search never leaves the scope.'**
  String get memoryScope;

  /// No description provided for @memorySearch.
  ///
  /// In en, this message translates to:
  /// **'Word search and semantic search are merged with Reciprocal Rank Fusion (RRF).'**
  String get memorySearch;

  /// No description provided for @memoryPersonas.
  ///
  /// In en, this message translates to:
  /// **'Personas: the person you are, a bot voice for a chat, and people you name in a question.'**
  String get memoryPersonas;

  /// No description provided for @memoryRepo.
  ///
  /// In en, this message translates to:
  /// **'Hippocampus repository'**
  String get memoryRepo;

  /// No description provided for @scopeDescription.
  ///
  /// In en, this message translates to:
  /// **'Tree of a memory scope: a workspace holds apps, and an app holds users.'**
  String get scopeDescription;

  /// No description provided for @graphDescription.
  ///
  /// In en, this message translates to:
  /// **'Example memory graph: memories linked to tags, entities and files.'**
  String get graphDescription;

  /// No description provided for @webTitle.
  ///
  /// In en, this message translates to:
  /// **'Web research'**
  String get webTitle;

  /// No description provided for @webMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get webMode;

  /// No description provided for @webQueries.
  ///
  /// In en, this message translates to:
  /// **'Queries'**
  String get webQueries;

  /// No description provided for @webPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get webPages;

  /// No description provided for @webDepth.
  ///
  /// In en, this message translates to:
  /// **'Link depth'**
  String get webDepth;

  /// No description provided for @webTime.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get webTime;

  /// No description provided for @webFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get webFast;

  /// No description provided for @webMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get webMedium;

  /// No description provided for @webDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get webDeep;

  /// No description provided for @webFastPages.
  ///
  /// In en, this message translates to:
  /// **'5'**
  String get webFastPages;

  /// No description provided for @webMediumPages.
  ///
  /// In en, this message translates to:
  /// **'5 per level'**
  String get webMediumPages;

  /// No description provided for @webMethod.
  ///
  /// In en, this message translates to:
  /// **'Pages are cut into chunks of about 500 tokens and ranked with BM25 and RRF. Web text uses no embeddings, and sources stay apart from your memory.'**
  String get webMethod;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String seconds(int n);

  /// No description provided for @liveTitle.
  ///
  /// In en, this message translates to:
  /// **'Live control'**
  String get liveTitle;

  /// No description provided for @liveSteps.
  ///
  /// In en, this message translates to:
  /// **'Live steps: every stage and step is streamed as it happens.'**
  String get liveSteps;

  /// No description provided for @liveReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect: the answer keeps running on the server, and you can come back to it.'**
  String get liveReconnect;

  /// No description provided for @liveStop.
  ///
  /// In en, this message translates to:
  /// **'Stop: you can stop an answer at any time.'**
  String get liveStop;

  /// No description provided for @liveStopThinking.
  ///
  /// In en, this message translates to:
  /// **'Stop thinking: go to the final answer with the notes so far.'**
  String get liveStopThinking;

  /// No description provided for @engTitle.
  ///
  /// In en, this message translates to:
  /// **'Engineering'**
  String get engTitle;

  /// No description provided for @engMachines.
  ///
  /// In en, this message translates to:
  /// **'Local machines on one network: the MSI GPU runs the language model, Pong runs embeddings, FSM keeps the files, and a database server keeps the data.'**
  String get engMachines;

  /// No description provided for @engRust.
  ///
  /// In en, this message translates to:
  /// **'The Cortex and Hippocampus APIs are written in Rust.'**
  String get engRust;

  /// No description provided for @engLocal.
  ///
  /// In en, this message translates to:
  /// **'Local models only. No cloud language model.'**
  String get engLocal;

  /// No description provided for @machinesDescription.
  ///
  /// In en, this message translates to:
  /// **'Diagram of the machines: the Cortex API sends model calls to the MSI GPU, memory calls to Hippocampus, which uses Pong for embeddings, FSM for files and the database server.'**
  String get machinesDescription;

  /// No description provided for @codeTitle.
  ///
  /// In en, this message translates to:
  /// **'Real code'**
  String get codeTitle;

  /// No description provided for @codeRrf.
  ///
  /// In en, this message translates to:
  /// **'Reciprocal Rank Fusion of web search lists'**
  String get codeRrf;

  /// No description provided for @codeGather.
  ///
  /// In en, this message translates to:
  /// **'Files, memory and web gathered at the same time'**
  String get codeGather;

  /// No description provided for @codeNames.
  ///
  /// In en, this message translates to:
  /// **'Tag search inside one scope'**
  String get codeNames;

  /// No description provided for @researchTitle.
  ///
  /// In en, this message translates to:
  /// **'Research basis'**
  String get researchTitle;

  /// No description provided for @securityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security and privacy'**
  String get securityTitle;

  /// No description provided for @securityShield.
  ///
  /// In en, this message translates to:
  /// **'Every input passes a security check with fixed rules and a classifier before anything is saved.'**
  String get securityShield;

  /// No description provided for @securityIsolation.
  ///
  /// In en, this message translates to:
  /// **'Each user sees only their own chats, files and memories, inside each app.'**
  String get securityIsolation;

  /// No description provided for @securityLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs and run records hold no chat text.'**
  String get securityLogs;

  /// No description provided for @faqLoginQ.
  ///
  /// In en, this message translates to:
  /// **'Do I need an account?'**
  String get faqLoginQ;

  /// No description provided for @faqLoginA.
  ///
  /// In en, this message translates to:
  /// **'Yes. You log in with your Asodya account before the first chat.'**
  String get faqLoginA;

  /// No description provided for @faqModelQ.
  ///
  /// In en, this message translates to:
  /// **'Which model answers?'**
  String get faqModelQ;

  /// No description provided for @faqModelA.
  ///
  /// In en, this message translates to:
  /// **'A local text model, and a local vision model when you send an image.'**
  String get faqModelA;

  /// No description provided for @faqDataQ.
  ///
  /// In en, this message translates to:
  /// **'Where does my data live?'**
  String get faqDataQ;

  /// No description provided for @faqDataA.
  ///
  /// In en, this message translates to:
  /// **'On Asodya machines: chats in the database, memories in Hippocampus and files in FSM.'**
  String get faqDataA;

  /// No description provided for @faqTempQ.
  ///
  /// In en, this message translates to:
  /// **'What is a temporary chat?'**
  String get faqTempQ;

  /// No description provided for @faqTempA.
  ///
  /// In en, this message translates to:
  /// **'A chat that is not saved: it ends after one hour or when you close it, and it creates no memory.'**
  String get faqTempA;

  /// No description provided for @faqLangQ.
  ///
  /// In en, this message translates to:
  /// **'Which languages?'**
  String get faqLangQ;

  /// No description provided for @faqLangA.
  ///
  /// In en, this message translates to:
  /// **'The app is in English, Portuguese and Thai.'**
  String get faqLangA;

  /// No description provided for @finalLine.
  ///
  /// In en, this message translates to:
  /// **'Ask your first question.'**
  String get finalLine;

  /// No description provided for @builtBy.
  ///
  /// In en, this message translates to:
  /// **'Built by Wilson Borba'**
  String get builtBy;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {v}'**
  String version(String v);

  /// No description provided for @logoDescription.
  ///
  /// In en, this message translates to:
  /// **'Cortex logo'**
  String get logoDescription;
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
