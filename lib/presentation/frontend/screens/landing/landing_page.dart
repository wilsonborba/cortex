import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/settings.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../preferences.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';
import 'code_snippet.dart';
import 'demo.dart';
import 'diagrams.dart';

const hippocampusRepo = 'https://github.com/wilsonborba/hippocampus';
const asodyaSite = 'https://asodya.com';

/// Research basis of 24.B.2.h, from the area 5, 6, 9 and 11 records.
const research = [
  (
    'Lost in the Middle',
    'Liu et al., TACL 2024',
    'https://arxiv.org/abs/2307.03172',
  ),
  ('RECOMP', 'Xu, Shi, Choi, ICLR 2024', 'https://arxiv.org/abs/2310.04408'),
  (
    'Corrective RAG (CRAG)',
    'Yan et al., 2024',
    'https://arxiv.org/abs/2401.15884',
  ),
  (
    'Reciprocal Rank Fusion',
    'Cormack, Clarke, Buttcher, SIGIR 2009',
    'https://doi.org/10.1145/1571941.1572114',
  ),
  (
    'Distracted by irrelevant context',
    'Shi et al., ICML 2023',
    'https://arxiv.org/abs/2302.00093',
  ),
  (
    'Benchmarking LLMs in RAG',
    'Chen et al., AAAI 2024',
    'https://arxiv.org/abs/2309.01431',
  ),
  (
    'Same Task, More Tokens',
    'Levy, Jacoby, Goldberg, ACL 2024',
    'https://aclanthology.org/2024.acl-long.818/',
  ),
  (
    'Sensitivity to prompt formatting',
    'Sclar et al., ICLR 2024',
    'https://arxiv.org/abs/2310.11324',
  ),
  (
    'Let Me Speak Freely?',
    'Tam et al., 2024',
    'https://arxiv.org/abs/2408.02442',
  ),
  (
    'LLMs cannot self-correct reasoning yet',
    'Huang et al., ICLR 2024',
    'https://arxiv.org/abs/2310.01798',
  ),
  (
    'Chain-of-Verification',
    'Dhuliawala et al., 2023',
    'https://arxiv.org/abs/2309.11495',
  ),
];

enum LandingSection { product, howItWorks, memory, engineering, faq }

extension _LandingSectionX on LandingSection {
  /// Existing public paths, one subject per page (owner correction #43).
  String get path => switch (this) {
    LandingSection.product => '/v1/home',
    LandingSection.howItWorks => '/v1/home/how-it-works',
    LandingSection.memory => '/v1/home/memory',
    LandingSection.engineering => '/v1/home/engineering',
    LandingSection.faq => '/v1/home/faq',
  };
  static LandingSection? fromSlug(String? slug) => switch (slug) {
    'how-it-works' => LandingSection.howItWorks,
    'memory' => LandingSection.memory,
    'engineering' => LandingSection.engineering,
    'faq' => LandingSection.faq,
    _ => null,
  };
  String label(AppLocalizations l) => switch (this) {
    LandingSection.product => l.product,
    LandingSection.howItWorks => l.howItWorks,
    LandingSection.memory => l.memory,
    LandingSection.engineering => l.engineering,
    LandingSection.faq => l.faq,
  };
}

