import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/surfaces.dart';

const cliRepositoryUrl = 'https://github.com/wilsonborba/cortex_cli';
const cliReadmeUrl = '$cliRepositoryUrl#readme';
const cliReleasesUrl = '$cliRepositoryUrl/releases';
const cliWebInstallerUrl = 'https://cortex.asodya.com/install.sh';
const cliReleaseInstallCommand =
    'curl -fsSL https://cortex.asodya.com/install.sh | bash';
const cliSourceInstallCommand =
    'git clone https://github.com/wilsonborba/cortex_cli.git\n'
    'cd cortex_cli\n'
    'cargo install --locked --path .';

/// Source-build instructions while owner-published release assets are absent.
class CliInstallSection extends StatelessWidget {
  const CliInstallSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return AppCard(
      key: const Key('cli-install-section'),
      radius: Radii.dialog,
      padding: const EdgeInsets.all(Space.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.cliTitle, style: TextStyles.title3.copyWith(color: p.text)),
          const SizedBox(height: Space.s8),
          Text(l.cliIntro, style: TextStyles.body2.copyWith(color: p.text2)),
          const SizedBox(height: Space.s24),
          Text(l.cliInstallTitle, style: TextStyles.subtitle1),
          const SizedBox(height: Space.s8),
          Text(l.cliInstallDetail, style: TextStyles.body2),
          TextButton(
            key: const Key('cli-web-installer-url'),
            style: TextButton.styleFrom(
              alignment: AlignmentDirectional.centerStart,
              padding: EdgeInsets.zero,
            ),
            onPressed: () => launchUrl(Uri.parse(cliWebInstallerUrl)),
            child: Text(cliWebInstallerUrl, softWrap: true),
          ),
          const SizedBox(height: Space.s12),
          _CommandBox(
            command: cliReleaseInstallCommand,
            copyLabel: l.cliCopy,
            containerKey: 'cli-install-command',
            commandKey: 'cli-install-command-text',
            copyKey: 'cli-copy-command',
          ),
          const SizedBox(height: Space.s8),
          Text(
            l.cliReleaseStatus,
            style: TextStyles.body2.copyWith(color: p.muted),
          ),
          const SizedBox(height: Space.s16),
          Text(l.cliSignIn, style: TextStyles.body1),
          const SizedBox(height: Space.s8),
          Text(
            l.cliProviderNote,
            style: TextStyles.body2.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s16),
          Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              AppButton(
                key: const Key('cli-readme-link'),
                label: l.cliReadme,
                icon: AppIcons.externalLink,
                onPressed: () => launchUrl(Uri.parse(cliReadmeUrl)),
              ),
              AppButton(
                key: const Key('cli-releases-link'),
                label: l.cliReleases,
                icon: AppIcons.externalLink,
                onPressed: () => launchUrl(Uri.parse(cliReleasesUrl)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AndroidInstallSection extends StatelessWidget {
  const AndroidInstallSection({super.key});

  static const androidHelpUrl =
      'https://support.google.com/android/answer/9457058?hl=en';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return AppCard(
      key: const Key('android-install-section'),
      radius: Radii.dialog,
      padding: const EdgeInsets.all(Space.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.androidInstallTitle,
            style: TextStyles.title3.copyWith(color: p.text),
          ),
          const SizedBox(height: Space.s8),
          Text(
            l.androidInstallDetail,
            style: TextStyles.body2.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s12),
          Text(
            l.androidReleaseStatus,
            style: TextStyles.body2.copyWith(color: p.muted),
          ),
          const SizedBox(height: Space.s16),
          Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              AppButton(
                key: const Key('android-download'),
                label: l.androidDownload,
                icon: AppIcons.file,
                onPressed: null,
              ),
              AppButton(
                key: const Key('android-install-help'),
                label: l.androidInstallHelp,
                icon: AppIcons.externalLink,
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l.androidHelpTitle),
                    content: Text(l.androidHelpDetail),
                    actions: [
                      TextButton(
                        key: const Key('android-official-help-link'),
                        onPressed: () => launchUrl(
                          Uri.parse(androidHelpUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Text(l.androidOfficialHelp),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(l.close),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommandBox extends StatelessWidget {
  const _CommandBox({
    required this.command,
    required this.copyLabel,
    this.containerKey = 'cli-install-command',
    this.commandKey = 'cli-install-command-text',
    this.copyKey = 'cli-copy-command',
  });

  final String command;
  final String copyLabel;
  final String containerKey;
  final String commandKey;
  final String copyKey;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Container(
      key: Key(containerKey),
      padding: const EdgeInsetsDirectional.only(
        start: Space.s12,
        top: Space.s8,
        bottom: Space.s8,
        end: Space.s4,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.stroke),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                command,
                key: Key(commandKey),
                style: TextStyles.caption1.copyWith(
                  color: p.text,
                  fontFamily: TextStyles.mono,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.s4),
          IconButton(
            key: Key(copyKey),
            tooltip: copyLabel,
            onPressed: () => Clipboard.setData(ClipboardData(text: command)),
            icon: const Icon(AppIcons.copy),
          ),
        ],
      ),
    );
  }
}
