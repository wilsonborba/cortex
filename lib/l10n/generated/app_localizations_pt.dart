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
  String get landingTagline =>
      'Um lugar calmo e monocromático para pensar em voz alta, com a cor correndo solta logo atrás.';

  @override
  String get signInWithAsodya => 'Entrar com a Asodya';

  @override
  String get continueAsGuest => 'Continuar como convidado';

  @override
  String get guestModeNotice =>
      'O modo convidado dispensa o login: é um atalho local, não uma conta Asodya.';

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
  String get messageHint => 'Envie uma mensagem para o Cortex...';

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
  String get webBrowsingSubtitle => 'Bloqueada no Nível 0';

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
