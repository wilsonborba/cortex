// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get logIn => 'Entrar';

  @override
  String get logOut => 'Sair';

  @override
  String get newChat => 'Nova conversa';

  @override
  String get temporaryChat => 'Conversa temporária';

  @override
  String get chats => 'Conversas';

  @override
  String get memory => 'Memória';

  @override
  String get personas => 'Personas';

  @override
  String get usage => 'Uso';

  @override
  String get timing => 'Tempo';

  @override
  String get stats => 'Estatísticas';

  @override
  String get events => 'Eventos';

  @override
  String get newPersona => 'Nova persona';

  @override
  String get details => 'Detalhes';

  @override
  String get close => 'Fechar';

  @override
  String get notFoundTitle => 'Página não encontrada';

  @override
  String get notFoundMessage => 'Este caminho ou item não existe.';

  @override
  String get goToChats => 'Ir para as conversas';

  @override
  String get signingIn => 'Abrindo o login';

  @override
  String get noChatsYet => 'Nenhuma conversa ainda';

  @override
  String get output => 'Resposta';

  @override
  String get product => 'Produto';

  @override
  String get howItWorks => 'Como funciona';

  @override
  String get engineering => 'Engenharia';

  @override
  String get faq => 'Perguntas';

  @override
  String get language => 'Idioma';

  @override
  String get themeSwitch => 'Tema';

  @override
  String get menu => 'Menu';

  @override
  String get heroLabel => 'Espaço de chat com IA';

  @override
  String get heroTitle => 'Converse com sua memória, arquivos e a web';

  @override
  String get heroLead =>
      'O Cortex responde com um modelo local e mostra cada etapa: memória, arquivos, fontes da web e raciocínio.';

  @override
  String get startChat => 'Começar uma conversa';

  @override
  String get seeHow => 'Veja como funciona';

  @override
  String get example => 'Exemplo';

  @override
  String get demoMemoryPrompt => 'O que eu decidi sobre o balanceador de uso?';

  @override
  String get demoFastPrompt => 'Qual é a versão estável mais recente do Rust?';

  @override
  String get demoDeepPrompt =>
      'Compare SQLite e PostgreSQL para um app web pequeno.';

  @override
  String get demoThinkPrompt =>
      'Um trem sai às 09:40 e chega às 13:05. Quantos minutos?';

  @override
  String get demoMemoryAnswer =>
      'Você decidiu uma divisão justa por usuário em 24 horas, com peso base 1 para novos usuários.';

  @override
  String get demoFastAnswer =>
      'A resposta vem das páginas lidas agora, e cada fonte aparece abaixo da resposta.';

  @override
  String get demoDeepAnswer =>
      'Para um app pequeno com poucos escritores, o SQLite é mais simples; para muitos escritores ao mesmo tempo, o PostgreSQL é mais seguro.';

  @override
  String get demoThinkAnswer => 'A viagem leva 205 minutos.';

  @override
  String get demoReplay => 'Repetir';

  @override
  String get stepSecurity => 'Verificação de segurança OK';

  @override
  String get stepMemorySearch => 'Buscando na sua memória';

  @override
  String get stepMemoriesFound => 'Memórias encontradas';

  @override
  String get stepQueries => 'Preparando as buscas';

  @override
  String get stepWebSearch => 'Buscando na web';

  @override
  String get stepPageRead => 'Lendo a página';

  @override
  String get stepThinking => 'Etapa de raciocínio';

  @override
  String get stepAnswer => 'Escrevendo a resposta';

  @override
  String get sources => 'Fontes';

  @override
  String get whatTitle => 'O que ele faz';

  @override
  String get whatMemory => 'Chat com memória';

  @override
  String get whatMemoryText =>
      'O Cortex encontra até 5 memórias suas que combinam com a pergunta e mostra quais usou.';

  @override
  String get whatWeb => 'Pesquisa na web';

  @override
  String get whatWebText =>
      'Rápida, média ou profunda: mais buscas e mais páginas para perguntas difíceis, com cada fonte mostrada.';

  @override
  String get whatFiles => 'Arquivos';

  @override
  String get whatFilesText =>
      'PDF (com OCR para páginas digitalizadas), DOCX com tabelas, áudio de até 10 minutos e imagens.';

  @override
  String get whatThinking => 'Raciocínio';

  @override
  String get whatThinkingText =>
      'Etapas de plano, trabalho e verificação antes da resposta final, no máximo 2 rodadas, e você pode parar o raciocínio a qualquer momento.';

  @override
  String get pipelineTitle => 'Como uma pergunta é processada';

  @override
  String get stageAccept => 'Aceitar';

  @override
  String get stageGather => 'Reunir';

  @override
  String get stageAssemble => 'Montar';

  @override
  String get stageThink => 'Raciocinar';

  @override
  String get stageAnswer => 'Responder';

  @override
  String get stageSave => 'Salvar';

  @override
  String get stageAcceptText =>
      'Verifica tamanho e tokens, depois a segurança.';

  @override
  String get stageGatherText => 'Arquivos, memória e web ao mesmo tempo.';

  @override
  String get stageAssembleText =>
      'Preenche o contexto de 8192 tokens em ordem fixa.';

  @override
  String get stageThinkText => 'Plano, trabalho e verificação opcionais.';

  @override
  String get stageAnswerText =>
      'Uma chamada ao modelo, transmitida token a token.';

  @override
  String get stageSaveText =>
      'Histórico, memória, uso e o registro da execução.';

  @override
  String get pipelineDescription =>
      'Diagrama das seis etapas de uma pergunta: Aceitar, Reunir com arquivos, memória e web em paralelo, Montar, Pensar, Responder e Salvar.';

  @override
  String get pause => 'Pausar';

  @override
  String get play => 'Reproduzir';

  @override
  String get memoryTitle => 'Memória com o Hippocampus';

  @override
  String get memoryScope =>
      'Toda memória tem um escopo: workspace, app e usuário. Uma busca nunca sai do escopo.';

  @override
  String get memorySearch =>
      'A busca por palavras e a busca semântica são unidas com Reciprocal Rank Fusion (RRF).';

  @override
  String get memoryPersonas =>
      'Personas: quem você é, uma voz de bot para a conversa e pessoas que você cita na pergunta.';

  @override
  String get memoryRepo => 'Repositório do Hippocampus';

  @override
  String get scopeDescription =>
      'Árvore de um escopo de memória: um workspace contém apps, e um app contém usuários.';

  @override
  String get graphDescription =>
      'Exemplo de grafo de memória: memórias ligadas a tags, entidades e arquivos.';

  @override
  String get webTitle => 'Pesquisa na web';

  @override
  String get webMode => 'Modo';

  @override
  String get webQueries => 'Buscas';

  @override
  String get webPages => 'Páginas';

  @override
  String get webDepth => 'Profundidade de links';

  @override
  String get webTime => 'Limite de tempo';

  @override
  String get webFast => 'Rápida';

  @override
  String get webMedium => 'Média';

  @override
  String get webDeep => 'Profunda';

  @override
  String get webFastPages => '5';

  @override
  String get webMediumPages => '5 por nível';

  @override
  String get webMethod =>
      'As páginas são cortadas em trechos de cerca de 500 tokens e ordenadas com BM25 e RRF. O texto da web não usa embeddings, e as fontes ficam separadas da sua memória.';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get liveTitle => 'Controle ao vivo';

  @override
  String get liveSteps =>
      'Etapas ao vivo: cada etapa é transmitida quando acontece.';

  @override
  String get liveReconnect =>
      'Reconexão: a resposta continua no servidor, e você pode voltar a ela.';

  @override
  String get liveStop =>
      'Parar: você pode parar uma resposta a qualquer momento.';

  @override
  String get liveStopThinking =>
      'Parar o raciocínio: ir para a resposta final com as notas até agora.';

  @override
  String get engTitle => 'Engenharia';

  @override
  String get engMachines =>
      'Máquinas locais em uma rede: a GPU do MSI executa o modelo de linguagem, o Pong executa embeddings, o FSM guarda os arquivos e um servidor de banco guarda os dados.';

  @override
  String get engRust =>
      'As APIs do Cortex e do Hippocampus são escritas em Rust.';

  @override
  String get engLocal =>
      'Somente modelos locais. Nenhum modelo de linguagem na nuvem.';

  @override
  String get machinesDescription =>
      'Diagrama das máquinas: a API do Cortex envia chamadas de modelo à GPU do MSI e chamadas de memória ao Hippocampus, que usa o Pong para embeddings, o FSM para arquivos e o servidor de banco.';

  @override
  String get codeTitle => 'Código real';

  @override
  String get codeRrf => 'Reciprocal Rank Fusion das listas de busca na web';

  @override
  String get codeGather => 'Arquivos, memória e web reunidos ao mesmo tempo';

  @override
  String get codeNames => 'Busca de tags dentro de um escopo';

  @override
  String get researchTitle => 'Base de pesquisa';

  @override
  String get securityTitle => 'Segurança e privacidade';

  @override
  String get securityShield =>
      'Toda entrada passa por uma verificação de segurança com regras fixas e um classificador antes de qualquer gravação.';

  @override
  String get securityIsolation =>
      'Cada usuário vê apenas suas próprias conversas, arquivos e memórias, em cada app.';

  @override
  String get securityLogs =>
      'Logs e registros de execução não guardam texto das conversas.';

  @override
  String get faqLoginQ => 'Preciso de uma conta?';

  @override
  String get faqLoginA =>
      'Sim. Você entra com sua conta Asodya antes da primeira conversa.';

  @override
  String get faqModelQ => 'Qual modelo responde?';

  @override
  String get faqModelA =>
      'Um modelo de texto local, e um modelo de visão local quando você envia uma imagem.';

  @override
  String get faqDataQ => 'Onde ficam meus dados?';

  @override
  String get faqDataA =>
      'Nas máquinas da Asodya: conversas no banco, memórias no Hippocampus e arquivos no FSM.';

  @override
  String get faqTempQ => 'O que é uma conversa temporária?';

  @override
  String get faqTempA =>
      'Uma conversa que não é salva: termina após uma hora ou quando você a fecha, e não cria memória.';

  @override
  String get faqLangQ => 'Quais idiomas?';

  @override
  String get faqLangA => 'O app está em inglês, português e tailandês.';

  @override
  String get finalLine => 'Faça sua primeira pergunta.';

  @override
  String version(String v) {
    return 'Versão $v';
  }

  @override
  String get logoDescription => 'Logo do Cortex';

  @override
  String get chatGreeting => 'O que você quer saber?';

  @override
  String get composerHint => 'Escreva uma mensagem';

  @override
  String get attach => 'Anexar arquivos';

  @override
  String get webLabel => 'Web';

  @override
  String get webOff => 'Desligada';

  @override
  String get memoryToggle => 'Memória';

  @override
  String get topicHint => 'Tópico (opcional)';

  @override
  String get thinkingToggle => 'Raciocínio';

  @override
  String get personaPicker => 'Persona do bot';

  @override
  String get noPersona => 'Sem persona';

  @override
  String get send => 'Enviar';

  @override
  String get stop => 'Parar';

  @override
  String get stopThinking => 'Parar o raciocínio';

  @override
  String usuallyAbout(int n) {
    return 'Normalmente cerca de $n s';
  }

  @override
  String elapsed(int n) {
    return '$n s';
  }

  @override
  String get stagesTimeline => 'Etapas';

  @override
  String get thinkingSection => 'Raciocínio';

  @override
  String get rolePlan => 'Plano';

  @override
  String get roleWork => 'Trabalho';

  @override
  String get roleCheck => 'Verificação';

  @override
  String get roleNotes => 'Notas';

  @override
  String roundN(int n) {
    return 'rodada $n';
  }

  @override
  String usedMemories(int n) {
    return 'Usou $n memórias';
  }

  @override
  String get copy => 'Copiar';

  @override
  String get copied => 'Copiado';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get jumpToLatest => 'Ir para o mais recente';

  @override
  String get reconnecting => 'Reconectando...';

  @override
  String get rename => 'Renomear';

  @override
  String get pin => 'Fixar';

  @override
  String get unpin => 'Desafixar';

  @override
  String get delete => 'Excluir';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get deleteChatTitle => 'Excluir esta conversa?';

  @override
  String get deleteChatMessage =>
      'A conversa e suas memórias serão excluídas. Isso não pode ser desfeito.';

  @override
  String tokenCounter(int n, int max) {
    return '$n de $max tokens';
  }

  @override
  String get overLimit => 'A mensagem passa do limite de entrada.';

  @override
  String get uploading => 'Enviando';

  @override
  String statsLine(String time, String s, int input, int output) {
    return '$time · $s s · $input entrada, $output saída tokens';
  }

  @override
  String get cancelledLine => 'Parado';

  @override
  String get steps_web_queries => 'Preparando as buscas';

  @override
  String get steps_queue_wait => 'Aguardando o modelo';

  @override
  String get steps_model_load => 'Carregando o modelo';

  @override
  String get steps_model_ready => 'O modelo está pronto';

  @override
  String get steps_security_ok => 'Verificação de segurança OK';

  @override
  String get steps_file_read_page => 'Lendo a página do arquivo';

  @override
  String get steps_file_ocr_page => 'Lendo a imagem da página';

  @override
  String get steps_file_transcribe => 'Transcrevendo o áudio';

  @override
  String get steps_memory_search => 'Buscando na sua memória';

  @override
  String get steps_memory_found => 'Memórias encontradas';

  @override
  String get steps_web_search => 'Buscando na web';

  @override
  String get steps_web_page_read => 'Lendo a página';

  @override
  String get steps_chunks_selected => 'Trechos selecionados';

  @override
  String get steps_thinking_step => 'Etapa de raciocínio';

  @override
  String get steps_thinking_stopped => 'Raciocínio parado pelo usuário';

  @override
  String get temporaryBanner =>
      'Temporária: não é salva e se perde ao recarregar.';

  @override
  String get justNow => 'Agora';

  @override
  String minutesAgo(int n) {
    return '$n min atrás';
  }

  @override
  String hoursAgo(int n) {
    return '$n h atrás';
  }

  @override
  String daysAgo(int n) {
    return '$n d atrás';
  }

  @override
  String get running => 'Em andamento';

  @override
  String get chatActions => 'Ações da conversa';

  @override
  String get deleteFailed => 'A conversa não foi excluída.';

  @override
  String get chatsLoadFailed => 'Não foi possível carregar as conversas.';

  @override
  String get graphView => 'Grafo';

  @override
  String get listView => 'Lista';

  @override
  String get depthLabel => 'Profundidade';

  @override
  String get limitLabel => 'Limite';

  @override
  String get legendMemory => 'Memória';

  @override
  String get legendTag => 'Tag';

  @override
  String get legendEntity => 'Entidade';

  @override
  String get legendFile => 'Arquivo';

  @override
  String get noMemories => 'Nenhuma memória ainda';

  @override
  String get memoryLoadFailed => 'Não foi possível carregar a memória.';

  @override
  String get memoryNotFound => 'Esta memória não foi encontrada.';

  @override
  String get superseded => 'Substituída';

  @override
  String get detailsLabel => 'Detalhes';

  @override
  String get linkedFiles => 'Arquivos';

  @override
  String get linkedMemories => 'Memórias ligadas';

  @override
  String get typeChat => 'Conversa';

  @override
  String get typeFile => 'Arquivo';

  @override
  String get typeNote => 'Nota';

  @override
  String get graphTruncated =>
      'Só parte do grafo aparece. Aumente o limite para ver mais.';

  @override
  String get memoryGraphDescription =>
      'Grafo da memória. A lista mostra os mesmos nós em texto.';

  @override
  String get legendPersona => 'Persona';

  @override
  String get linkedPersonas => 'Personas vinculadas';

  @override
  String get searchPersonas => 'Buscar personas';

  @override
  String get allPersonaTypes => 'Todos os tipos';

  @override
  String get personType => 'Pessoa';

  @override
  String get botType => 'Bot';

  @override
  String get you => 'Você';

  @override
  String get noPersonas => 'Nenhuma persona ainda';

  @override
  String get personasLoadFailed => 'Não foi possível carregar as personas.';

  @override
  String get personaFormFailed =>
      'Não foi possível carregar o formulário da persona.';

  @override
  String get personaSaveFailed =>
      'Não foi possível salvar a persona. Confira os campos marcados.';

  @override
  String get editPersona => 'Editar persona';

  @override
  String get personaType => 'Tipo';

  @override
  String get personaName => 'Nome';

  @override
  String get personaAliases => 'Apelidos';

  @override
  String get personaIsSelf => 'Esta persona é você';

  @override
  String get personaRequiredLegend => '* Campo obrigatório';

  @override
  String get personaSaved => 'Persona salva';

  @override
  String get deletePersona => 'Excluir persona';

  @override
  String get deletePersonaConfirm => 'Excluir esta persona e seus atributos?';

  @override
  String get personaFieldRequired => 'Este campo é obrigatório.';

  @override
  String get personaFieldUnknown =>
      'Este campo não faz parte do esquema salvo.';

  @override
  String get personaFieldType => 'Use o tipo indicado para este campo.';

  @override
  String get personaFieldInvalid => 'Confira este campo.';

  @override
  String get addPersonaItem => 'Adicionar item';

  @override
  String get removePersonaItem => 'Remover item';

  @override
  String get choosePersonaDate => 'Escolher uma data';

  @override
  String get clear => 'Limpar';

  @override
  String get personaYes => 'Sim';

  @override
  String get personaNo => 'Não';

  @override
  String get personaInteger => 'Número inteiro';

  @override
  String get personaNumber => 'Número';

  @override
  String get personaActionFailed =>
      'Não foi possível concluir a ação. Tente novamente.';

  @override
  String get usageLoadFailed => 'Não foi possível carregar o uso.';

  @override
  String get notAvailableYet => 'Ainda não disponível';

  @override
  String usageWindow(int hours) {
    return 'Seu uso nas últimas $hours horas';
  }

  @override
  String get usageInputTokens => 'Tokens de entrada';

  @override
  String get usageOutputTokens => 'Tokens de saída';

  @override
  String get usageTotalTokens => 'Total de tokens';

  @override
  String get usageImages => 'Imagens';

  @override
  String get usageAudio => 'Itens de áudio';

  @override
  String get usagePriority => 'Sua prioridade';

  @override
  String get usagePriorityHelp =>
      'A próxima chamada ao modelo vai para a pessoa na fila com o menor uso de tokens dividido pelo seu peso. Uma chamada já iniciada termina normalmente.';

  @override
  String get usageWeight => 'Peso';

  @override
  String get usageAccountAge => 'Parte da idade da conta';

  @override
  String get usageFrequency => 'Parte da frequência de acesso';

  @override
  String get usageAccountDays => 'Idade da conta em dias';

  @override
  String get usageSignInDays => 'Dias com acesso nos últimos 90 dias';

  @override
  String get usageWeightFormula =>
      'Peso = 1 + parte da idade da conta + parte da frequência de acesso.';

  @override
  String usageKind(String mode, String thinking) {
    return '$mode, $thinking';
  }

  @override
  String get usageThinkingOn => 'raciocínio ativado';

  @override
  String get usageThinkingOff => 'raciocínio desativado';

  @override
  String usageSeconds(String value) {
    return '$value s';
  }

  @override
  String get usageTimingHelp =>
      'Média das últimas 20 respostas concluídas de cada tipo. Respostas com falha ou canceladas não entram na média.';

  @override
  String get usageEmpty => 'Ainda não há registros de uso';

  @override
  String get usageMetric => 'Medida';

  @override
  String get usageRuns => 'Total de respostas';

  @override
  String get usageAverageTime => 'Tempo médio';

  @override
  String get usageAverageInput => 'Média de tokens de entrada';

  @override
  String get usageAverageOutput => 'Média de tokens de saída';

  @override
  String get usageAverageTotal => 'Média do total de tokens';

  @override
  String get usageSuccessRate => 'Taxa de sucesso';

  @override
  String get usageRequest => 'ID da requisição';

  @override
  String get usageOutput => 'ID da resposta';

  @override
  String get usageUser => 'Usuário';

  @override
  String get usageModel => 'Modelo';

  @override
  String get usageRole => 'Função';

  @override
  String get usageStarted => 'Início';

  @override
  String get usageFinished => 'Fim';

  @override
  String get usageNoUser => 'Sem usuário';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get loading => 'Carregando';

  @override
  String get process1001 => 'A rota não foi encontrada.';

  @override
  String get process1002 => 'O método não é permitido.';

  @override
  String get process1003 => 'Os dados da requisição não são válidos.';

  @override
  String get process1004 => 'O corpo JSON não é válido.';

  @override
  String get process1005 => 'Entre na sua conta para continuar.';

  @override
  String get process1006 => 'O tipo de conteúdo não é compatível.';

  @override
  String get process1007 => 'A requisição é grande demais.';

  @override
  String get process1008 => 'O servidor não conseguiu concluir a requisição.';

  @override
  String get process1009 => 'Este aplicativo não é permitido.';

  @override
  String get process1010 =>
      'O servidor está com muita carga. Tente mais tarde.';

  @override
  String get process1011 => 'A fila de chamadas locais falhou.';

  @override
  String get process1012 => 'A chamada ao modelo local falhou.';

  @override
  String get process1201 => 'A entrada ultrapassa o limite de tokens.';

  @override
  String get process1013 => 'Os dados de uso não estão disponíveis.';

  @override
  String get process1014 => 'Você está brincando comigo, palhaço?';

  @override
  String get process1015 => 'A verificação de segurança não está disponível.';

  @override
  String get process1016 => 'A conversa não foi encontrada.';

  @override
  String get process1017 => 'Não foi possível carregar ou alterar o histórico.';

  @override
  String get process1018 => 'A resposta não foi encontrada.';

  @override
  String get process1019 => 'Não foi possível salvar a memória da conversa.';

  @override
  String get process1020 => 'A pesquisa na web não está disponível.';

  @override
  String get process1021 => 'A página excedeu o tempo de espera.';

  @override
  String get process1022 => 'A página ultrapassa o limite de tamanho.';

  @override
  String get process1023 => 'A página não é HTML.';

  @override
  String get process1024 => 'Não foi possível ler a página.';

  @override
  String get process1025 => 'A página não tem texto principal legível.';

  @override
  String get process1026 => 'O limite de tempo da pesquisa foi atingido.';

  @override
  String get process1027 => 'O limite de páginas foi atingido.';

  @override
  String get process1028 =>
      'Não foi possível carregar as regras de rastreamento.';

  @override
  String get process1029 => 'Não foi possível carregar a memória.';

  @override
  String get process1030 => 'O tipo de arquivo não é compatível.';

  @override
  String get process1031 => 'O arquivo ultrapassa o limite de tamanho.';

  @override
  String get process1032 => 'Não foi possível ler o texto do arquivo.';

  @override
  String get process1033 =>
      'O arquivo ultrapassa o limite de páginas para OCR.';

  @override
  String get process1034 => 'Não foi possível ler o texto da imagem.';

  @override
  String get process1035 =>
      'O armazenamento de conversas temporárias não está disponível.';

  @override
  String get process1036 => 'O limite de tempo do raciocínio foi atingido.';

  @override
  String get process1037 =>
      'O fluxo de logs está disponível apenas na rede local.';

  @override
  String get process1038 => 'Não foi possível carregar os dados de telemetria.';

  @override
  String get process1039 => 'O nó de memória não foi encontrado.';

  @override
  String get process1040 => 'O arquivo não foi salvo.';

  @override
  String get process1041 => 'O arquivo não foi encontrado.';

  @override
  String get process1042 => 'Os eventos da resposta não estão disponíveis.';

  @override
  String get process1043 => 'A resposta não está em execução.';

  @override
  String get process1044 => 'Não foi possível excluir as memórias da conversa.';

  @override
  String get process1045 => 'A persona não foi encontrada.';

  @override
  String get process1046 => 'Os dados da persona não são válidos.';

  @override
  String get process1047 => 'Não foi possível carregar ou alterar as personas.';

  @override
  String get process1048 => 'O áudio ultrapassa o limite de 10 minutos.';

  @override
  String get process1049 => 'Não foi possível transcrever o áudio.';

  @override
  String get process1050 => 'O processo de arquivos não respondeu.';

  @override
  String processUnknown(int number) {
    return 'Ocorreu um problema ($number).';
  }

  @override
  String get processGeneric => 'Ocorreu um problema. Tente novamente.';

  @override
  String get networkOffline =>
      'Você está offline. Confira sua conexão e tente novamente.';

  @override
  String get stepUnknown => 'Em andamento';

  @override
  String get statusStarted => 'Iniciado';

  @override
  String get statusDone => 'Concluído';

  @override
  String get statusFailed => 'Falhou';

  @override
  String get statusCancelled => 'Cancelado';

  @override
  String get statusSkipped => 'Ignorado';

  @override
  String get expandThinking => 'Expandir raciocínio';

  @override
  String get collapseThinking => 'Recolher raciocínio';
}
