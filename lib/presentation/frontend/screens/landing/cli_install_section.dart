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
          Text(l.cliSourceTitle, style: TextStyles.subtitle1),
          const SizedBox(height: Space.s8),
          Text(l.cliSourceDetail, style: TextStyles.body2),
          const SizedBox(height: Space.s12),
          _CommandBox(command: cliSourceInstallCommand, copyLabel: l.cliCopy),
          const SizedBox(height: Space.s12),
          Text(l.cliLinuxPrerequisite, style: TextStyles.caption1),
          const SizedBox(height: Space.s16),
          Text(l.cliSignIn, style: TextStyles.body1),
          const SizedBox(height: Space.s8),
          Text(
            l.cliProviderNote,
            style: TextStyles.body2.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s16),
          Text(
            l.cliReleaseStatus,
            style: TextStyles.body2.copyWith(color: p.muted),
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

class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.command, required this.copyLabel});

  final String command;
  final String copyLabel;

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Container(
      key: const Key('cli-install-command'),
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
                key: const Key('cli-install-command-text'),
                style: TextStyles.caption1.copyWith(
                  color: p.text,
                  fontFamily: TextStyles.mono,
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.s4),
          IconButton(
            key: const Key('cli-copy-command'),
            tooltip: copyLabel,
            onPressed: () => Clipboard.setData(ClipboardData(text: command)),
            icon: const Icon(AppIcons.copy),
          ),
        ],
      ),
    );
  }
}
