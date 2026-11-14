import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';
import 'diagrams.dart' show DiagramCanvas;
import 'engineering_sources.dart';

typedef _Box = ({String name, String tech, String role});
_Box _box(String name, [String tech = '', String role = '']) =>
    (name: name, tech: tech, role: role);

/// Logical architecture and source-backed decisions. No deployment topology.
class EngineeringContent extends StatelessWidget {
  const EngineeringContent({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final api = _box(l.engApi, l.engTechRust, l.engApiRole);
    final memory = _box(l.engMemoryService, l.engTechRust, l.engMemoryRole);
    Widget heading(String key, String title) => Padding(
      padding: const EdgeInsets.only(top: Space.s40, bottom: Space.s16),
      child: Text(title, key: Key(key), style: TextStyles.subtitle1),
    );
    final decisions = [
      (l.engRustTitle, l.engRustContext, l.engRustDecision, l.engRustResult),
      (
        l.engJournalTitle,
        l.engJournalContext,
        l.engJournalDecision,
        l.engJournalResult,
      ),
      (
        l.engGatherTitle,
        l.engGatherContext,
        l.engGatherDecision,
        l.engGatherResult,
      ),
      (
        l.engMemoryTitle,
        l.engMemoryContext,
        l.engMemoryDecision,
        l.engMemoryResult,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.engIntro,
          key: const Key('engineering-intro'),
          style: TextStyles.body2,
        ),
        heading('engineering-context', l.engContextTitle),
        DiagramCanvas(
          child: Semantics(
            label: l.engContextAlt,
            excludeSemantics: true,
            child: Column(
              children: [
                _Chain(
                  nodes: [
                    _box(l.engUser),
                    _box(l.engGateway),
                    _box(l.engCortex),
                  ],
                  verbs: [l.engSends, l.engForwards],
                ),
                const SizedBox(height: Space.s24),
                _Branches(
                  branches: [
                    (
                      source: l.engCortex,
                      verb: l.engRecalls,
                      target: _box(l.engMemoryService),
                      child: (
                        source: l.engMemoryService,
                        verb: l.engStoresFiles,
                        target: _box(l.engFileStorage),
                      ),
                    ),
                    (
                      source: l.engCortex,
                      verb: l.engGenerates,
                      target: _box(l.engModelRuntime),
                      child: null,
                    ),
                    (
                      source: l.engApps,
                      verb: l.engPersists,
                      target: _box(l.engDatabases),
                      child: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        heading('engineering-containers', l.engContainersTitle),
        DiagramCanvas(
          child: Semantics(
            label: l.engContainersAlt,
            excludeSemantics: true,
            child: Column(
              children: [
                _Chain(
                  nodes: [
                    _box(l.engFrontend, l.engTechFlutter, l.engFrontendRole),
                    _box(l.engGateway, l.engTechHTTP, l.engGatewayRole),
                    api,
                  ],
                  verbs: [l.engSends, l.engForwards],
                ),
                const SizedBox(height: Space.s24),
                _Branches(
                  branches: [
                    (
                      source: l.engApi,
                      verb: l.engRecalls,
                      target: memory,
                      child: (
                        source: l.engMemoryService,
                        verb: l.engStoresDocs,
                        target: _box(
                          l.engDocumentStore,
                          l.engTechCouchDB,
                          l.engDocumentRole,
                        ),
                      ),
                    ),
                    (
                      source: l.engApi,
                      verb: l.engGenerates,
                      target: _box(
                        l.engModelRuntime,
                        l.engTechOllama,
                        l.engModelRole,
                      ),
                      child: null,
                    ),
                    (
                      source: l.engApps,
                      verb: l.engPersists,
                      target: _box(
                        l.engPostgres,
                        l.engTechPostgreSQL,
                        l.engPostgresRole,
                      ),
                      child: null,
                    ),
                    (
                      source: l.engApi,
                      verb: l.engCaches,
                      target: _box(l.engCache, l.engTechValkey, l.engCacheRole),
                      child: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        heading('engineering-pipeline', l.engPipelineTitle),
        for (final (i, stage) in [
          (l.stageAccept, l.engAcceptDetail),
          (l.stageGather, l.engGatherDetail),
          (l.stageAssemble, l.engAssembleDetail),
          (l.stageThink, l.engThinkDetail),
          (l.stageAnswer, l.engAnswerDetail),
          (l.stageSave, l.engSaveDetail),
        ].indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: Space.s40,
                  child: Text(
                    '${i + 1}',
                    style: TextStyles.subtitle1.copyWith(
                      color: Palette.from(context).muted,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.$1,
                        style: TextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(stage.$2, style: TextStyles.body2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        heading('engineering-decisions', l.engDecisionsTitle),
        LayoutBuilder(
          builder: (context, box) {
            final wide = SizeClass.of(box.maxWidth) != SizeClass.compact;
            return Wrap(
              spacing: Space.s16,
              runSpacing: Space.s16,
              children: [
                for (final (i, d) in decisions.indexed)
                  SizedBox(
                    width: wide ? (box.maxWidth - Space.s16) / 2 : box.maxWidth,
                    child: _Decision(
                      title: d.$1,
                      contextText: d.$2,
                      decision: d.$3,
                      result: d.$4,
                      index: i,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NodeBox extends StatelessWidget {
  const _NodeBox(this.node);
  final _Box node;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Space.s16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.stroke),
        borderRadius: BorderRadius.circular(
          FoundationTokens.of(context).groupRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.name,
            style: TextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          if (node.tech.isNotEmpty) ...[
            const SizedBox(height: Space.s4),
            Text(
              node.tech,
              style: TextStyles.caption1.copyWith(color: p.muted),
            ),
          ],
          if (node.role.isNotEmpty) ...[
            const SizedBox(height: Space.s8),
            Text(node.role, style: TextStyles.body1),
          ],
        ],
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.label, {required this.vertical});
  final String label;
  final bool vertical;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(Space.s8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          vertical ? AppIcons.jumpToLatest : AppIcons.next,
          size: IconSizes.action,
          color: Palette.from(context).muted,
        ),
        const SizedBox(height: Space.s4),
        Text(
          label,
          style: TextStyles.caption1.copyWith(
            color: Palette.from(context).muted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Chain extends StatelessWidget {
  const _Chain({required this.nodes, required this.verbs});
  final List<_Box> nodes;
  final List<String> verbs;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (SizeClass.of(box.maxWidth) == SizeClass.compact) {
        return Column(
          children: [
            for (final (i, n) in nodes.indexed) ...[
              if (i > 0) _Arrow(verbs[i - 1], vertical: true),
              _NodeBox(n),
            ],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final (i, n) in nodes.indexed) ...[
            if (i > 0) Flexible(child: _Arrow(verbs[i - 1], vertical: false)),
            Expanded(flex: 2, child: _NodeBox(n)),
          ],
        ],
      );
    },
  );
}

typedef _Link = ({String source, String verb, _Box target});
typedef _Branch = ({String source, String verb, _Box target, _Link? child});

class _Branches extends StatelessWidget {
  const _Branches({required this.branches});
  final List<_Branch> branches;
  Widget link(_Link link) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Arrow('${link.source}\n${link.verb}', vertical: true),
      _NodeBox(link.target),
    ],
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide = SizeClass.of(box.maxWidth) != SizeClass.compact;
      return Wrap(
        spacing: Space.s16,
        runSpacing: Space.s16,
        children: [
          for (final b in branches)
            SizedBox(
              width: wide
                  ? (box.maxWidth - Space.s16 * (branches.length - 1)) /
                        branches.length
                  : box.maxWidth,
              child: Column(
                children: [
                  link((source: b.source, verb: b.verb, target: b.target)),
                  if (b.child != null) link(b.child!),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _Decision extends StatelessWidget {
  const _Decision({
    required this.title,
    required this.contextText,
    required this.decision,
    required this.result,
    required this.index,
  });
  final String title, contextText, decision, result;
  final int index;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = Palette.from(context),
        source = engineeringExcerpts[index];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyles.subtitle1),
          for (final part in [
            (l.engContextWord, contextText),
            (l.engDecisionWord, decision),
            (l.engResultWord, result),
          ]) ...[
            const SizedBox(height: Space.s12),
            Text(part.$1, style: TextStyles.caption1.copyWith(color: p.muted)),
            const SizedBox(height: Space.s4),
            Text(part.$2, style: TextStyles.body1),
          ],
          const SizedBox(height: Space.s16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              source.code,
              style: TextStyles.caption1.copyWith(fontFamily: TextStyles.mono),
            ),
          ),
          const SizedBox(height: Space.s8),
          Text(
            source.path,
            style: TextStyles.caption1.copyWith(
              fontFamily: TextStyles.mono,
              color: p.muted,
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://github.com/wilsonborba/cortex_api/blob/v2.1.1/${source.path}',
                ),
              ),
              icon: const Icon(AppIcons.externalLink, size: IconSizes.action),
              label: Text(l.engSource),
            ),
          ),
        ],
      ),
    );
  }
}
