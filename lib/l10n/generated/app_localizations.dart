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

  /// No description provided for @chatGreeting.
  ///
  /// In en, this message translates to:
  /// **'What do you want to know?'**
  String get chatGreeting;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get composerHint;

  /// No description provided for @attach.
  ///
  /// In en, this message translates to:
  /// **'Attach files'**
  String get attach;

  /// No description provided for @webLabel.
  ///
  /// In en, this message translates to:
  /// **'Web'**
  String get webLabel;

  /// No description provided for @webOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get webOff;

  /// No description provided for @memoryToggle.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get memoryToggle;

  /// No description provided for @topicHint.
  ///
  /// In en, this message translates to:
  /// **'Topic (optional)'**
  String get topicHint;

  /// No description provided for @thinkingToggle.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinkingToggle;

  /// No description provided for @personaPicker.
  ///
  /// In en, this message translates to:
  /// **'Bot persona'**
  String get personaPicker;

  /// No description provided for @noPersona.
  ///
  /// In en, this message translates to:
  /// **'No persona'**
  String get noPersona;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopThinking.
  ///
  /// In en, this message translates to:
  /// **'Stop thinking'**
  String get stopThinking;

  /// No description provided for @usuallyAbout.
  ///
  /// In en, this message translates to:
  /// **'Usually about {n} s'**
  String usuallyAbout(int n);

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'{n} s'**
  String elapsed(int n);

  /// No description provided for @stagesTimeline.
  ///
  /// In en, this message translates to:
  /// **'Stages'**
  String get stagesTimeline;

  /// No description provided for @thinkingSection.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get thinkingSection;

  /// No description provided for @rolePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get rolePlan;

  /// No description provided for @roleWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get roleWork;

  /// No description provided for @roleCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get roleCheck;

  /// No description provided for @roleNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get roleNotes;

  /// No description provided for @roundN.
  ///
  /// In en, this message translates to:
  /// **'round {n}'**
  String roundN(int n);

  /// No description provided for @usedMemories.
  ///
  /// In en, this message translates to:
  /// **'Used {n} memories'**
  String usedMemories(int n);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @jumpToLatest.
  ///
  /// In en, this message translates to:
  /// **'Jump to latest'**
  String get jumpToLatest;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this chat?'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatMessage.
  ///
  /// In en, this message translates to:
  /// **'The chat and its memories are deleted. This cannot be undone.'**
  String get deleteChatMessage;

  /// No description provided for @tokenCounter.
  ///
  /// In en, this message translates to:
  /// **'{n} of {max} tokens'**
  String tokenCounter(int n, int max);

  /// No description provided for @overLimit.
  ///
  /// In en, this message translates to:
  /// **'The message is over the input limit.'**
  String get overLimit;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @statsLine.
  ///
  /// In en, this message translates to:
  /// **'{time} · {s} s · {input} in, {output} out tokens'**
  String statsLine(String time, String s, int input, int output);

  /// No description provided for @cancelledLine.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get cancelledLine;

  /// No description provided for @steps_web_queries.
  ///
  /// In en, this message translates to:
  /// **'Preparing search queries'**
  String get steps_web_queries;

  /// No description provided for @steps_queue_wait.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the model'**
  String get steps_queue_wait;

  /// No description provided for @steps_model_load.
  ///
  /// In en, this message translates to:
  /// **'Loading the model'**
  String get steps_model_load;

  /// No description provided for @steps_model_ready.
  ///
  /// In en, this message translates to:
  /// **'The model is ready'**
  String get steps_model_ready;

  /// No description provided for @steps_security_ok.
  ///
  /// In en, this message translates to:
  /// **'Security check OK'**
  String get steps_security_ok;

  /// No description provided for @steps_file_read_page.
  ///
  /// In en, this message translates to:
  /// **'Reading the file page'**
  String get steps_file_read_page;

  /// No description provided for @steps_file_ocr_page.
  ///
  /// In en, this message translates to:
  /// **'Reading the page image'**
  String get steps_file_ocr_page;

  /// No description provided for @steps_file_transcribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio'**
  String get steps_file_transcribe;

  /// No description provided for @steps_memory_search.
  ///
  /// In en, this message translates to:
  /// **'Searching your memory'**
  String get steps_memory_search;

  /// No description provided for @steps_memory_found.
  ///
  /// In en, this message translates to:
  /// **'Memories found'**
  String get steps_memory_found;

  /// No description provided for @steps_web_search.
  ///
  /// In en, this message translates to:
  /// **'Searching the web'**
  String get steps_web_search;

  /// No description provided for @steps_web_page_read.
  ///
  /// In en, this message translates to:
  /// **'Reading the web page'**
  String get steps_web_page_read;

  /// No description provided for @steps_chunks_selected.
  ///
  /// In en, this message translates to:
  /// **'Text parts selected'**
  String get steps_chunks_selected;

  /// No description provided for @steps_thinking_step.
  ///
  /// In en, this message translates to:
  /// **'Thinking step'**
  String get steps_thinking_step;

  /// No description provided for @steps_thinking_stopped.
  ///
  /// In en, this message translates to:
  /// **'Thinking stopped by the user'**
  String get steps_thinking_stopped;

  /// No description provided for @temporaryBanner.
  ///
  /// In en, this message translates to:
  /// **'Temporary: not saved, lost when you refresh.'**
  String get temporaryBanner;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String daysAgo(int n);

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @chatActions.
  ///
  /// In en, this message translates to:
  /// **'Chat actions'**
  String get chatActions;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'The chat was not deleted.'**
  String get deleteFailed;

  /// No description provided for @chatsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Chats could not be loaded.'**
  String get chatsLoadFailed;

  /// No description provided for @graphView.
  ///
  /// In en, this message translates to:
  /// **'Graph'**
  String get graphView;

  /// No description provided for @listView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get listView;

  /// No description provided for @depthLabel.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depthLabel;

  /// No description provided for @limitLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitLabel;

  /// No description provided for @legendMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get legendMemory;

  /// No description provided for @legendTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get legendTag;

  /// No description provided for @legendEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get legendEntity;

  /// No description provided for @legendFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get legendFile;

  /// No description provided for @noMemories.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get noMemories;

  /// No description provided for @memoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Memory could not be loaded.'**
  String get memoryLoadFailed;

  /// No description provided for @memoryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This memory was not found.'**
  String get memoryNotFound;

  /// No description provided for @superseded.
  ///
  /// In en, this message translates to:
  /// **'Superseded'**
  String get superseded;

  /// No description provided for @detailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsLabel;

  /// No description provided for @linkedFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get linkedFiles;

  /// No description provided for @linkedMemories.
  ///
  /// In en, this message translates to:
  /// **'Linked memories'**
  String get linkedMemories;

  /// No description provided for @typeChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get typeChat;

  /// No description provided for @typeFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get typeFile;

  /// No description provided for @typeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get typeNote;

  /// No description provided for @graphTruncated.
  ///
  /// In en, this message translates to:
  /// **'Only part of the graph is shown. Raise the limit to see more.'**
  String get graphTruncated;

  /// No description provided for @memoryGraphDescription.
  ///
  /// In en, this message translates to:
  /// **'Memory graph. The list view shows the same nodes as text.'**
  String get memoryGraphDescription;

  /// No description provided for @legendPersona.
  ///
  /// In en, this message translates to:
  /// **'Persona'**
  String get legendPersona;

  /// No description provided for @linkedPersonas.
  ///
  /// In en, this message translates to:
  /// **'Linked personas'**
  String get linkedPersonas;

  /// No description provided for @searchPersonas.
  ///
  /// In en, this message translates to:
  /// **'Search personas'**
  String get searchPersonas;

  /// No description provided for @allPersonaTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get allPersonaTypes;

  /// No description provided for @personType.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get personType;

  /// No description provided for @botType.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get botType;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @noPersonas.
  ///
  /// In en, this message translates to:
  /// **'No personas yet'**
  String get noPersonas;

  /// No description provided for @personasLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Personas could not be loaded.'**
  String get personasLoadFailed;

  /// No description provided for @personaFormFailed.
  ///
  /// In en, this message translates to:
  /// **'The persona form could not be loaded.'**
  String get personaFormFailed;

  /// No description provided for @personaSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'The persona could not be saved. Check the marked fields.'**
  String get personaSaveFailed;

  /// No description provided for @editPersona.
  ///
  /// In en, this message translates to:
  /// **'Edit persona'**
  String get editPersona;

  /// No description provided for @personaType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get personaType;

  /// No description provided for @personaName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get personaName;

  /// No description provided for @personaAliases.
  ///
  /// In en, this message translates to:
  /// **'Aliases'**
  String get personaAliases;

  /// No description provided for @personaIsSelf.
  ///
  /// In en, this message translates to:
  /// **'This persona is you'**
  String get personaIsSelf;

  /// No description provided for @personaRequiredLegend.
  ///
  /// In en, this message translates to:
  /// **'* Required field'**
  String get personaRequiredLegend;

  /// No description provided for @personaSaved.
  ///
  /// In en, this message translates to:
  /// **'Persona saved'**
  String get personaSaved;

  /// No description provided for @deletePersona.
  ///
  /// In en, this message translates to:
  /// **'Delete persona'**
  String get deletePersona;

  /// No description provided for @deletePersonaConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this persona and its attributes?'**
  String get deletePersonaConfirm;

  /// No description provided for @personaFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get personaFieldRequired;

  /// No description provided for @personaFieldUnknown.
  ///
  /// In en, this message translates to:
  /// **'This field is not in the stored schema.'**
  String get personaFieldUnknown;

  /// No description provided for @personaFieldType.
  ///
  /// In en, this message translates to:
  /// **'Use the type shown for this field.'**
  String get personaFieldType;

  /// No description provided for @personaFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check this field.'**
  String get personaFieldInvalid;

  /// No description provided for @addPersonaItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addPersonaItem;

  /// No description provided for @removePersonaItem.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get removePersonaItem;

  /// No description provided for @choosePersonaDate.
  ///
  /// In en, this message translates to:
  /// **'Choose a date'**
  String get choosePersonaDate;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @personaYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get personaYes;

  /// No description provided for @personaNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get personaNo;

  /// No description provided for @personaInteger.
  ///
  /// In en, this message translates to:
  /// **'Whole number'**
  String get personaInteger;

  /// No description provided for @personaNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get personaNumber;

  /// No description provided for @personaActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the action. Try again.'**
  String get personaActionFailed;

  /// No description provided for @usageLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Usage could not be loaded.'**
  String get usageLoadFailed;

  /// No description provided for @notAvailableYet.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get notAvailableYet;

  /// No description provided for @usageWindow.
  ///
  /// In en, this message translates to:
  /// **'Your usage in the last {hours} hours'**
  String usageWindow(int hours);

  /// No description provided for @usageInputTokens.
  ///
  /// In en, this message translates to:
  /// **'Input tokens'**
  String get usageInputTokens;

  /// No description provided for @usageOutputTokens.
  ///
  /// In en, this message translates to:
  /// **'Output tokens'**
  String get usageOutputTokens;

  /// No description provided for @usageTotalTokens.
  ///
  /// In en, this message translates to:
  /// **'Total tokens'**
  String get usageTotalTokens;

  /// No description provided for @usageImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get usageImages;

  /// No description provided for @usageAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio items'**
  String get usageAudio;

  /// No description provided for @usagePriority.
  ///
  /// In en, this message translates to:
  /// **'Your priority'**
  String get usagePriority;

  /// No description provided for @usagePriorityHelp.
  ///
  /// In en, this message translates to:
  /// **'The next model call goes to the waiting user with the lowest token use divided by their weight. A call that has started will finish.'**
  String get usagePriorityHelp;

  /// No description provided for @usageWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get usageWeight;

  /// No description provided for @usageAccountAge.
  ///
  /// In en, this message translates to:
  /// **'Account age part'**
  String get usageAccountAge;

  /// No description provided for @usageFrequency.
  ///
  /// In en, this message translates to:
  /// **'Sign-in frequency part'**
  String get usageFrequency;

  /// No description provided for @usageAccountDays.
  ///
  /// In en, this message translates to:
  /// **'Account age in days'**
  String get usageAccountDays;

  /// No description provided for @usageSignInDays.
  ///
  /// In en, this message translates to:
  /// **'Days with a sign-in in the last 90 days'**
  String get usageSignInDays;

  /// No description provided for @usageWeightFormula.
  ///
  /// In en, this message translates to:
  /// **'Weight = 1 + account age part + sign-in frequency part.'**
  String get usageWeightFormula;

  /// No description provided for @usageKind.
  ///
  /// In en, this message translates to:
  /// **'{mode}, {thinking}'**
  String usageKind(String mode, String thinking);

  /// No description provided for @usageThinkingOn.
  ///
  /// In en, this message translates to:
  /// **'thinking on'**
  String get usageThinkingOn;

  /// No description provided for @usageThinkingOff.
  ///
  /// In en, this message translates to:
  /// **'thinking off'**
  String get usageThinkingOff;

  /// No description provided for @usageSeconds.
  ///
  /// In en, this message translates to:
  /// **'{value} s'**
  String usageSeconds(String value);

  /// No description provided for @usageTimingHelp.
  ///
  /// In en, this message translates to:
  /// **'Average of the last 20 completed answers for each kind. Failed and cancelled answers are excluded.'**
  String get usageTimingHelp;

  /// No description provided for @usageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No usage records yet'**
  String get usageEmpty;

  /// No description provided for @usageMetric.
  ///
  /// In en, this message translates to:
  /// **'Measure'**
  String get usageMetric;

  /// No description provided for @usageRuns.
  ///
  /// In en, this message translates to:
  /// **'Total answers'**
  String get usageRuns;

  /// No description provided for @usageAverageTime.
  ///
  /// In en, this message translates to:
  /// **'Average time'**
  String get usageAverageTime;

  /// No description provided for @usageAverageInput.
  ///
  /// In en, this message translates to:
  /// **'Average input tokens'**
  String get usageAverageInput;

  /// No description provided for @usageAverageOutput.
  ///
  /// In en, this message translates to:
  /// **'Average output tokens'**
  String get usageAverageOutput;

  /// No description provided for @usageAverageTotal.
  ///
  /// In en, this message translates to:
  /// **'Average total tokens'**
  String get usageAverageTotal;

  /// No description provided for @usageSuccessRate.
  ///
  /// In en, this message translates to:
  /// **'Success rate'**
  String get usageSuccessRate;

  /// No description provided for @usageRequest.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get usageRequest;

  /// No description provided for @usageOutput.
  ///
  /// In en, this message translates to:
  /// **'Output ID'**
  String get usageOutput;

  /// No description provided for @usageUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get usageUser;

  /// No description provided for @usageModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get usageModel;

  /// No description provided for @usageRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get usageRole;

  /// No description provided for @usageStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get usageStarted;

  /// No description provided for @usageFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get usageFinished;

  /// No description provided for @usageNoUser.
  ///
  /// In en, this message translates to:
  /// **'No user'**
  String get usageNoUser;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @process1001.
  ///
  /// In en, this message translates to:
  /// **'The route was not found'**
  String get process1001;

  /// No description provided for @process1002.
  ///
  /// In en, this message translates to:
  /// **'The method is not allowed'**
  String get process1002;

  /// No description provided for @process1003.
  ///
  /// In en, this message translates to:
  /// **'The request data is not valid'**
  String get process1003;

  /// No description provided for @process1004.
  ///
  /// In en, this message translates to:
  /// **'The JSON body is not valid'**
  String get process1004;

  /// No description provided for @process1005.
  ///
  /// In en, this message translates to:
  /// **'The x-uuid header is required'**
  String get process1005;

  /// No description provided for @process1006.
  ///
  /// In en, this message translates to:
  /// **'The content type is not supported'**
  String get process1006;

  /// No description provided for @process1007.
  ///
  /// In en, this message translates to:
  /// **'The request body is too large'**
  String get process1007;

  /// No description provided for @process1008.
  ///
  /// In en, this message translates to:
  /// **'The server could not complete the request'**
  String get process1008;

  /// No description provided for @process1009.
  ///
  /// In en, this message translates to:
  /// **'The app_id is not allowed'**
  String get process1009;

  /// No description provided for @process1010.
  ///
  /// In en, this message translates to:
  /// **'The server is under heavy load. Try later'**
  String get process1010;

  /// No description provided for @process1011.
  ///
  /// In en, this message translates to:
  /// **'The local call queue failed'**
  String get process1011;

  /// No description provided for @process1012.
  ///
  /// In en, this message translates to:
  /// **'The local model call failed'**
  String get process1012;

  /// No description provided for @process1201.
  ///
  /// In en, this message translates to:
  /// **'The input is over the token limit'**
  String get process1201;

  /// No description provided for @process1013.
  ///
  /// In en, this message translates to:
  /// **'The usage data is not available'**
  String get process1013;

  /// No description provided for @process1014.
  ///
  /// In en, this message translates to:
  /// **'Are you kidding me, clown?'**
  String get process1014;

  /// No description provided for @process1015.
  ///
  /// In en, this message translates to:
  /// **'The input security check is not available'**
  String get process1015;

  /// No description provided for @process1016.
  ///
  /// In en, this message translates to:
  /// **'The chat was not found'**
  String get process1016;

  /// No description provided for @process1017.
  ///
  /// In en, this message translates to:
  /// **'The chat history could not be loaded or changed'**
  String get process1017;

  /// No description provided for @process1018.
  ///
  /// In en, this message translates to:
  /// **'The output was not found'**
  String get process1018;

  /// No description provided for @process1019.
  ///
  /// In en, this message translates to:
  /// **'The exchange memory could not be saved'**
  String get process1019;

  /// No description provided for @process1020.
  ///
  /// In en, this message translates to:
  /// **'Web search is not available'**
  String get process1020;

  /// No description provided for @process1021.
  ///
  /// In en, this message translates to:
  /// **'The web page timed out'**
  String get process1021;

  /// No description provided for @process1022.
  ///
  /// In en, this message translates to:
  /// **'The web page is over the size limit'**
  String get process1022;

  /// No description provided for @process1023.
  ///
  /// In en, this message translates to:
  /// **'The web page is not HTML'**
  String get process1023;

  /// No description provided for @process1024.
  ///
  /// In en, this message translates to:
  /// **'The web page could not be read'**
  String get process1024;

  /// No description provided for @process1025.
  ///
  /// In en, this message translates to:
  /// **'The web page has no readable main text'**
  String get process1025;

  /// No description provided for @process1026.
  ///
  /// In en, this message translates to:
  /// **'The web time limit was reached'**
  String get process1026;

  /// No description provided for @process1027.
  ///
  /// In en, this message translates to:
  /// **'The web page limit was reached'**
  String get process1027;

  /// No description provided for @process1028.
  ///
  /// In en, this message translates to:
  /// **'The web crawl rules could not be loaded'**
  String get process1028;

  /// No description provided for @process1029.
  ///
  /// In en, this message translates to:
  /// **'Memory could not be loaded'**
  String get process1029;

  /// No description provided for @process1030.
  ///
  /// In en, this message translates to:
  /// **'The file type is not supported'**
  String get process1030;

  /// No description provided for @process1031.
  ///
  /// In en, this message translates to:
  /// **'The file is over the size limit'**
  String get process1031;

  /// No description provided for @process1032.
  ///
  /// In en, this message translates to:
  /// **'The file text could not be read'**
  String get process1032;

  /// No description provided for @process1033.
  ///
  /// In en, this message translates to:
  /// **'The file is over the OCR page limit'**
  String get process1033;

  /// No description provided for @process1034.
  ///
  /// In en, this message translates to:
  /// **'The file image text could not be read'**
  String get process1034;

  /// No description provided for @process1035.
  ///
  /// In en, this message translates to:
  /// **'Temporary chat storage is not available'**
  String get process1035;

  /// No description provided for @process1036.
  ///
  /// In en, this message translates to:
  /// **'The thinking time limit was reached'**
  String get process1036;

  /// No description provided for @process1037.
  ///
  /// In en, this message translates to:
  /// **'The live log stream is for the LAN'**
  String get process1037;

  /// No description provided for @process1038.
  ///
  /// In en, this message translates to:
  /// **'Telemetry data could not be loaded'**
  String get process1038;

  /// No description provided for @process1039.
  ///
  /// In en, this message translates to:
  /// **'The memory graph node was not found'**
  String get process1039;

  /// No description provided for @process1040.
  ///
  /// In en, this message translates to:
  /// **'The file was not saved'**
  String get process1040;

  /// No description provided for @process1041.
  ///
  /// In en, this message translates to:
  /// **'The file was not found'**
  String get process1041;

  /// No description provided for @process1042.
  ///
  /// In en, this message translates to:
  /// **'The output events are not available'**
  String get process1042;

  /// No description provided for @process1043.
  ///
  /// In en, this message translates to:
  /// **'The output is not running'**
  String get process1043;

  /// No description provided for @process1044.
  ///
  /// In en, this message translates to:
  /// **'The chat memories could not be deleted'**
  String get process1044;

  /// No description provided for @process1045.
  ///
  /// In en, this message translates to:
  /// **'The persona was not found'**
  String get process1045;

  /// No description provided for @process1046.
  ///
  /// In en, this message translates to:
  /// **'The persona data is not valid'**
  String get process1046;

  /// No description provided for @process1047.
  ///
  /// In en, this message translates to:
  /// **'Personas could not be loaded or changed'**
  String get process1047;

  /// No description provided for @process1048.
  ///
  /// In en, this message translates to:
  /// **'The audio is over the 10 minute limit'**
  String get process1048;

  /// No description provided for @process1049.
  ///
  /// In en, this message translates to:
  /// **'The audio could not be transcribed'**
  String get process1049;

  /// No description provided for @process1050.
  ///
  /// In en, this message translates to:
  /// **'The file worker did not answer'**
  String get process1050;

  /// No description provided for @processUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({number}).'**
  String processUnknown(int number);

  /// No description provided for @processGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get processGeneric;

  /// No description provided for @networkOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Check your connection and retry.'**
  String get networkOffline;

  /// No description provided for @stepUnknown.
  ///
  /// In en, this message translates to:
  /// **'Working'**
  String get stepUnknown;

  /// No description provided for @statusStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get statusStarted;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @expandThinking.
  ///
  /// In en, this message translates to:
  /// **'Expand thinking'**
  String get expandThinking;

  /// No description provided for @collapseThinking.
  ///
  /// In en, this message translates to:
  /// **'Collapse thinking'**
  String get collapseThinking;

  /// No description provided for @noPersonaMatches.
  ///
  /// In en, this message translates to:
  /// **'No personas match these filters'**
  String get noPersonaMatches;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemChoice.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemChoice;

  /// No description provided for @lightChoice.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightChoice;

  /// No description provided for @darkChoice.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkChoice;

  /// No description provided for @browserPreferenceNote.
  ///
  /// In en, this message translates to:
  /// **'These choices are saved in this browser.'**
  String get browserPreferenceNote;

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

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortugueseBrazil.
  ///
  /// In en, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortugueseBrazil;

  /// No description provided for @languageThai.
  ///
  /// In en, this message translates to:
  /// **'ไทย'**
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
