import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/memory_overview.dart';
import '../../../../domain/services/memory_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';
import 'tiny_map.dart';

const _base = '/v1/settings/memory';

/// Size in KB or MB with 1 decimal (cortex #65).
String memorySize(int bytes) => bytes >= 1 << 20
    ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(1)} KB';

String _time(BuildContext context, DateTime? t) => t == null
    ? ''
    : MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(t),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

String _date(BuildContext context, DateTime? t) => t == null
    ? ''
    : DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(t);

String _dateTime(BuildContext context, DateTime? t) =>
    t == null ? '' : '${_date(context, t)} ${_time(context, t)}';

/// The day header of a list group: "Today", "Yesterday" or the date.
String _day(BuildContext context, AppLocalizations l, DateTime? t) {
  if (t == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  return diff == 0
      ? l.memToday
      : diff == 1
      ? l.memYesterday
      : _date(context, t);
}

/// Second line of a row from the source and the time (ARB template).
String _line(BuildContext context, AppLocalizations l, MemoryItem m) {
  final time = _time(context, m.createdAt);
  return switch (m.sourceKind) {
    'chat' => l.memLineChat(m.sourceTitle ?? '', time),
    'file' => l.memLineFile(m.sourceTitle ?? '', time),
    _ => l.memLineNote(time),
  };
}

IconData _kindIcon(String kind) => switch (kind) {
  'chat' => AppIcons.chats,
  'file' => AppIcons.file,
  'person' || 'entity' => AppIcons.entity,
  'topic' || 'tag' => AppIcons.tag,
  _ => AppIcons.note,
};

String _typeLabel(AppLocalizations l, MemoryItem m) => switch (m.sourceKind) {
  'chat' => l.memTypeConversation,
  'file' => l.memTypeFile,
  _ => l.memTypeNote,
};

/// Memory overview (cortex #65): what Cortex knows, where it came from, when,
/// when Cortex used it, and how to open, fix or delete it. The data comes
/// already grouped, merged and labeled from cortex_api #121.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key, required this.controller, this.nodeId});
  final MemoryController controller;
  final String? nodeId;
  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  MemoryController get c => widget.controller;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = c.query;
    c.load();
    c.open(widget.nodeId);
  }

  @override
  void didUpdateWidget(MemoryScreen old) {
    super.didUpdateWidget(old);
    if (old.nodeId != widget.nodeId) c.open(widget.nodeId);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(String id) =>
      GoRouter.maybeOf(context)?.go('$_base/${Uri.encodeComponent(id)}');

  void _close() => GoRouter.maybeOf(context)?.go(_base);

  Future<void> _delete(MemoryDetail d) async {
    final l = AppLocalizations.of(context);
    if (!await showConfirmDialog(
      context,
      title: l.memDeleteTitle,
      message: l.memDeleteMessage,
      confirm: l.delete,
      cancel: l.cancel,
      destructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    await runApiAction(context, () async {
      await c.delete(d.item.id);
      if (mounted) _close();
    });
  }

  void _openConnection(MemoryConnection x) {
    final router = GoRouter.maybeOf(context);
    switch (x.kind) {
      case 'source_chat' when x.targetId != null:
        router?.go('/v1/chats/${x.targetId}');
      case 'relation' when x.targetId != null:
        _select(x.targetId!);
      case 'person' || 'topic' || 'file' when x.targetId != null:
        c.source = switch (x.kind) {
          'person' => MemorySource.person,
          'topic' => MemorySource.topic,
          _ => MemorySource.file,
        };
        c.openGroup(
          MemoryGroup(x.targetId!, x.kind, x.targetLabel, 0, null, null),
        );
        _close();
      default:
        break;
    }
  }

  // Summary (Q1) -----------------------------------------------------------

  Widget _summary(
    AppLocalizations l,
    Palette p,
    MemoryOverview o,
    bool compact,
  ) {
    final cards = [
      (l.memCardCount, '${o.memories}'),
      (l.memCardSize, memorySize(o.sizeBytes)),
      (l.memCardAdded, '${o.added7Days}'),
      (l.memCardUsed, '${o.used7Days}'),
    ];
    Widget card((String, String) v) => AppCard(
      padding: const EdgeInsets.all(Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.$1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.caption1.copyWith(color: p.muted),
          ),
          const SizedBox(height: Space.s4),
          Text(v.$2, style: TextStyles.title2.copyWith(color: p.text)),
        ],
      ),
    );
    final top = o.months.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final locale = Localizations.localeOf(context).toString();
    return Column(
      key: const Key('memory-summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (o.truncated) ...[
          MessageBar(message: l.memTruncated),
          const SizedBox(height: Space.s12),
        ],
        Text(
          [
            l.memSummary(
              o.memories,
              memorySize(o.sizeBytes),
              l.memChats(o.chats),
              l.memFiles(o.files),
              l.memPeople(o.people),
            ),
            if (o.lastAt != null)
              l.memNewest(
                '${_day(context, l, o.lastAt).toLowerCase() == l.memToday.toLowerCase() ? l.memToday.toLowerCase() : _date(context, o.lastAt)} ${_time(context, o.lastAt)}',
              ),
          ].join(' '),
          style: TextStyles.body2.copyWith(color: p.text),
        ),
        const SizedBox(height: Space.s16),
        if (compact)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Space.s8,
            crossAxisSpacing: Space.s8,
            childAspectRatio: 1.6,
            children: [for (final v in cards) card(v)],
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, v) in cards.indexed) ...[
                  if (i > 0) const SizedBox(width: Space.s8),
                  Expanded(child: card(v)),
                ],
              ],
            ),
          ),
        if (o.months.isNotEmpty) ...[
          const SizedBox(height: Space.s16),
          Text(
            l.memByMonth,
            style: TextStyles.caption1Strong.copyWith(color: p.text2),
          ),
          const SizedBox(height: Space.s4),
          for (final m in o.months)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s2),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Text(() {
                      final d = DateTime.tryParse('${m.key}-01');
                      return d == null
                          ? m.key
                          : DateFormat.yMMM(locale).format(d);
                    }(), style: TextStyles.caption1.copyWith(color: p.text2)),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: top == 0 ? 0 : m.count / top,
                        child: Container(
                          height: Space.s8,
                          decoration: BoxDecoration(
                            color: p.text2,
                            borderRadius: BorderRadius.circular(Radii.small),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: Space.s40,
                    child: Text(
                      '${m.count}',
                      textAlign: TextAlign.end,
                      style: TextStyles.caption1.copyWith(color: p.text2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // Facets (Q2) --------------------------------------------------------------

  List<(MemorySource, String, int?)> _sources(AppLocalizations l) {
    final o = c.overview;
    return [
      (MemorySource.chat, l.memSourceChats, o?.sources['chat']),
      (MemorySource.file, l.memSourceFiles, o?.sources['file']),
      (MemorySource.note, l.memSourceNotes, o?.sources['note']),
      (MemorySource.person, l.memSourcePeople, o?.people),
      (MemorySource.topic, l.memSourceTopics, o?.topics),
    ];
  }

  List<(MemoryPeriod, String)> _periods(AppLocalizations l) => [
    (MemoryPeriod.today, l.memPeriodToday),
    (MemoryPeriod.week, l.memPeriod7),
    (MemoryPeriod.month, l.memPeriod30),
    (MemoryPeriod.all, l.memPeriodAll),
  ];

  Widget _facetRow(
    Palette p,
    String label,
    int? count,
    bool selected,
    VoidCallback onTap,
    Key key,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s2),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.control),
        child: InkWell(
          key: key,
          borderRadius: BorderRadius.circular(Radii.control),
          hoverColor: p.subtleHover,
          onTap: onTap,
          child: SizedBox(
            height: Space.s32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.s8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (selected ? TextStyles.body1Strong : TextStyles.body1)
                              .copyWith(color: p.text),
                    ),
                  ),
                  if (count != null)
                    Text(
                      '$count',
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _facets(AppLocalizations l, Palette p, {VoidCallback? onDone}) {
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.s8,
        Space.s16,
        Space.s8,
        Space.s4,
      ),
      child: Text(
        text,
        style: TextStyles.caption1Strong.copyWith(color: p.muted),
      ),
    );
    return Column(
      key: const Key('memory-facets'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppInput(
          key: const Key('memory-search'),
          controller: _search,
          hint: l.memSearch,
          onSubmitted: (v) {
            c.setQuery(v);
            onDone?.call();
          },
        ),
        header(l.memFacetSource),
        for (final (s, label, count) in _sources(l))
          _facetRow(p, label, count, c.source == s, () {
            c.setSource(c.source == s ? MemorySource.all : s);
            onDone?.call();
          }, Key('facet-${s.name}')),
        header(l.memFacetPeriod),
        for (final (period, label) in _periods(l))
          _facetRow(p, label, null, c.period == period, () {
            c.setPeriod(period);
            onDone?.call();
          }, Key('period-${period.name}')),
      ],
    );
  }

  /// Active filters as small dismissable tags, with "Clear all".
  Widget _activeFilters(AppLocalizations l) {
    final tags = <(String, VoidCallback)>[
      if (c.source != MemorySource.all)
        (
          _sources(l).firstWhere((e) => e.$1 == c.source).$2,
          () => c.setSource(MemorySource.all),
        ),
      if (c.group != null && c.group!.title.isNotEmpty)
        (c.group!.title, () => c.openGroup(null)),
      if (c.period != MemoryPeriod.all)
        (
          _periods(l).firstWhere((e) => e.$1 == c.period).$2,
          () => c.setPeriod(MemoryPeriod.all),
        ),
      if (c.query.isNotEmpty)
        (
          '"${c.query}"',
          () {
            _search.clear();
            c.setQuery('');
          },
        ),
    ];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s12),
      child: Wrap(
        key: const Key('active-filters'),
        spacing: Space.s8,
        runSpacing: Space.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (label, remove) in tags)
            InputChip(
              visualDensity: Controls.tagDensity,
              label: Text(label),
              deleteButtonTooltipMessage: l.memRemoveFilter,
              onDeleted: remove,
            ),
          AppButton(
            key: const Key('clear-filters'),
            label: l.memClearAll,
            kind: ButtonKind.subtle,
            size: ButtonSize.small,
            onPressed: () {
              _search.clear();
              c.clearFilters();
            },
          ),
        ],
      ),
    );
  }

  // List (Q3) ----------------------------------------------------------------

  Widget _groupCard(AppLocalizations l, Palette p, MemoryGroup g) => Padding(
    padding: const EdgeInsets.only(bottom: Space.s8),
    child: AppCard(
      key: Key('group-${g.id}'),
      onTap: () => c.openGroup(g),
      child: Row(
        children: [
          _iconSquare(p, _kindIcon(g.kind)),
          const SizedBox(width: Space.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.body1Strong.copyWith(color: p.text),
                ),
                Text(
                  [
                    _date(context, g.firstAt),
                    if (_date(context, g.lastAt) != _date(context, g.firstAt))
                      _date(context, g.lastAt),
                  ].join(' → '),
                  style: TextStyles.caption1.copyWith(color: p.muted),
                ),
              ],
            ),
          ),
          Text(
            l.memGroupCount(g.count),
            style: TextStyles.caption1.copyWith(color: p.text2),
          ),
        ],
      ),
    ),
  );

  Widget _iconSquare(Palette p, IconData icon) => Container(
    width: Space.s32,
    height: Space.s32,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: p.tagBackground,
      borderRadius: BorderRadius.circular(Radii.control),
    ),
    child: Icon(icon, size: IconSizes.action, color: p.text2),
  );

  Widget _row(AppLocalizations l, Palette p, MemoryItem m) {
    final selected = c.detail?.item.id == m.id || widget.nodeId == m.id;
    final open = c.stacks.containsKey(m.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: selected ? p.selected : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.control),
          child: InkWell(
            key: Key('memory-${m.id}'),
            borderRadius: BorderRadius.circular(Radii.control),
            hoverColor: p.subtleHover,
            onTap: () => _select(m.id),
            child: Semantics(
              selected: selected,
              child: SizedBox(
                height: 64,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s8),
                  child: Row(
                    children: [
                      _iconSquare(p, _kindIcon(m.sourceKind)),
                      const SizedBox(width: Space.s12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    m.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyles.body1Strong.copyWith(
                                      color: p.text,
                                    ),
                                  ),
                                ),
                                if (m.stack != null) ...[
                                  const SizedBox(width: Space.s8),
                                  Tooltip(
                                    message: l.memShowSimilar,
                                    child: InkWell(
                                      key: Key('stack-${m.id}'),
                                      borderRadius: BorderRadius.circular(
                                        Radii.small,
                                      ),
                                      onTap: () => setState(() {
                                        if (open) {
                                          c.stacks.remove(m.id);
                                        } else {
                                          c.loadStack(m);
                                        }
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: Space.s4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: p.tagBackground,
                                          borderRadius: BorderRadius.circular(
                                            Radii.small,
                                          ),
                                        ),
                                        child: Text(
                                          l.memSimilar(m.stack!.count),
                                          style: TextStyles.caption1Strong
                                              .copyWith(color: p.text2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: Space.s2),
                            Text(
                              _line(context, l, m),
                              key: Key('memory-line-${m.id}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.caption1.copyWith(
                                color: p.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.s8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (m.usedInAnswers > 0)
                            Text(
                              l.memUsedTimes(m.usedInAnswers),
                              style: TextStyles.caption1.copyWith(
                                color: p.text2,
                              ),
                            ),
                          Text(
                            memorySize(m.sizeBytes),
                            style: TextStyles.caption1.copyWith(color: p.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (open)
          Padding(
            key: Key('stack-list-${m.id}'),
            padding: const EdgeInsets.only(left: Space.s52, bottom: Space.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (c.stacks[m.id]!.isEmpty) const LinearProgressIndicator(),
                for (final copy in c.stacks[m.id]!)
                  InkWell(
                    borderRadius: BorderRadius.circular(Radii.control),
                    onTap: () => _select(copy.item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: Space.s4,
                        horizontal: Space.s8,
                      ),
                      child: Text(
                        '${_dateTime(context, copy.item.createdAt)}  ${copy.content.characters.take(80)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.caption1.copyWith(color: p.text2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _list(AppLocalizations l, Palette p) {
    if (c.error != null && c.items.isEmpty && c.groups.isEmpty) {
      return [
        ErrorState(
          message: apiFailure(l, c.error),
          retryLabel: l.retry,
          onRetry: c.load,
        ),
      ];
    }
    if (c.loading && c.items.isEmpty && c.groups.isEmpty) {
      return [
        for (var i = 0; i < 4; i++)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Space.s8),
            child: SkeletonBox(height: 48),
          ),
      ];
    }
    final out = <Widget>[];
    if (c.grouped && c.group != null) {
      out.add(
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            key: const Key('back-to-groups'),
            label: l.memBackToGroups,
            icon: AppIcons.back,
            kind: ButtonKind.subtle,
            size: ButtonSize.small,
            onPressed: () => c.openGroup(null),
          ),
        ),
      );
    }
    if (c.grouped && c.group == null) {
      for (final g in c.groups) {
        out.add(_groupCard(l, p, g));
      }
    } else {
      String? last;
      for (final m in c.items) {
        final day = _day(context, l, m.createdAt);
        if (day != last) {
          out.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.s8,
                Space.s16,
                Space.s8,
                Space.s4,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  day,
                  style: TextStyles.caption1Strong.copyWith(color: p.muted),
                ),
              ),
            ),
          );
          last = day;
        }
        out.add(_row(l, p, m));
      }
    }
    if (out.isEmpty || (c.items.isEmpty && c.groups.isEmpty)) {
      out.add(
        Padding(
          padding: const EdgeInsets.all(Space.s24),
          child: Text(
            l.memNoResults,
            textAlign: TextAlign.center,
            style: TextStyles.body1.copyWith(color: p.muted),
          ),
        ),
      );
    }
    if (c.nextCursor != null) {
      out.add(
        Padding(
          padding: const EdgeInsets.all(Space.s12),
          child: Center(
            child: AppButton(
              key: const Key('memory-more'),
              label: l.memLoadMore,
              busy: c.loadingMore,
              onPressed: c.loadMore,
            ),
          ),
        ),
      );
    }
    return out;
  }

  // Detail (Q4, Q5) ----------------------------------------------------------

  Widget _detail(AppLocalizations l, Palette p, {bool page = false}) {
    if (c.detailLoading && c.detail == null) {
      return const Center(child: AppSpinner(page: true));
    }
    final d = c.detail;
    if (d == null) {
      return ErrorState(
        message: apiFailure(l, c.detailError),
        retryLabel: l.retry,
        onRetry: () => c.open(widget.nodeId),
      );
    }
    return _MemoryDetailView(
      key: ValueKey('detail-${d.item.id}'),
      detail: d,
      page: page,
      onClose: _close,
      onConnection: _openConnection,
      onDelete: () => _delete(d),
    );
  }

  // Layout --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    return LayoutBuilder(
      builder: (context, box) => ListenableBuilder(
        listenable: c,
        builder: (context, _) {
          final o = c.overview;
          final compact = size == SizeClass.compact;
          // The columns follow the width of this area (the shell and the
          // Settings tabs take space): facets need 240 plus a 480 list, the
          // inline detail another 360. Else facets are a menu and the detail
          // is a drawer.
          final expanded = !compact && box.maxWidth >= 720;
          final detailInline = expanded && box.maxWidth >= 1080;
          if (compact && widget.nodeId != null) {
            return _detail(l, p, page: true);
          }
          if (o != null && o.memories == 0 && !c.filtered) {
            return EmptyState(
              key: const Key('memory-empty'),
              title: l.memEmpty,
              icon: AppIcons.memory,
              action: AppButton(
                label: l.memStartChat,
                onPressed: () => GoRouter.maybeOf(context)?.go('/v1/chats'),
              ),
            );
          }
          final gutter = compact ? Space.s16 : Space.s8;
          final filters = AppButton(
            key: const Key('memory-filters'),
            label: l.memFilters,
            icon: AppIcons.list,
            kind: ButtonKind.subtle,
            onPressed: () {
              if (compact) {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  barrierColor: p.overlay,
                  builder: (sheet) => ListenableBuilder(
                    listenable: c,
                    builder: (sheet, _) => SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(Space.s16),
                        child: _facets(
                          l,
                          p,
                          onDone: () => Navigator.pop(sheet),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          );
          final center = ListView(
            key: const Key('memory-list'),
            padding: EdgeInsets.fromLTRB(
              gutter,
              0,
              compact ? Space.s16 : Space.s24,
              Space.s24,
            ),
            children: [
              if (o != null) ...[
                _summary(l, p, o, compact),
                const SizedBox(height: Space.s16),
              ],
              if (!expanded)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: compact
                        ? filters
                        : MenuAnchor(
                            clipBehavior: Clip.none,
                            menuChildren: [
                              SizedBox(
                                width: 240,
                                child: Padding(
                                  padding: const EdgeInsets.all(Space.s8),
                                  child: ListenableBuilder(
                                    listenable: c,
                                    builder: (_, _) => _facets(l, p),
                                  ),
                                ),
                              ),
                            ],
                            builder: (context, controller, _) => AppButton(
                              key: const Key('memory-filters'),
                              label: l.memFilters,
                              icon: AppIcons.list,
                              kind: ButtonKind.subtle,
                              onPressed: () => controller.isOpen
                                  ? controller.close()
                                  : controller.open(),
                            ),
                          ),
                  ),
                ),
              _activeFilters(l),
              ..._list(l, p),
            ],
          );
          final detailOpen = widget.nodeId != null;
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (expanded)
                    SizedBox(
                      width: 240,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          right: Space.s8,
                          bottom: Space.s24,
                        ),
                        child: _facets(l, p),
                      ),
                    ),
                  Expanded(child: center),
                  if (detailInline && detailOpen)
                    Container(
                      key: const Key('memory-detail-panel'),
                      width: 360,
                      decoration: BoxDecoration(
                        color: p.surface,
                        border: Border(left: BorderSide(color: p.divider)),
                      ),
                      child: _detail(l, p),
                    ),
                ],
              ),
              // Medium width: the detail opens as a drawer from the right.
              if (!detailInline && !compact && detailOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _close,
                    child: ColoredBox(color: p.overlay),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: 360,
                  child: Container(
                    key: const Key('memory-detail-panel'),
                    decoration: BoxDecoration(
                      color: p.raised,
                      boxShadow: Shadows.shadow64(Theme.of(context).brightness),
                    ),
                    child: _detail(l, p),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The detail of one memory (Q4, Q5): title, type and source, facts, the text,
/// one sentence per connection, the answers that used it, the optional tiny
/// map and the actions.
class _MemoryDetailView extends StatefulWidget {
  const _MemoryDetailView({
    super.key,
    required this.detail,
    required this.page,
    required this.onClose,
    required this.onConnection,
    required this.onDelete,
  });
  final MemoryDetail detail;
  final bool page;
  final VoidCallback onClose, onDelete;
  final ValueChanged<MemoryConnection> onConnection;
  @override
  State<_MemoryDetailView> createState() => _MemoryDetailViewState();
}

class _MemoryDetailViewState extends State<_MemoryDetailView> {
  bool all = false, picture = false;

  String _sentence(AppLocalizations l, MemoryConnection x) {
    final v = x.targetLabel;
    return switch (x.kind) {
      'source_chat' => l.memConnChat(v),
      'file' => l.memConnFile(v),
      'person' => l.memConnPerson(v),
      'topic' => l.memConnTopic(v),
      'same_title' => l.memConnSameTitle(x.count),
      _ => switch (x.relationType) {
        'supersedes' => l.memConnSupersedes(v),
        'corrects' => l.memConnCorrects(v),
        'derived_from' => l.memConnDerived(v),
        'supports' => l.memConnSupports(v),
        'contradicts' => l.memConnContradicts(v),
        'part_of' => l.memConnPartOf(v),
        _ => l.memConnRelated(v),
      },
    };
  }

  IconData _connIcon(MemoryConnection x) => switch (x.kind) {
    'source_chat' => AppIcons.chats,
    'file' => AppIcons.file,
    'person' => AppIcons.entity,
    'topic' => AppIcons.tag,
    'same_title' => AppIcons.list,
    _ => AppIcons.note,
  };

  Widget _section(Palette p, String title) => Padding(
    padding: const EdgeInsets.only(top: Space.s20, bottom: Space.s8),
    child: Semantics(
      header: true,
      child: Text(title, style: TextStyles.subtitle2.copyWith(color: p.text)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final d = widget.detail, m = d.item;
    final router = GoRouter.maybeOf(context);
    final facts = [
      (l.memCreated, _dateTime(context, m.createdAt)),
      (l.memUpdated, _dateTime(context, m.updatedAt)),
      (l.memSize, l.memSizeWords(memorySize(m.sizeBytes), m.words)),
      (l.memUsedCount, '${m.usedInAnswers}'),
      (
        l.memLastUsed,
        m.lastUsedAt == null ? l.memNever : _dateTime(context, m.lastUsedAt),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s16, Space.s12, Space.s8, 0),
          child: Row(
            children: [
              if (widget.page)
                BackButton(onPressed: widget.onClose)
              else
                const SizedBox.shrink(),
              Expanded(
                child: Text(
                  l.memDetails,
                  style: TextStyles.caption1Strong.copyWith(color: p.muted),
                ),
              ),
              if (!widget.page)
                IconButton(
                  key: const Key('memory-detail-close'),
                  tooltip: l.close,
                  icon: const Icon(AppIcons.close, size: IconSizes.action),
                  onPressed: widget.onClose,
                ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('memory-detail'),
            padding: const EdgeInsets.fromLTRB(
              Space.s16,
              Space.s4,
              Space.s16,
              Space.s16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    m.title,
                    style: TextStyles.subtitle1.copyWith(color: p.text),
                  ),
                ),
                const SizedBox(height: Space.s4),
                Wrap(
                  spacing: Space.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _typeLabel(l, m),
                      style: TextStyles.caption1.copyWith(color: p.muted),
                    ),
                    if (m.sourceKind == 'chat' && m.sourceId != null)
                      InkWell(
                        key: const Key('memory-source-link'),
                        onTap: () => router?.go('/v1/chats/${m.sourceId}'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                m.sourceTitle ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.caption1.copyWith(
                                  color: p.text,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(width: Space.s4),
                            Icon(
                              AppIcons.externalLink,
                              size: IconSizes.small,
                              color: p.text2,
                            ),
                          ],
                        ),
                      )
                    else if (m.sourceTitle != null)
                      Text(
                        m.sourceTitle!,
                        style: TextStyles.caption1.copyWith(color: p.text2),
                      ),
                  ],
                ),
                const SizedBox(height: Space.s16),
                for (final (label, value) in facts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120,
                          child: Text(
                            label,
                            style: TextStyles.caption1.copyWith(color: p.muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyles.body1.copyWith(color: p.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                _section(p, l.memKeeps),
                Text(
                  d.content,
                  key: const Key('memory-content'),
                  maxLines: all ? null : 12,
                  overflow: all ? null : TextOverflow.ellipsis,
                  style: TextStyles.body1.copyWith(color: p.text),
                ),
                if ('\n'.allMatches(d.content).length >= 12 ||
                    d.content.length > 600)
                  AppButton(
                    label: all ? l.memShowLess : l.memShowAll,
                    kind: ButtonKind.subtle,
                    size: ButtonSize.small,
                    onPressed: () => setState(() => all = !all),
                  ),
                if (d.connections.isNotEmpty) ...[
                  _section(p, l.memConnects),
                  for (final x in d.connections)
                    InkWell(
                      key: Key('connection-${x.kind}-${x.targetId ?? x.count}'),
                      borderRadius: BorderRadius.circular(Radii.control),
                      onTap: x.kind == 'same_title'
                          ? null
                          : () => widget.onConnection(x),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.s4),
                        child: Row(
                          children: [
                            Icon(
                              _connIcon(x),
                              size: IconSizes.small,
                              color: p.text2,
                            ),
                            const SizedBox(width: Space.s8),
                            Expanded(
                              child: Text(
                                _sentence(l, x),
                                style: TextStyles.body1.copyWith(
                                  color: p.text,
                                  decoration: x.kind == 'same_title'
                                      ? null
                                      : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                _section(p, l.memUsedIn),
                if (d.usage.isEmpty)
                  Text(
                    l.memNoUse,
                    style: TextStyles.body1.copyWith(color: p.muted),
                  ),
                for (final u in d.usage)
                  InkWell(
                    key: Key('usage-${u.outputId}'),
                    borderRadius: BorderRadius.circular(Radii.control),
                    onTap: () => router?.go(
                      '/v1/chats/${u.sessionId}/outputs/${u.outputId}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.s4),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.chats,
                            size: IconSizes.small,
                            color: p.text2,
                          ),
                          const SizedBox(width: Space.s8),
                          Expanded(
                            child: Text(
                              u.chatTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.body1.copyWith(
                                color: p.text,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            _date(context, u.usedAt),
                            style: TextStyles.caption1.copyWith(color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (d.mapNodes.length > 1) ...[
                  const SizedBox(height: Space.s12),
                  AppButton(
                    key: const Key('memory-picture'),
                    label: picture ? l.memHidePicture : l.memShowPicture,
                    kind: ButtonKind.subtle,
                    size: ButtonSize.small,
                    icon: AppIcons.memory,
                    onPressed: () => setState(() => picture = !picture),
                  ),
                  if (picture) TinyMap(detail: d),
                ],
                const SizedBox(height: Space.s20),
                Wrap(
                  spacing: Space.s8,
                  runSpacing: Space.s8,
                  children: [
                    if (m.sourceKind == 'chat' && m.sourceId != null)
                      AppButton(
                        key: const Key('memory-open-chat'),
                        label: l.memOpenChat,
                        onPressed: () => router?.go('/v1/chats/${m.sourceId}'),
                      ),
                    _DangerSubtleButton(
                      label: l.memDelete,
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Delete memory": a subtle button in `dangerForeground` (cortex #65).
class _DangerSubtleButton extends StatelessWidget {
  const _DangerSubtleButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final size = ButtonSize.of(SizeClass.of(MediaQuery.sizeOf(context).width));
    return TextButton.icon(
      key: const Key('memory-delete'),
      style: buttonStyle(p, ButtonAppearance.subtle, size: size).copyWith(
        foregroundColor: WidgetStatePropertyAll(p.dangerForeground),
        iconColor: WidgetStatePropertyAll(p.dangerForeground),
      ),
      onPressed: onPressed,
      icon: Icon(AppIcons.delete, size: size.icon),
      label: Text(label),
    );
  }
}
