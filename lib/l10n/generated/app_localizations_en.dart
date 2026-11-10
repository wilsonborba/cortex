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
  String get signingIn => 'Opening the login';

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
  String get engMachines =>
      'Local machines on one network: the MSI GPU runs the language model, Pong runs embeddings, FSM keeps the files, and a database server keeps the data.';

  @override
  String get engRust => 'The Cortex and Hippocampus APIs are written in Rust.';

  @override
  String get engLocal => 'Local models only. No cloud language model.';

  @override
  String get machinesDescription =>
      'Diagram of the machines: the Cortex API sends model calls to the MSI GPU, memory calls to Hippocampus, which uses Pong for embeddings, FSM for files and the database server.';

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
  String get builtBy => 'Built by Wilson Borba';

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
}