/// Public subject pages with shared navigation and localized content.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key, required this.onSignIn, this.section});
  final VoidCallback onSignIn;
  final String? section;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    final current =
        _LandingSectionX.fromSlug(this.section) ?? LandingSection.product;
    void go(LandingSection subject) => context.go(subject.path);
    Widget section(LandingSection? key, String title, Widget body) => Padding(
      key: key == null ? null : ValueKey(key),
      padding: const EdgeInsets.only(top: Space.section),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: TextStyles.section),
          ),
          const SizedBox(height: Space.s24),
          body,
        ],
      ),
    );
    return Scaffold(
      body: Column(
        children: [
          LandingHeader(size: size, onSignIn: onSignIn, onSection: go),
          Expanded(
            child: GridBackground(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Space.contentMaxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Space.s24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (current == LandingSection.product) ...[
                            _Hero(
                              size: size,
                              onSignIn: onSignIn,
                              onHow: () => go(LandingSection.howItWorks),
                            ),
                            section(null, l.whatTitle, _What(size: size)),
                          ],
                          if (current == LandingSection.howItWorks)
                            section(
                              LandingSection.howItWorks,
                              l.pipelineTitle,
                              const PipelineDiagram(),
                            ),
                          if (current == LandingSection.memory)
                            section(
                              LandingSection.memory,
                              l.memoryTitle,
                              _Memory(size: size),
                            ),
                          if (current == LandingSection.howItWorks) ...[
                            section(null, l.webTitle, const _Web()),
                            section(
                              null,
                              l.liveTitle,
                              _Bullets([
                                l.liveSteps,
                                l.liveReconnect,
                                l.liveStop,
                                l.liveStopThinking,
                              ]),
                            ),
                          ],
                          if (current == LandingSection.engineering) ...[
                            section(
                              LandingSection.engineering,
                              l.engTitle,
                              const _Engineering(),
                            ),
                            section(null, l.researchTitle, const _Research()),
                            section(
                              null,
                              l.securityTitle,
                              _Bullets([
                                l.securityShield,
                                l.securityIsolation,
                                l.securityLogs,
                              ]),
                            ),
                          ],
                          if (current == LandingSection.faq)
                            section(LandingSection.faq, l.faq, const _Faq()),
                          if (current == LandingSection.product)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: Space.section,
                              ),
                              child: Flex(
                                key: const Key('landing-final-action'),
                                direction: size == SizeClass.compact
                                    ? Axis.vertical
                                    : Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (size == SizeClass.compact)
                                    Text(l.finalLine, style: TextStyles.section)
                                  else
                                    Expanded(
                                      child: Text(
                                        l.finalLine,
                                        style: TextStyles.section,
                                      ),
                                    ),
                                  const SizedBox(
                                    width: Space.s16,
                                    height: Space.s16,
                                  ),
                                  AppButton.primary(
                                    label: l.startChat,
                                    onPressed: onSignIn,
                                  ),
                                ],
                              ),
                            ),
                          const _Footer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LandingHeader extends StatelessWidget {
  const LandingHeader({
    super.key,
    required this.size,
    required this.onSignIn,
    required this.onSection,
  });
  final SizeClass size;
  final VoidCallback onSignIn;
  final ValueChanged<LandingSection> onSection;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final prefs = PreferencesScope.maybeOf(context);
    // Five links fit only on the expanded width; medium and compact use a menu.
    final compact = size != SizeClass.expanded;
    return Container(
      key: const Key('landing-header'),
      height: 64,
      padding: EdgeInsets.symmetric(
        horizontal: size == SizeClass.compact ? Space.s16 : Space.s24,
      ),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          Semantics(
            label: l.logoDescription,
            image: true,
            child: Image.asset(
              'lib/presentation/frontend/assets/img/logo.png',
              width: 28,
              height: 28,
              excludeFromSemantics: true,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: Space.s8),
            Text('Cortex', style: TextStyles.subsection),
            const SizedBox(width: Space.s24),
            Expanded(
              child: SingleChildScrollView(
                key: const Key('header-links'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final section in LandingSection.values)
                      TextButton(
                        key: Key('link-${section.name}'),
                        onPressed: () => onSection(section),
                        child: Text(
                          section.label(l),
                          style: TextStyles.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Space.s16),
          ] else
            const SizedBox(width: Space.s8),
          if (size != SizeClass.compact && prefs != null) ...[
            PopupMenuButton<Locale>(
              tooltip: l.language,
              icon: const Icon(Icons.translate),
              onSelected: (v) => prefs.locale = v,
              itemBuilder: (_) => [
                for (final (code, name) in [
                  ('en', 'English'),
                  ('pt', 'Português'),
                  ('th', 'ไทย'),
                ])
                  PopupMenuItem(value: Locale(code), child: Text(name)),
              ],
            ),
            IconButton(
              tooltip: l.themeSwitch,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () =>
                  prefs.theme = Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ],
          if (compact)
            PopupMenuButton<LandingSection>(
              key: const Key('section-menu'),
              tooltip: l.menu,
              icon: const Icon(Icons.menu),
              onSelected: onSection,
              itemBuilder: (_) => [
                for (final s in LandingSection.values)
                  PopupMenuItem(value: s, child: Text(s.label(l))),
              ],
            ),
          const SizedBox(width: Space.s8),
          if (compact)
            Expanded(
              child: AppButton(label: l.logIn, onPressed: onSignIn),
            )
          else
            AppButton(label: l.logIn, onPressed: onSignIn),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.size,
    required this.onSignIn,
    required this.onHow,
  });
  final SizeClass size;
  final VoidCallback onSignIn;
  final VoidCallback onHow;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.heroLabel, style: TextStyles.label.copyWith(color: p.muted)),
        const SizedBox(height: Space.s12),
        Semantics(
          header: true,
          child: Text(
            l.heroTitle,
            style: size == SizeClass.compact
                ? TextStyles.pageTitle
                : TextStyles.display,
          ),
        ),
        const SizedBox(height: Space.s16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l.heroLead,
            style: TextStyles.body.copyWith(color: p.muted),
          ),
        ),
        const SizedBox(height: Space.s24),
        Wrap(
          spacing: Space.s12,
          runSpacing: Space.s12,
          children: [
            AppButton.primary(
              key: const Key('start-chat'),
              label: l.startChat,
              onPressed: onSignIn,
            ),
            AppButton(label: l.seeHow, onPressed: onHow),
          ],
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: Space.s48),
      child: size == SizeClass.expanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: Space.s32),
                const Expanded(child: ChatDemo()),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                const SizedBox(height: Space.s32),
                const ChatDemo(),
              ],
            ),
    );
  }
}

