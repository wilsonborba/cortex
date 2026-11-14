import '../../theme/app_icons.dart';
import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
import 'engineering_page.dart';

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
          Semantics(header: true, child: Text(title, style: TextStyles.title3)),
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
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: Space.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s24),
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
                            const EngineeringContent(),
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
                            padding: const EdgeInsets.only(top: Space.section),
                            child: _FinalAction(size: size, onSignIn: onSignIn),
                          ),
                        const _Footer(),
                      ],
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
    final p = Palette.from(context);
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
        border: Border(bottom: BorderSide(color: p.divider)),
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
            Text('Cortex', style: TextStyles.subtitle1),
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
                        child: Text(section.label(l), style: TextStyles.body1),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: Space.s16),
          ] else
            const SizedBox(width: Space.s8),
          if (size != SizeClass.compact && prefs != null) ...[
            FoundationFocus(
              child: AppMenu<Locale>(
                tooltip: l.language,
                icon: const Icon(AppIcons.language),
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
            ),
            IconButton(
              tooltip: l.themeSwitch,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? AppIcons.lightTheme
                    : AppIcons.darkTheme,
              ),
              onPressed: () =>
                  prefs.theme = Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark,
            ),
          ],
          if (compact)
            FoundationFocus(
              child: AppMenu<LandingSection>(
                key: const Key('section-menu'),
                tooltip: l.menu,
                icon: const Icon(AppIcons.menu),
                onSelected: onSection,
                itemBuilder: (_) => [
                  for (final s in LandingSection.values)
                    PopupMenuItem(value: s, child: Text(s.label(l))),
                ],
              ),
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

/// The 11 landing images, bundled in `assets/images/` (#70). Placement
/// follows the owner order of 2026-11-14.
abstract final class LandingImages {
  static const _dir = 'assets/images';
  static const backdrop = '$_dir/aurora_backdrop_gradient_unsplash.webp';
  static const badge = '$_dir/hero_branding_badge_unsplash.webp';
  static const previewFrame = '$_dir/browser_frame_wireframe_pixabay.svg';
  static const cardSurface = '$_dir/glassmorphic_card_surface_pexels.webp';
  static const mobile = '$_dir/mobile_app_mockup_viewport_unsplash.webp';
  static const play = '$_dir/media_cta_button_freepik.svg';
  static const ctaTexture = '$_dir/mesh_ambient_wallpaper_pexels.webp';
  static const workflows = '$_dir/abstract_creativity_vector_undraw.svg';
  static const ideation = '$_dir/lightbulb_ideation_graphic_undraw.svg';
  static const multimodal = '$_dir/vision_concept_art_undraw.svg';
  static const performance = '$_dir/workflow_speed_glyph_freepik.svg';
}

/// Final call to action (#70): the mesh texture card with the mobile
/// companion preview, the last line and the primary button.
class _FinalAction extends StatelessWidget {
  const _FinalAction({required this.size, required this.onSignIn});
  final SizeClass size;
  final VoidCallback onSignIn;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final compact = size == SizeClass.compact;
    final mobile = ClipRRect(
      borderRadius: BorderRadius.circular(Radii.dialog),
      child: Image.asset(
        LandingImages.mobile,
        key: const Key('mobile-preview'),
        width: 96,
        height: 96,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      ),
    );
    final line = Text(
      l.finalLine,
      style: TextStyles.title3.copyWith(color: p.text),
    );
    final button = AppButton.primary(label: l.startChat, onPressed: onSignIn);
    return ClipRRect(
      key: const Key('landing-final-action'),
      borderRadius: BorderRadius.circular(Radii.dialog),
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: p.surface)),
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                LandingImages.ctaTexture,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.s24),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mobile,
                      const SizedBox(height: Space.s16),
                      line,
                      const SizedBox(height: Space.s16),
                      button,
                    ],
                  )
                : Row(
                    children: [
                      mobile,
                      const SizedBox(width: Space.s24),
                      Expanded(child: line),
                      const SizedBox(width: Space.s16),
                      button,
                    ],
                  ),
          ),
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
    final p = Palette.from(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero brand badge (#70, owner placement).
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.dialog),
          child: Image.asset(
            LandingImages.badge,
            key: const Key('hero-badge'),
            height: Space.s56,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(height: Space.s16),
        Text(l.heroLabel, style: TextStyles.caption1.copyWith(color: p.muted)),
        const SizedBox(height: Space.s12),
        Semantics(
          header: true,
          child: Text(
            l.heroTitle,
            style: size == SizeClass.expanded
                ? TextStyles.display
                : TextStyles.largeTitle,
          ),
        ),
        const SizedBox(height: Space.s16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l.heroLead,
            style: TextStyles.body1.copyWith(color: p.text2),
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
            // Secondary button with the demo play icon (#70).
            TextButton.icon(
              key: const Key('see-how'),
              style: buttonStyle(
                p,
                ButtonAppearance.secondary,
                size: ButtonSize.of(size),
              ),
              onPressed: onHow,
              icon: SvgPicture.asset(
                LandingImages.play,
                width: IconSizes.action,
                height: IconSizes.action,
                excludeFromSemantics: true,
                // The glyph is white; it takes the button text color.
                colorFilter: ColorFilter.mode(p.text, BlendMode.srcIn),
              ),
              label: Text(l.seeHow),
            ),
          ],
        ),
      ],
    );
    // The demo on the ambient backdrop, with the preview frame controls.
    final demo = ClipRRect(
      key: const Key('hero-visual'),
      borderRadius: BorderRadius.circular(Radii.dialog),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(LandingImages.backdrop),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Space.s20),
          child: Column(
            children: [
              const ChatDemo(),
              const SizedBox(height: Space.s12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SvgPicture.asset(
                  LandingImages.previewFrame,
                  excludeFromSemantics: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: Space.s48),
      child: size == SizeClass.expanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: text),
                const SizedBox(width: Space.s32),
                Expanded(child: demo),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                text,
                const SizedBox(height: Space.s32),
                demo,
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
    final p = Palette.from(context);
    // Feature cards (#70): Fluent card, radius 8, an illustration on top;
    // the first card has the glass surface texture.
    Widget block(
      String title,
      String text,
      Widget ui,
      String art, {
      bool primary = false,
    }) => SizedBox(
      width: size == SizeClass.compact ? double.infinity : 270,
      child: AppCard(
        radius: Radii.dialog,
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Radii.dialog),
          child: Stack(
            children: [
              if (primary)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.18,
                    child: Image.asset(
                      LandingImages.cardSurface,
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Space.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: Space.s56,
                      child: SvgPicture.asset(
                        art,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(height: Space.s12),
                    Text(
                      title,
                      style: TextStyles.subtitle2.copyWith(color: p.text),
                    ),
                    const SizedBox(height: Space.s8),
                    Text(
                      text,
                      style: TextStyles.body1.copyWith(color: p.text2),
                    ),
                    const SizedBox(height: Space.s12),
                    ui,
                  ],
                ),
              ),
            ],
          ),
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
              Chip(
                visualDensity: Controls.tagDensity,
                label: Text('tag: cortex'),
              ),
              Chip(
                visualDensity: Controls.tagDensity,
                label: Text(l.usedMemories(2)),
              ),
            ],
          ),
          LandingImages.workflows,
          primary: true,
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
          LandingImages.performance,
        ),
        block(
          l.whatFiles,
          l.whatFilesText,
          const Wrap(
            spacing: Space.s8,
            children: [
              Chip(
                visualDensity: Controls.tagDensity,
                avatar: Icon(AppIcons.file),
                label: Text('report.pdf'),
              ),
              Chip(
                visualDensity: Controls.tagDensity,
                avatar: Icon(AppIcons.activity),
                label: Text('note.ogg'),
              ),
            ],
          ),
          LandingImages.multimodal,
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
          LandingImages.ideation,
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
          icon: AppIcons.externalLink,
          onPressed: () => launchUrl(Uri.parse(hippocampusRepo)),
        ),
      ],
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.example, style: TextStyles.caption1),
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
    final p = Palette.from(context);
    // Values of cortex_api config.rs (areas 4 and 5).
    final rows = [
      [l.webFast, '1', l.webFastPages, '0', l.seconds(15)],
      [l.webMedium, '3', l.webMediumPages, '1', l.seconds(30)],
      [l.webDeep, '4', l.webMediumPages, '2', l.seconds(60)],
    ];
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.divider)),
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
                  ? TextStyles.caption1.copyWith(color: p.muted)
                  : TextStyles.body1,
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
        Text(l.webMethod, style: TextStyles.body2.copyWith(color: p.muted)),
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

