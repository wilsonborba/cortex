// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Cortex';

  @override
  String get landingTag => 'MVP NEURAL EXPERIMENTAL';

  @override
  String get landingHeroTitle => 'Inteligência sem distração.';

  @override
  String get landingHeroSubtitle =>
      'Um espaço experimental em estágio inicial para raciocínio focado e chat persistente. Criado para reflexão profunda com total privacidade.';

  @override
  String get getStarted => 'Começar';

  @override
  String get ssoAuthHint => '[ Logon Único • Requer Conta ]';

  @override
  String get aboutAsodya => 'Sobre a Asodya';

  @override
  String get logIn => 'Entrar';

  @override
  String get signUp => 'Cadastrar';

  @override
  String get footerWorkspace => 'ASODYA CORTEX // MVP EXPERIMENTAL (NÍVEL 0)';

  @override
  String get allRightsReserved =>
      '© 2026 ASODYA. TODOS OS DIREITOS RESERVADOS.';

  @override
  String get card1Number => '01 / ARQUITETURA';

  @override
  String get card1Title => 'Raciocínio Neural';

  @override
  String get card1Description =>
      'Transmissão contextual contínua alimentada por modelos leves de Nível 0 e parâmetros de execução isolados.';

  @override
  String get card2Number => '02 / INTEGRIDADE';

  @override
  String get card2Title => 'Privacidade por Padrão';

  @override
  String get card2Description =>
      'A telemetria do sistema é estritamente isolada na infraestrutura. Seus prompts e conversas permanecem privados.';

  @override
  String get card3Number => '03 / CONTINUIDADE';

  @override
  String get card3Title => 'Rascunhos Persistentes';

  @override
  String get card3Description =>
      'Cache local de rascunhos e recuperação resiliente de sessão em múltiplos dispositivos via autenticação Asodya SSO.';

  @override
  String get newConversation => 'Nova Conversa';

  @override
  String get history => 'HISTÓRICO';

  @override
  String get clearAll => 'Limpar Tudo';

  @override
  String get clearAllTitle => 'Limpar Todas as Conversas';

  @override
  String get clearAllConfirmation =>
      'Tem certeza de que deseja excluir permanentemente todas as conversas? Esta ação não pode ser desfeita.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get webResearchPill => 'Pesquisa Web';

  @override
  String get memoryEnginePill => 'Motor de Memória';

  @override
  String get attachTooltip => 'Anexar arquivos ou imagens';

  @override
  String get userBadgePro => 'PRO // ASODYA AUTH';

  @override
  String get tier0Badge => 'NÍVEL 0 // CORTEX-T0';

  @override
  String get collapseSidebar => 'Recolher barra lateral';

  @override
  String get expandSidebar => 'Expandir barra lateral';

  @override
  String get openSettings => 'Configurações';

  @override
  String get sessionOptions => 'Opções da sessão';

  @override
  String get tierZeroLabel => 'Nível 0 - Grátis e rápido';

  @override
  String get messageHint => 'Envie uma mensagem para o Cortex (Nível 0)...';

  @override
  String lockedFeatureNotice(String tier) {
    return '$tier: este recurso é liberado em um nível superior.';
  }

  @override
  String attachFileLocked(String tier) {
    return 'Anexar arquivo (bloqueado no $tier)';
  }

  @override
  String webBrowsingLocked(String tier) {
    return 'Navegação na web (bloqueada no $tier)';
  }

  @override
  String get memoryRecallOnTooltip =>
      'Memória ativada: esta resposta usará o /execute nativo do cortex_api com recuperação de memória no servidor';

  @override
  String get memoryRecallOffTooltip =>
      'Ativar recuperação de memória (/execute nativo)';

  @override
  String get memoryRecallTitle => 'Recuperação de memória';

  @override
  String get memoryRecallSubtitle =>
      'Usa o /execute nativo do cortex_api com recuperação de memória no servidor, disponível no Nível 0';

  @override
  String get webBrowsingTitle => 'Navegação na web';

  @override
  String get webBrowsingSubtitle =>
      'Fundamenta a resposta com uma busca na web, disponível no Nível 0';

  @override
  String get webSearchOnTooltip =>
      'Busca na web ativada: esta resposta será fundamentada com uma busca na web (needs_web)';

  @override
  String get webSearchOffTooltip =>
      'Ativar fundamentação por busca na web (needs_web)';

  @override
  String sourcesCount(int count) {
    return 'Fontes ($count)';
  }

  @override
  String get attachFile => 'Anexar um arquivo';

  @override
  String get attachImage => 'Imagem';

  @override
  String get attachDocument => 'Documento';

  @override
  String get removeAttachment => 'Remover anexo';

  @override
  String get documentAttachmentBackendGap =>
      'A ingestão de documentos ainda não é suportada pelo backend: hoje só imagens são aceitas.';

  @override
  String get voiceStartRecording => 'Gravar uma mensagem de voz';

  @override
  String get voiceCancelRecording => 'Cancelar gravação';

  @override
  String get voiceSendRecording => 'Enviar mensagem de voz';

  @override
  String get micPermissionDenied =>
      'O acesso ao microfone está indisponível ou foi negado.';

  @override
  String get voiceMessageTooShort =>
      'A gravação foi curta demais para ser enviada.';

  @override
  String get incognitoModeTitle => 'Chat incógnito';

  @override
  String get incognitoModeSubtitle =>
      'Sessão efêmera: nenhum histórico é salvo e a memória fica explicitamente desligada';

  @override
  String get newIncognitoChat => 'Iniciar chat incógnito';

  @override
  String get liveLogsTooltip => 'Logs ao vivo (somente desenvolvimento local)';

  @override
  String get liveLogsTitle => 'Logs ao vivo do Cortex';

  @override
  String get liveLogsDescription =>
      'Somente para desenvolvimento local: conecta diretamente ao /logs/stream do cortex_api, contornando o proxy do api_for_apps (que não suporta WebSocket).';

  @override
  String liveLogsConnectionError(String error) {
    return 'Não foi possível conectar: $error';
  }

  @override
  String get liveLogsWaiting => 'Aguardando linhas de log...';

  @override
  String couldNotSendMessage(String error) {
    return 'Não foi possível enviar a mensagem: $error';
  }

  @override
  String get scrollToBottomTooltip => 'Rolar até o fim';

  @override
  String get codeBlockPlainLabel => 'código';

  @override
  String get codeBlockCopyLabel => 'Copiar';

  @override
  String get codeBlockCopiedLabel => 'Copiado!';

  @override
  String get continueGenerationLabel => 'Continuar geração';

  @override
  String get continueGenerationTooltip =>
      'A conexão caiu no meio da resposta. Isso tenta a solicitação de novo, do zero (o cortex_api não consegue retomar uma resposta parcial), substituindo esta mensagem quando a nova resposta chegar.';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageThai => 'Tailandês';
}