class _What extends StatelessWidget {
  const _What({required this.size});
  final SizeClass size;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    Widget block(String title, String text, Widget ui) => SizedBox(
      width: size == SizeClass.compact ? double.infinity : 270,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyles.subsection),
            const SizedBox(height: Space.s8),
            Text(text, style: TextStyles.compact.copyWith(color: p.muted)),
            const SizedBox(height: Space.s12),
            ui,
          ],
        ),
      ),
    );
    return Wrap(
      spacing: Space.s16,
      runSpacing: Space.s16,
      children: [
        block(
          l.whatMemory,
          l.whatMemoryText,
          Wrap(
            spacing: Space.s8,
            children: [
              Chip(label: Text('tag: cortex')),
              Chip(label: Text(l.usedMemories(2))),
            ],
          ),
        ),
        block(
          l.whatWeb,
          l.whatWebText,
          Wrap(
            spacing: Space.s8,
            children: [
              AppChip(label: l.webFast, selected: true, onSelected: (_) {}),
              AppChip(label: l.webMedium, onSelected: (_) {}),
              AppChip(label: l.webDeep, onSelected: (_) {}),
            ],
          ),
        ),
        block(
          l.whatFiles,
          l.whatFilesText,
          const Wrap(
            spacing: Space.s8,
            children: [
              Chip(
                avatar: Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text('report.pdf'),
              ),
              Chip(
                avatar: Icon(Icons.graphic_eq, size: 16),
                label: Text('note.ogg'),
              ),
            ],
          ),
        ),
        block(
          l.whatThinking,
          l.whatThinkingText,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in [l.rolePlan, l.roleWork, l.roleCheck])
                NoticeLine(message: '${l.stepThinking}: $r'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Memory extends StatelessWidget {
  const _Memory({required this.size});
  final SizeClass size;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Bullets([l.memoryScope, l.memorySearch, l.memoryPersonas]),
        const SizedBox(height: Space.s16),
        const ScopeTree(),
        const SizedBox(height: Space.s16),
        AppButton(
          key: const Key('hippocampus-link'),
          label: l.memoryRepo,
          icon: Icons.open_in_new,
          onPressed: () => launchUrl(Uri.parse(hippocampusRepo)),
        ),
      ],
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.example, style: TextStyles.label),
        const ExampleGraph(),
        const SizedBox(height: Space.s16),
        CodeSnippet(
          asset:
              'lib/presentation/frontend/assets/snippets/scoped_names.rs.txt',
          path: 'hippocampus/src/dal/local/scoped_graph.rs',
          caption: l.codeNames,
        ),
      ],
    );
    return size == SizeClass.expanded
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: Space.s32),
              Expanded(child: right),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              left,
              const SizedBox(height: Space.s24),
              right,
            ],
          );
  }
}