class _Research extends StatelessWidget {
  const _Research();
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in [
          (AppLocalizations.of(context).engResearchContext, research.take(7)),
          (
            AppLocalizations.of(context).engResearchPrompts,
            research.skip(7).take(2),
          ),
          (AppLocalizations.of(context).engResearchReasoning, research.skip(9)),
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.s16, bottom: Space.s8),
            child: Text(group.$1, style: TextStyles.subtitle1),
          ),
          for (final (title, who, url) in group.$2)
            FoundationFocus(
              child: InkWell(
                onTap: () => launchUrl(Uri.parse(url)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Space.s4),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: TextStyles.body1.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(
                          text: '  $who',
                          style: TextStyles.body1.copyWith(color: p.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq();
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
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
            title: Text(q, style: TextStyles.body2),
            shape: const Border(),
            childrenPadding: const EdgeInsets.only(
              left: Space.s16,
              right: Space.s16,
              bottom: Space.s16,
            ),
            expandedAlignment: Alignment.centerLeft,
            children: [
              Text(a, style: TextStyles.body1.copyWith(color: p.muted)),
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
    final p = Palette.from(context);
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
                    // The 4 px dot is centered on the first text line.
                    padding: EdgeInsets.only(
                      top:
                          (TextStyles.body2.fontSize! *
                                  TextStyles.body2.height! -
                              Space.s4) /
                          2,
                    ),
                    child: Container(
                      width: Space.s4,
                      height: Space.s4,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(width: Space.s12),
                  Expanded(child: Text(i, style: TextStyles.body2)),
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
    final p = Palette.from(context);
    return Container(
      margin: const EdgeInsets.only(top: Space.section),
      padding: const EdgeInsets.symmetric(vertical: Space.s24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.divider)),
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
          Text(
            l.version(AppSettings.buildVersion),
            style: TextStyles.caption1.copyWith(color: p.muted),
          ),
        ],
      ),
    );
  }
}
