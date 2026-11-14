// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get logIn => 'Log in';

  @override
  String get logOut => 'Log out';

  @override
  String get newChat => 'New chat';

  @override
  String get temporaryChat => 'Temporary chat';

  @override
  String get chats => 'Chats';

  @override
  String get memory => 'Memory';

  @override
  String get personas => 'Personas';

  @override
  String get usage => 'Usage';

  @override
  String get timing => 'Timing';

  @override
  String get stats => 'Statistics';

  @override
  String get events => 'Events';

  @override
  String get newPersona => 'New persona';

  @override
  String get details => 'Details';

  @override
  String get close => 'Close';

  @override
  String get notFoundTitle => 'Page not found';

  @override
  String get notFoundMessage => 'This path or item does not exist.';

  @override
  String get goToChats => 'Go to chats';

  @override
  String get signingIn => 'Signing you in …';

  @override
  String get noChatsYet => 'No chats yet';

  @override
  String get output => 'Output';

  @override
  String get product => 'Product';

  @override
  String get howItWorks => 'How it works';

  @override
  String get engineering => 'Engineering';

  @override
  String get faq => 'FAQ';

  @override
  String get language => 'Language';

  @override
  String get themeSwitch => 'Theme';

  @override
  String get menu => 'Menu';

  @override
  String get heroLabel => 'AI chat workspace';

  @override
  String get heroTitle => 'Chat with your memory, files and the web';

  @override
  String get heroLead =>
      'Cortex answers with a local model and shows each step: memory, files, web sources and thinking.';

  @override
  String get startChat => 'Start a chat';

  @override
  String get seeHow => 'See how it works';

  @override
  String get example => 'Example';

  @override
  String get demoMemoryPrompt => 'What did I decide about the usage balancer?';

  @override
  String get demoFastPrompt => 'What is the latest stable Rust version?';

  @override
  String get demoDeepPrompt =>
      'Compare SQLite and PostgreSQL for a small web app.';

  @override
  String get demoThinkPrompt =>
      'A train leaves at 09:40 and arrives at 13:05. How many minutes?';

  @override
  String get demoMemoryAnswer =>
      'You decided on a fair share per user over 24 hours, with a base weight of 1 for new users.';

  @override
  String get demoFastAnswer =>
      'The answer comes from the pages read now, and each source is listed below the answer.';

  @override
  String get demoDeepAnswer =>
      'For one small app with few writers, SQLite is simpler; for many writers at the same time, PostgreSQL is safer.';

  @override
  String get demoThinkAnswer => 'The trip takes 205 minutes.';

  @override
  String get demoReplay => 'Replay';

  @override
  String get stepSecurity => 'Security check OK';

  @override
  String get stepMemorySearch => 'Searching your memory';

  @override
  String get stepMemoriesFound => 'Memories found';

  @override
  String get stepQueries => 'Preparing search queries';

  @override
  String get stepWebSearch => 'Searching the web';

  @override
  String get stepPageRead => 'Reading the web page';

  @override
  String get stepThinking => 'Thinking step';

  @override
  String get stepAnswer => 'Writing the answer';

  @override
  String get sources => 'Sources';

  @override
  String get whatTitle => 'What it does';

  @override
  String get whatMemory => 'Chat with memory';

  @override
  String get whatMemoryText =>
      'Cortex finds up to 5 of your memories that match the question and shows which ones it used.';

  @override
  String get whatWeb => 'Web research';

  @override
  String get whatWebText =>
      'Fast, medium or deep: more queries and more pages for harder questions, with every source shown.';

  @override
  String get whatFiles => 'Files';

  @override
  String get whatFilesText =>
      'PDF (with OCR for scanned pages), DOCX with tables, audio up to 10 minutes and images.';

  @override
  String get whatThinking => 'Thinking';

  @override
  String get whatThinkingText =>
      'Plan, work and check steps before the final answer, at most 2 rounds, and you can stop thinking at any time.';

  @override
  String get pipelineTitle => 'How one request works';

  @override
  String get stageAccept => 'Accept';

  @override
  String get stageGather => 'Gather';

  @override
  String get stageAssemble => 'Assemble';

  @override
  String get stageThink => 'Think';

  @override
  String get stageAnswer => 'Answer';

  @override
  String get stageSave => 'Save';

  @override
  String get stageAcceptText =>
      'Size and token checks, then the security check.';

  @override
  String get stageGatherText => 'Files, memory and web at the same time.';

  @override
  String get stageAssembleText =>
      'Fills the 8192-token context in a fixed order.';

  @override
  String get stageThinkText => 'Optional plan, work and check.';

  @override
  String get stageAnswerText => 'One model call, streamed token by token.';

  @override
  String get stageSaveText => 'History, memory, usage and the run record.';

  @override
  String get pipelineDescription =>
      'Diagram of the six stages of one request: Accept, Gather with files, memory and web in parallel, Assemble, Think, Answer and Save.';

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get memoryTitle => 'Memory with Hippocampus';

  @override
  String get memoryScope =>
      'Every memory has a scope: workspace, app and user. A search never leaves the scope.';

  @override
  String get memorySearch =>
      'Word search and semantic search are merged with Reciprocal Rank Fusion (RRF).';

  @override
  String get memoryPersonas =>
      'Personas: the person you are, a bot voice for a chat, and people you name in a question.';

  @override
  String get memoryRepo => 'Hippocampus repository';

  @override
  String get scopeDescription =>
      'Tree of a memory scope: a workspace holds apps, and an app holds users.';

  @override
  String get graphDescription =>
      'Example memory graph: memories linked to tags, entities and files.';

  @override
  String get webTitle => 'Web research';

  @override
  String get webMode => 'Mode';

  @override
  String get webQueries => 'Queries';

  @override
  String get webPages => 'Pages';

  @override
  String get webDepth => 'Link depth';

  @override
  String get webTime => 'Time limit';

  @override
  String get webFast => 'Fast';

  @override
  String get webMedium => 'Medium';

  @override
  String get webDeep => 'Deep';

  @override
  String get webFastPages => '5';

  @override
  String get webMediumPages => '5 per level';

  @override
  String get webMethod =>
      'Pages are cut into chunks of about 500 tokens and ranked with BM25 and RRF. Web text uses no embeddings, and sources stay apart from your memory.';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get liveTitle => 'Live control';

  @override
  String get liveSteps =>
      'Live steps: every stage and step is streamed as it happens.';

  @override
  String get liveReconnect =>
      'Reconnect: the answer keeps running on the server, and you can come back to it.';

  @override
  String get liveStop => 'Stop: you can stop an answer at any time.';

  @override
  String get liveStopThinking =>
      'Stop thinking: go to the final answer with the notes so far.';

  @override
  String get engTitle => 'Engineering';

  @override
  String get codeTitle => 'Real code';

  @override
  String get codeRrf => 'Reciprocal Rank Fusion of web search lists';

  @override
  String get codeGather => 'Files, memory and web gathered at the same time';

  @override
  String get codeNames => 'Tag search inside one scope';

  @override
  String get researchTitle => 'Research basis';

  @override
  String get securityTitle => 'Security and privacy';

  @override
  String get securityShield =>
      'Every input passes a security check with fixed rules and a classifier before anything is saved.';

  @override
  String get securityIsolation =>
      'Each user sees only their own chats, files and memories, inside each app.';

  @override
  String get securityLogs => 'Logs and run records hold no chat text.';

  @override
  String get faqLoginQ => 'Do I need an account?';

  @override
  String get faqLoginA =>
      'Yes. You log in with your Asodya account before the first chat.';

  @override
  String get faqModelQ => 'Which model answers?';

  @override
  String get faqModelA =>
      'A local text model, and a local vision model when you send an image.';

  @override
  String get faqDataQ => 'Where does my data live?';

  @override
  String get faqDataA =>
      'On Asodya machines: chats in the database, memories in Hippocampus and files in FSM.';

  @override
  String get faqTempQ => 'What is a temporary chat?';

  @override
  String get faqTempA =>
      'A chat that is not saved: it ends after one hour or when you close it, and it creates no memory.';

  @override
  String get faqLangQ => 'Which languages?';

  @override
  String get faqLangA => 'The app is in English, Portuguese and Thai.';

  @override
  String get finalLine => 'Ask your first question.';

  @override
  String version(String v) {
    return 'Version $v';
  }

  @override
  String get logoDescription => 'Cortex logo';

  @override
  String get chatGreeting => 'What do you want to know?';

  @override
  String get composerHint => 'Write a message';

  @override
  String get attach => 'Attach files';

  @override
  String get webLabel => 'Web';

  @override
  String get webOff => 'Off';

  @override
  String get memoryToggle => 'Memory';

  @override
  String get topicHint => 'Topic (optional)';

  @override
  String get thinkingToggle => 'Thinking';

  @override
  String get personaPicker => 'Bot persona';

  @override
  String get noPersona => 'No persona';

  @override
  String get send => 'Send';

  @override
  String get stop => 'Stop';

  @override
  String get stopThinking => 'Stop thinking';

  @override
  String usuallyAbout(int n) {
    return 'Usually about $n s';
  }

  @override
  String elapsed(int n) {
    return '$n s';
  }

  @override
  String get stagesTimeline => 'Stages';

  @override
  String get thinkingSection => 'Thinking';

  @override
  String get rolePlan => 'Plan';

  @override
  String get roleWork => 'Work';

  @override
  String get roleCheck => 'Check';

  @override
  String get roleNotes => 'Notes';

  @override
  String roundN(int n) {
    return 'round $n';
  }

  @override
  String usedMemories(int n) {
    return 'Used $n memories';
  }

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get retry => 'Retry';

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get rename => 'Rename';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get deleteChatTitle => 'Delete this chat?';

  @override
  String get deleteChatMessage =>
      'The chat and its memories are deleted. This cannot be undone.';

  @override
  String tokenCounter(int n, int max) {
    return '$n of $max tokens';
  }

  @override
  String get overLimit => 'The message is over the input limit.';

  @override
  String get uploading => 'Uploading';

  @override
  String statsLine(String time, String s, int input, int output) {
    return '$time · $s s · $input in, $output out tokens';
  }

  @override
  String get cancelledLine => 'Stopped';

  @override
  String get steps_web_queries => 'Preparing search queries';

  @override
  String get steps_queue_wait => 'Waiting for the model';

  @override
  String get steps_model_load => 'Loading the model';

  @override
  String get steps_model_ready => 'The model is ready';

  @override
  String get steps_security_ok => 'Security check OK';

  @override
  String get steps_file_read_page => 'Reading the file page';

  @override
  String get steps_file_ocr_page => 'Reading the page image';

  @override
  String get steps_file_transcribe => 'Transcribing audio';

  @override
  String get steps_memory_search => 'Searching your memory';

  @override
  String get steps_memory_found => 'Memories found';

  @override
  String get steps_web_search => 'Searching the web';

  @override
  String get steps_web_page_read => 'Reading the web page';

  @override
  String get steps_chunks_selected => 'Text parts selected';

  @override
  String get steps_thinking_step => 'Thinking step';

  @override
  String get steps_thinking_stopped => 'Thinking stopped by the user';

  @override
  String get temporaryBanner => 'Temporary: not saved, lost when you refresh.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String daysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get running => 'Running';

  @override
  String get chatActions => 'Chat actions';

  @override
  String get deleteFailed => 'The chat was not deleted.';

  @override
  String get chatsLoadFailed => 'Chats could not be loaded.';

  @override
  String get graphView => 'Graph';

  @override
  String get listView => 'List';

  @override
  String get depthLabel => 'Depth';

  @override
  String get limitLabel => 'Limit';

  @override
  String get legendMemory => 'Memory';

  @override
  String get legendTag => 'Tag';

  @override
  String get legendEntity => 'Entity';

  @override
  String get legendFile => 'File';

  @override
  String get noMemories => 'No memories yet';

  @override
  String get memoryLoadFailed => 'Memory could not be loaded.';

  @override
  String get memoryNotFound => 'This memory was not found.';

  @override
  String get superseded => 'Superseded';

  @override
  String get detailsLabel => 'Details';

  @override
  String get linkedFiles => 'Files';

  @override
  String get linkedMemories => 'Linked memories';

  @override
  String get typeChat => 'Chat';

  @override
  String get typeFile => 'File';

  @override
  String get typeNote => 'Note';

  @override
  String get graphTruncated =>
      'Only part of the graph is shown. Raise the limit to see more.';

  @override
  String get memoryGraphDescription =>
      'Memory graph. The list view shows the same nodes as text.';

  @override
  String get legendPersona => 'Persona';

  @override
  String get linkedPersonas => 'Linked personas';

  @override
  String get searchPersonas => 'Search personas';

  @override
  String get allPersonaTypes => 'All types';

  @override
  String get personType => 'Person';

  @override
  String get botType => 'Bot';

  @override
  String get you => 'You';

  @override
  String get noPersonas => 'No personas yet';

  @override
  String get personasLoadFailed => 'Personas could not be loaded.';

  @override
  String get personaFormFailed => 'The persona form could not be loaded.';

  @override
  String get personaSaveFailed =>
      'The persona could not be saved. Check the marked fields.';

  @override
  String get editPersona => 'Edit persona';

  @override
  String get personaType => 'Type';

  @override
  String get personaName => 'Name';

  @override
  String get personaAliases => 'Aliases';

  @override
  String get personaIsSelf => 'This persona is you';

  @override
  String get personaRequiredLegend => '* Required field';

  @override
  String get personaSaved => 'Persona saved';

  @override
  String get deletePersona => 'Delete persona';

  @override
  String get deletePersonaConfirm => 'Delete this persona and its attributes?';

  @override
  String get personaFieldRequired => 'This field is required.';

  @override
  String get personaFieldUnknown => 'This field is not in the stored schema.';

  @override
  String get personaFieldType => 'Use the type shown for this field.';

  @override
  String get personaFieldInvalid => 'Check this field.';

  @override
  String get addPersonaItem => 'Add item';

  @override
  String get removePersonaItem => 'Remove item';

  @override
  String get choosePersonaDate => 'Choose a date';

  @override
  String get clear => 'Clear';

  @override
  String get personaYes => 'Yes';

  @override
  String get personaNo => 'No';

  @override
  String get personaInteger => 'Whole number';

  @override
  String get personaNumber => 'Number';

  @override
  String get personaActionFailed => 'Could not complete the action. Try again.';

  @override
  String get usageLoadFailed => 'Usage could not be loaded.';

  @override
  String get notAvailableYet => 'Not available yet';

  @override
  String usageWindow(int hours) {
    return 'Your usage in the last $hours hours';
  }

  @override
  String get usageInputTokens => 'Input tokens';

  @override
  String get usageOutputTokens => 'Output tokens';

  @override
  String get usageTotalTokens => 'Total tokens';

  @override
  String get usageImages => 'Images';

  @override
  String get usageAudio => 'Audio items';

  @override
  String get usagePriority => 'Your priority';

  @override
  String get usagePriorityHelp =>
      'The next model call goes to the waiting user with the lowest token use divided by their weight. A call that has started will finish.';

  @override
  String get usageWeight => 'Weight';

  @override
  String get usageAccountAge => 'Account age part';

  @override
  String get usageFrequency => 'Sign-in frequency part';

  @override
  String get usageAccountDays => 'Account age in days';

  @override
  String get usageSignInDays => 'Days with a sign-in in the last 90 days';

  @override
  String get usageWeightFormula =>
      'Weight = 1 + account age part + sign-in frequency part.';

  @override
  String usageKind(String mode, String thinking) {
    return '$mode, $thinking';
  }

  @override
  String get usageThinkingOn => 'thinking on';

  @override
  String get usageThinkingOff => 'thinking off';

  @override
  String usageSeconds(String value) {
    return '$value s';
  }

  @override
  String get usageTimingHelp =>
      'Average of the last 20 completed answers for each kind. Failed and cancelled answers are excluded.';

  @override
  String get usageEmpty => 'No usage records yet';

  @override
  String get usageMetric => 'Measure';

  @override
  String get usageRuns => 'Total answers';

  @override
  String get usageAverageTime => 'Average time';

  @override
  String get usageAverageInput => 'Average input tokens';

  @override
  String get usageAverageOutput => 'Average output tokens';

  @override
  String get usageAverageTotal => 'Average total tokens';

  @override
  String get usageSuccessRate => 'Success rate';

  @override
  String get usageRequest => 'Request ID';

  @override
  String get usageOutput => 'Output ID';

  @override
  String get usageUser => 'User';

  @override
  String get usageModel => 'Model';

  @override
  String get usageRole => 'Role';

  @override
  String get usageStarted => 'Started';

  @override
  String get usageFinished => 'Finished';

  @override
  String get usageNoUser => 'No user';

  @override
  String get loadMore => 'Load more';

  @override
  String get loading => 'Loading';

  @override
  String get process1001 => 'The route was not found';

  @override
  String get process1002 => 'The method is not allowed';

  @override
  String get process1003 => 'The request data is not valid';

  @override
  String get process1004 => 'The JSON body is not valid';

  @override
  String get process1005 => 'The x-uuid header is required';

  @override
  String get process1006 => 'The content type is not supported';

  @override
  String get process1007 => 'The request body is too large';

  @override
  String get process1008 => 'The server could not complete the request';

  @override
  String get process1009 => 'The app_id is not allowed';

  @override
  String get process1010 => 'The server is under heavy load. Try later';

  @override
  String get process1011 => 'The local call queue failed';

  @override
  String get process1012 => 'The local model call failed';

  @override
  String get process1201 => 'The input is over the token limit';

  @override
  String get process1013 => 'The usage data is not available';

  @override
  String get process1014 => 'Are you kidding me, clown?';

  @override
  String get process1015 => 'The input security check is not available';

  @override
  String get process1016 => 'The chat was not found';

  @override
  String get process1017 => 'The chat history could not be loaded or changed';

  @override
  String get process1018 => 'The output was not found';

  @override
  String get process1019 => 'The exchange memory could not be saved';

  @override
  String get process1020 => 'Web search is not available';

  @override
  String get process1021 => 'The web page timed out';

  @override
  String get process1022 => 'The web page is over the size limit';

  @override
  String get process1023 => 'The web page is not HTML';

  @override
  String get process1024 => 'The web page could not be read';

  @override
  String get process1025 => 'The web page has no readable main text';

  @override
  String get process1026 => 'The web time limit was reached';

  @override
  String get process1027 => 'The web page limit was reached';

  @override
  String get process1028 => 'The web crawl rules could not be loaded';

  @override
  String get process1029 => 'Memory could not be loaded';

  @override
  String get process1030 => 'The file type is not supported';

  @override
  String get process1031 => 'The file is over the size limit';

  @override
  String get process1032 => 'The file text could not be read';

  @override
  String get process1033 => 'The file is over the OCR page limit';

  @override
  String get process1034 => 'The file image text could not be read';

  @override
  String get process1035 => 'Temporary chat storage is not available';

  @override
  String get process1036 => 'The thinking time limit was reached';

  @override
  String get process1037 => 'The live log stream is for the LAN';

  @override
  String get process1038 => 'Telemetry data could not be loaded';

  @override
  String get process1039 => 'The memory graph node was not found';

  @override
  String get process1040 => 'The file was not saved';

  @override
  String get process1041 => 'The file was not found';

  @override
  String get process1042 => 'The output events are not available';

  @override
  String get process1043 => 'The output is not running';

  @override
  String get process1044 => 'The chat memories could not be deleted';

  @override
  String get process1045 => 'The persona was not found';

  @override
  String get process1046 => 'The persona data is not valid';

  @override
  String get process1047 => 'Personas could not be loaded or changed';

  @override
  String get process1048 => 'The audio is over the 10 minute limit';

  @override
  String get process1049 => 'The audio could not be transcribed';

  @override
  String get process1050 => 'The file worker did not answer';

  @override
  String processUnknown(int number) {
    return 'Something went wrong ($number).';
  }

  @override
  String get processGeneric => 'Something went wrong. Try again.';

  @override
  String get networkOffline =>
      'You are offline. Check your connection and retry.';

  @override
  String get stepUnknown => 'Working';

  @override
  String get statusStarted => 'Started';

  @override
  String get statusDone => 'Done';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get expandThinking => 'Expand thinking';

  @override
  String get collapseThinking => 'Collapse thinking';

  @override
  String get noPersonaMatches => 'No personas match these filters';

  @override
  String get account => 'Account';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemChoice => 'System';

  @override
  String get lightChoice => 'Light';

  @override
  String get darkChoice => 'Dark';

  @override
  String get browserPreferenceNote =>
      'These choices are saved in this browser.';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortugueseBrazil => 'Português (Brasil)';

  @override
  String get languageThai => 'ไทย';

  @override
  String get chatDisclaimer =>
      'Cortex can make mistakes. Check important facts.';

  @override
  String get copyFailed => 'Could not copy. Select the text and try again.';

  @override
  String get answerStarted => 'Answer started';

  @override
  String get answerComplete => 'Answer complete';

  @override
  String thoughtFor(Object seconds) {
    return 'Thought for $seconds s';
  }

  @override
  String get codeLabel => 'Code';

  @override
  String get composerOptions => 'Options';

  @override
  String get composerEmptyReason => 'Write a message before sending.';

  @override
  String get composerUploadReason => 'Wait for the file upload to finish.';

  @override
  String get graphZoomIn => 'Zoom in';

  @override
  String get graphZoomOut => 'Zoom out';

  @override
  String get graphFit => 'Fit graph';

  @override
  String get graphSearch => 'Search memories';

  @override
  String get graphNoLinks => 'These memories have no links yet';

  @override
  String get graphMissingNode => 'This node is not in the current result.';

  @override
  String get openChat => 'Open chat';

  @override
  String get showInGraph => 'Show in memory graph';

  @override
  String get exampleChat => 'Planning chat';

  @override
  String get exampleMemoryOne => 'Plan the next steps';

  @override
  String get exampleMemoryTwo => 'Compare the options';

  @override
  String get exampleTag => 'Planning';

  @override
  String get exampleFile => 'Plan document';

  @override
  String get exampleEntity => 'Project';

  @override
  String get graphBack => 'Back';

  @override
  String get personasPurpose => 'People and bot voices used in your chats.';

  @override
  String get personaIdentity => 'Identity';

  @override
  String get personaSchemaFields => 'Schema fields';

  @override
  String get engIntro =>
      'Cortex is a chat application with a Flutter web client and a Rust API. Cortex runs the request pipeline; Hippocampus owns scoped memories, personas and file records. The gateway authenticates each request before it reaches the API.';

  @override
  String get engContextTitle => 'System context';

  @override
  String get engContainersTitle => 'Inside the system';

  @override
  String get engPipelineTitle => 'The request pipeline';

  @override
  String get engDecisionsTitle => 'Engineering decisions';

  @override
  String get engContextAlt =>
      'The user reaches Cortex through the gateway. Cortex calls the memory service and the model runtime. Hippocampus uses file storage. Cortex and Hippocampus persist their own data.';

  @override
  String get engContainersAlt =>
      'The Flutter web client calls the gateway, which authenticates and forwards requests to the Rust Cortex API. The API calls Hippocampus and the model runtime. PostgreSQL stores chats and memory metadata. Hippocampus stores documents in CouchDB. Valkey keeps the Cortex event journal and cached context.';

  @override
  String get engContextWord => 'Context';

  @override
  String get engDecisionWord => 'Decision';

  @override
  String get engResultWord => 'Result';

  @override
  String get engSource => 'View source';

  @override
  String get engUser => 'User';

  @override
  String get engCortex => 'Cortex';

  @override
  String get engGateway => 'Gateway';

  @override
  String get engMemoryService => 'Hippocampus';

  @override
  String get engModelRuntime => 'Model runtime';

  @override
  String get engFileStorage => 'File storage';

  @override
  String get engDatabases => 'Databases';

  @override
  String get engApps => 'Cortex and Hippocampus';

  @override
  String get engFrontend => 'Frontend';

  @override
  String get engApi => 'Cortex API';

  @override
  String get engPostgres => 'Relational data';

  @override
  String get engDocumentStore => 'Document store';

  @override
  String get engCache => 'Event journal and cache';

  @override
  String get engSends => 'Sends requests';

  @override
  String get engForwards => 'Authenticates and forwards';

  @override
  String get engRecalls => 'Recalls and saves';

  @override
  String get engGenerates => 'Requests answers';

  @override
  String get engPersists => 'Persists data';

  @override
  String get engStoresDocs => 'Stores documents';

  @override
  String get engCaches => 'Stores events and context';

  @override
  String get engStoresFiles => 'Stores files';

  @override
  String get engFrontendRole => 'Shows chats and memory views.';

  @override
  String get engGatewayRole => 'Authenticates and forwards requests.';

  @override
  String get engApiRole => 'Runs the six request stages.';

  @override
  String get engMemoryRole => 'Owns scoped memories and personas.';

  @override
  String get engModelRole => 'Runs local language models.';

  @override
  String get engPostgresRole => 'Stores chats and memory metadata.';

  @override
  String get engDocumentRole => 'Stores memory documents.';

  @override
  String get engCacheRole => 'Keeps events for replay and caches context.';

  @override
  String get engAcceptDetail => 'Checks input, scope and limits.';

  @override
  String get engGatherDetail =>
      'Reads files, memory and web sources at the same time.';

  @override
  String get engAssembleDetail => 'Builds the context within its budget.';

  @override
  String get engThinkDetail => 'Runs the requested thinking step.';

  @override
  String get engAnswerDetail => 'Streams the answer and its events.';

  @override
  String get engSaveDetail =>
      'Stores the finished answer and its exchange memory.';

  @override
  String get engRustTitle => 'Rust backends';

  @override
  String get engRustContext =>
      'The pipeline has distinct stages and failure states.';

  @override
  String get engRustDecision =>
      'Use Rust and explicit stage types for both backends.';

  @override
  String get engRustResult =>
      'The stage contract can be checked by the compiler and tests.';

  @override
  String get engJournalTitle => 'Reconnect with an event journal';

  @override
  String get engJournalContext =>
      'A browser can lose its connection while an answer runs.';

  @override
  String get engJournalDecision =>
      'Store numbered events and read after the last known event.';

  @override
  String get engJournalResult =>
      'A client can resume the stream within the journal retention window.';

  @override
  String get engGatherTitle => 'Gather sources together';

  @override
  String get engGatherContext =>
      'Files, memory and web reads do not depend on each other.';

  @override
  String get engGatherDecision =>
      'Start the three source jobs together in Gather.';

  @override
  String get engGatherResult =>
      'One source does not need to wait for another to start.';

  @override
  String get engMemoryTitle => 'One memory per finished answer';

  @override
  String get engMemoryContext =>
      'A finished answer must remain useful for later recall.';

  @override
  String get engMemoryDecision =>
      'Save the exchange directly, with its input title and chat link.';

  @override
  String get engMemoryResult =>
      'The save uses no extra model call and keeps its memory assignment.';

  @override
  String get engResearchContext => 'Context and retrieval';

  @override
  String get engResearchPrompts => 'Prompts and output format';

  @override
  String get engResearchReasoning => 'Reasoning and verification';

  @override
  String get engTechFlutter => 'Flutter web';

  @override
  String get engTechHTTP => 'HTTP';

  @override
  String get engTechRust => 'Rust';

  @override
  String get engTechOllama => 'Ollama';

  @override
  String get engTechPostgreSQL => 'PostgreSQL';

  @override
  String get engTechCouchDB => 'CouchDB';

  @override
  String get engTechValkey => 'Valkey';

  @override
  String get settingsGeneral => 'General';

  @override
  String get themeDescription =>
      'Use the system theme, the light theme or the dark theme.';

  @override
  String get languageDescription => 'Select the language of Cortex.';

  @override
  String get pinnedChats => 'Pinned';

  @override
  String get recentChats => 'Recent';
}