class _Web extends StatelessWidget {
  const _Web();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    // Values of cortex_api config.rs (areas 4 and 5).
    final rows = [
      [l.webFast, '1', l.webFastPages, '0', l.seconds(15)],
      [l.webMedium, '3', l.webMediumPages, '1', l.seconds(30)],
      [l.webDeep, '4', l.webMediumPages, '2', l.seconds(60)],
    ];
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: Space.s8,
              horizontal: Space.s8,
            ),
            child: Text(
              c,
              style: head
                  ? TextStyles.label.copyWith(color: p.muted)
                  : TextStyles.compact,
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          key: const Key('web-table'),
          children: [
            row([
              l.webMode,
              l.webQueries,
              l.webPages,
              l.webDepth,
              l.webTime,
            ], head: true),
            for (final r in rows) row(r),
          ],
        ),
        const SizedBox(height: Space.s16),
        Text(l.webMethod, style: TextStyles.body.copyWith(color: p.muted)),
        const SizedBox(height: Space.s16),
        CodeSnippet(
          asset: 'lib/presentation/frontend/assets/snippets/rrf.rs.txt',
          path: 'cortex_api/src/domain/services/search.rs',
          caption: l.codeRrf,
        ),
      ],
    );
  }
}

class _Engineering extends StatelessWidget {
  const _Engineering();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Bullets([l.engMachines, l.engRust, l.engLocal]),
        const SizedBox(height: Space.s16),
        const MachinesDiagram(),
        const SizedBox(height: Space.s24),
        CodeSnippet(
          asset: 'lib/presentation/frontend/assets/snippets/gather.rs.txt',
          path: 'cortex_api/src/domain/services/pipeline.rs',
          caption: l.codeGather,
        ),
      ],
    );
  }
}

class _Research extends StatelessWidget {
  const _Research();
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, who, url) in research)
          InkWell(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: TextStyles.compact.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: '  $who',
                      style: TextStyles.compact.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    return Column(
      children: [
        for (final (q, a) in [
          (l.faqLoginQ, l.faqLoginA),
          (l.faqModelQ, l.faqModelA),
          (l.faqDataQ, l.faqDataA),
          (l.faqTempQ, l.faqTempA),
          (l.faqLangQ, l.faqLangA),
        ])
          ExpansionTile(
            title: Text(q, style: TextStyles.body),
            shape: const Border(),
            childrenPadding: const EdgeInsets.only(
              left: Space.s16,
              right: Space.s16,
              bottom: Space.s16,
            ),
            expandedAlignment: Alignment.centerLeft,
            children: [
              Text(a, style: TextStyles.compact.copyWith(color: p.muted)),
            ],
          ),
      ],
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets(this.items);
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9),
                    child: Container(width: 4, height: 4, color: p.text),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(child: Text(i, style: TextStyles.body)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    return Container(
      margin: const EdgeInsets.only(top: Space.section),
      padding: const EdgeInsets.symmetric(vertical: Space.s24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Wrap(
        spacing: Space.s24,
        runSpacing: Space.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse(asodyaSite)),
            child: const Text('Asodya'),
          ),
          TextButton(
            onPressed: () => launchUrl(Uri.parse(hippocampusRepo)),
            child: const Text('Hippocampus'),
          ),
          Text(l.builtBy, style: TextStyles.label.copyWith(color: p.muted)),
          Text(
            l.version(AppSettings.buildVersion),
            style: TextStyles.label.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}
