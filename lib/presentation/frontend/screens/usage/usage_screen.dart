import '../../handlers/process_messages.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/telemetry.dart';
import '../../../../domain/services/usage_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';

String viewTitle(AppLocalizations l, UsageView view) => switch (view) {
  UsageView.usage => l.usage,
  UsageView.timing => l.timing,
  UsageView.stats => l.stats,
  UsageView.events => l.events,
};
String kindTitle(AppLocalizations l, RunKind kind) =>
    l.usageKind(switch (kind.webMode) {
      'fast' => l.webFast,
      'medium' => l.webMedium,
      'deep' => l.webDeep,
      _ => kind.webMode,
    }, kind.thinking ? l.usageThinkingOn : l.usageThinkingOff);
String number(AppLocalizations l, num value) =>
    NumberFormat.decimalPattern(l.localeName).format(value);
String seconds(AppLocalizations l, num value) =>
    l.usageSeconds(number(l, value));

class UsageScreen extends StatefulWidget {
  const UsageScreen({super.key, required this.controller, required this.view});
  final UsageController controller;
  final UsageView view;
  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  UsageController get usage => widget.controller;
  bool retryMore = false;
  @override
  void initState() {
    super.initState();
    usage.addListener(changed);
    schedule();
  }

  @override
  void didUpdateWidget(UsageScreen old) {
    super.didUpdateWidget(old);
    if (old.view != widget.view) schedule();
  }

  void schedule() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      retryMore = false;
      usage.load(widget.view);
    }
  });
  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    usage.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final active = usage.view == widget.view;
    final loading = !active || usage.loading;
    final error = active ? usage.error : null;
    final hasData =
        active &&
        switch (widget.view) {
          UsageView.usage => usage.usage != null,
          UsageView.timing => usage.timing != null,
          UsageView.stats => usage.stats != null,
          UsageView.events => usage.events != null,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.s12,
            Space.s12,
            Space.s12,
            0,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final view in UsageView.values)
                  UsageTab(
                    label: viewTitle(l, view),
                    selected: view == widget.view,
                    onTap: () => context.go(
                      view == UsageView.usage
                          ? '/v1/usage'
                          : '/v1/usage/${view.name}',
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(Space.s16),
            child: ErrorState(
              message: apiFailure(l, error),
              retryLabel: l.retry,
              onRetry: () => usage.load(widget.view, more: retryMore),
            ),
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(Space.s16),
            child: SkeletonBox(height: 48),
          ),
        if (hasData)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.s16),
              child: switch (widget.view) {
                UsageView.usage => UsageSummary(data: usage.usage!),
                UsageView.timing => TimingTable(rows: usage.timing!),
                UsageView.stats => StatsChart(rows: usage.stats!),
                UsageView.events => EventsTable(
                  rows: usage.events!,
                  hasMore: usage.hasMore,
                  loading: loading,
                  more: () {
                    retryMore = true;
                    usage.load(UsageView.events, more: true);
                  },
                ),
              },
            ),
          ),
      ],
    );
  }
}

/// Fluent tab (#67): height 44, `body1` (selected `body1Strong`), a 3 px
/// `brandForeground1` bar under the label with a circular radius, hover
/// `subtleHover`. The tabs keep their URL paths.
class UsageTab extends StatelessWidget {
  const UsageTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('usage-tab-$label'),
        onTap: selected ? null : onTap,
        hoverColor: p.subtleHover,
        borderRadius: BorderRadius.circular(Radii.control),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s10),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: Strokes.thicker),
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: selected
                            ? TextStyles.body1Strong.copyWith(color: p.text)
                            : TextStyles.body1.copyWith(color: p.text2),
                      ),
                    ),
                  ),
                  Container(
                    height: Strokes.thicker,
                    decoration: BoxDecoration(
                      color: selected ? p.brandForeground1 : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.circular),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A summary card (#67): label `caption1` `muted`, value `title2`, sub text
/// `caption1`. No value: an info message bar inside the card.
class UsageCard extends StatelessWidget {
  const UsageCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
  });
  final String label;
  final String? value, sub;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return AppCard(
      padding: const EdgeInsets.all(Space.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyles.caption1.copyWith(color: p.muted)),
          const SizedBox(height: Space.s4),
          if (value == null)
            MessageBar(message: l.notAvailableYet)
          else
            Text(
              value!,
              style: TextStyles.title2.copyWith(
                color: p.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          if (sub != null) ...[
            const SizedBox(height: Space.s4),
            Text(sub!, style: TextStyles.caption1.copyWith(color: p.text2)),
          ],
        ],
      ),
    );
  }
}

/// Cards in a grid: 1 column compact, 2 medium, 3 expanded, gap 16.
class _CardGrid extends StatelessWidget {
  const _CardGrid({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = SizeClass.of(MediaQuery.sizeOf(context).width);
      final columns = size == SizeClass.compact
          ? 1
          : size == SizeClass.medium
          ? 2
          : 3;
      final width = (box.maxWidth - Space.s16 * (columns - 1)) / columns;
      return Wrap(
        spacing: Space.s16,
        runSpacing: Space.s16,
        children: [for (final c in children) SizedBox(width: width, child: c)],
      );
    },
  );
}

class UsageSummary extends StatelessWidget {
  const UsageSummary({super.key, required this.data});
  final UsageData data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final weight = data.weight;
    String? v(num? value) => value == null ? null : number(l, value);
    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s12),
      child: Semantics(
        header: true,
        child: Text(text, style: TextStyles.subtitle2.copyWith(color: p.text)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        title(l.usageWindow(data.windowHours)),
        _CardGrid(
          children: [
            UsageCard(
              label: l.usageInputTokens,
              value: v(data.tokens['input']),
            ),
            UsageCard(
              label: l.usageOutputTokens,
              value: v(data.tokens['output']),
            ),
            UsageCard(
              label: l.usageTotalTokens,
              value: v(data.tokens['total']),
            ),
            UsageCard(label: l.usageImages, value: v(data.items['images'])),
            UsageCard(label: l.usageAudio, value: v(data.items['audio'])),
          ],
        ),
        const SizedBox(height: Space.s24),
        title(l.usagePriority),
        Padding(
          padding: const EdgeInsets.only(bottom: Space.s12),
          child: Text(
            l.usagePriorityHelp,
            style: TextStyles.body1.copyWith(color: p.text2),
          ),
        ),
        _CardGrid(
          children: [
            UsageCard(
              label: l.usageWeight,
              value: v(weight['value']),
              sub: l.usageWeightFormula,
            ),
            UsageCard(label: l.usageAccountAge, value: v(weight['age'])),
            UsageCard(label: l.usageFrequency, value: v(weight['frequency'])),
            UsageCard(
              label: l.usageAccountDays,
              value: v(weight['account_days']),
            ),
            UsageCard(
              label: l.usageSignInDays,
              value: v(weight['sign_in_days_90']),
            ),
          ],
        ),
      ],
    );
  }
}

/// One column of a [FluentTable].
class TableColumnSpec {
  const TableColumnSpec(this.title, {this.numeric = false, this.width = 160});
  final String title;
  final bool numeric;
  final double width;
}

/// Fluent table look (#67): header 32 high in `caption1Strong` `muted` with
/// a 1 px `divider` under it; rows 40 high (44 compact) in `body1` with a
/// 1 px `divider` between them and `subtleHover` on hover; numbers right
/// aligned with tabular figures. Scrolls horizontally when it is too wide.
class FluentTable extends StatelessWidget {
  const FluentTable({super.key, required this.columns, required this.rows});
  final List<TableColumnSpec> columns;
  final List<List<Widget>> rows;
  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    final compact =
        SizeClass.of(MediaQuery.sizeOf(context).width) == SizeClass.compact;
    Widget cell(TableColumnSpec c, Widget child) => SizedBox(
      width: c.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s8),
        child: Align(
          alignment: c.numeric ? Alignment.centerRight : Alignment.centerLeft,
          child: DefaultTextStyle.merge(
            style: c.numeric
                ? const TextStyle(fontFeatures: [FontFeature.tabularFigures()])
                : null,
            child: child,
          ),
        ),
      ),
    );
    final total = columns.fold<double>(0, (w, c) => w + c.width);
    return LayoutBuilder(
      builder: (context, box) {
        final scale = box.maxWidth > total ? box.maxWidth / total : 1.0;
        final cols = [
          for (final c in columns)
            TableColumnSpec(
              c.title,
              numeric: c.numeric,
              width: c.width * scale,
            ),
        ];
        return SingleChildScrollView(
          key: const Key('fluent-table'),
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: Space.s32,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.divider)),
                ),
                child: Row(
                  children: [
                    for (final c in cols)
                      cell(
                        c,
                        Text(
                          c.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.caption1Strong.copyWith(
                            color: p.muted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              for (final r in rows)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    hoverColor: p.subtleHover,
                    splashFactory: NoSplash.splashFactory,
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: compact ? Controls.minTouch : Space.s40,
                      ),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: p.divider)),
                      ),
                      child: Row(
                        children: [
                          for (var i = 0; i < cols.length; i++)
                            cell(
                              cols[i],
                              DefaultTextStyle.merge(
                                style: TextStyles.body1.copyWith(color: p.text),
                                child: r[i],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class TimingTable extends StatelessWidget {
  const TimingTable({super.key, required this.rows});
  final List<TimingAverage> rows;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    if (rows.isEmpty) return EmptyState(title: l.usageEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.timing, style: TextStyles.subtitle2.copyWith(color: p.text)),
        const SizedBox(height: Space.s4),
        Text(
          l.usageTimingHelp,
          style: TextStyles.body1.copyWith(color: p.text2),
        ),
        const SizedBox(height: Space.s12),
        FluentTable(
          columns: [
            TableColumnSpec(l.usageKindColumn, width: 260),
            TableColumnSpec(l.usageAverageTime, numeric: true, width: 140),
          ],
          rows: [
            for (final row in rows)
              [
                Text(kindTitle(l, row.kind)),
                Text(
                  row.milliseconds == null
                      ? l.notAvailableYet
                      : seconds(l, row.milliseconds! / 1000),
                ),
              ],
          ],
        ),
      ],
    );
  }
}

const metrics = [
  'total_runs',
  'avg_latency_ms',
  'avg_input_tokens',
  'avg_output_tokens',
  'avg_total_tokens',
  'success_rate',
];
String metricTitle(AppLocalizations l, String metric) => switch (metric) {
  'total_runs' => l.usageRuns,
  'avg_latency_ms' => l.usageAverageTime,
  'avg_input_tokens' => l.usageAverageInput,
  'avg_output_tokens' => l.usageAverageOutput,
  'avg_total_tokens' => l.usageAverageTotal,
  _ => l.usageSuccessRate,
};
num metricValue(GroupStats row, String metric) {
  final value = row.values[metric] ?? 0;
  return metric == 'avg_latency_ms'
      ? value / 1000
      : metric == 'success_rate'
      ? value * 100
      : value;
}

String metricText(AppLocalizations l, GroupStats row, String metric) {
  final value = metricValue(row, metric);
  return metric == 'avg_latency_ms'
      ? seconds(l, value)
      : metric == 'success_rate'
      ? NumberFormat.percentPattern(l.localeName).format(value / 100)
      : number(l, value);
}

class StatsChart extends StatefulWidget {
  const StatsChart({super.key, required this.rows});
  final List<GroupStats> rows;
  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart> {
  String metric = metrics.first;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    if (widget.rows.isEmpty) return EmptyState(title: l.usageEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('stats-metric'),
          initialValue: metric,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.usageMetric),
          items: [
            for (final item in metrics)
              DropdownMenuItem(
                value: item,
                child: Text(
                  metricTitle(l, item),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (value) => setState(() => metric = value!),
        ),
        const SizedBox(height: Space.s16),
        // One series at a time keeps this chart monochrome (Asodya chart
        // rules). The frame is a Fluent card (#67). The table rows are also
        // available to screen readers and at large text sizes.
        AppCard(
          key: const Key('stats-card'),
          padding: const EdgeInsets.all(Space.s16),
          child: ExcludeSemantics(
            child: SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: p.divider, strokeWidth: Strokes.thin),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt() + 1}',
                          style: TextStyles.caption1.copyWith(color: p.muted),
                        ),
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) =>
                          Theme.of(context).brightness == Brightness.dark
                          ? p.raised
                          : p.background,
                      tooltipBorderRadius: BorderRadius.circular(Radii.control),
                      tooltipPadding: const EdgeInsets.fromLTRB(
                        Space.s10 + Strokes.thin,
                        Space.s4,
                        Space.s10 + Strokes.thin,
                        Space.s6,
                      ),
                      getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                        metricText(l, widget.rows[group.x], metric),
                        TextStyles.caption1.copyWith(color: p.text),
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < widget.rows.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: metricValue(widget.rows[i], metric).toDouble(),
                            color: p.text,
                            width: 24,
                            borderRadius: BorderRadius.zero,
                          ),
                        ],
                      ),
                  ],
                ),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : MotionDurations.fast,
              ),
            ),
          ),
        ),
        const SizedBox(height: Space.s16),
        FluentTable(
          columns: [
            const TableColumnSpec('#', numeric: true, width: 48),
            TableColumnSpec(l.usageKindColumn, width: 260),
            TableColumnSpec(metricTitle(l, metric), numeric: true, width: 160),
          ],
          rows: [
            for (var i = 0; i < widget.rows.length; i++)
              [
                Text('${i + 1}'),
                Text(kindTitle(l, widget.rows[i].kind)),
                Text(
                  metricText(l, widget.rows[i], metric),
                  key: Key('stats-value-$i'),
                ),
              ],
          ],
        ),
      ],
    );
  }
}

class EventsTable extends StatelessWidget {
  const EventsTable({
    super.key,
    required this.rows,
    required this.hasMore,
    required this.loading,
    required this.more,
  });
  final List<CallEvent> rows;
  final bool hasMore, loading;
  final VoidCallback more;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (rows.isEmpty) return EmptyState(title: l.usageEmpty);
    final admin = rows.any((row) => row.user != null);
    String time(DateTime value) =>
        DateFormat.yMMMd(l.localeName).add_Hms().format(value.toLocal());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FluentTable(
          key: const Key('events-table'),
          columns: [
            TableColumnSpec(l.usageRequest, width: 200),
            TableColumnSpec(l.usageOutput, width: 200),
            if (admin) TableColumnSpec(l.usageUser, width: 140),
            TableColumnSpec(l.usageModel, width: 180),
            TableColumnSpec(l.usageRole, width: 110),
            TableColumnSpec(l.usageInputTokens, numeric: true, width: 120),
            TableColumnSpec(l.usageOutputTokens, numeric: true, width: 120),
            TableColumnSpec(l.usageTotalTokens, numeric: true, width: 120),
            TableColumnSpec(l.usageStarted, width: 190),
            TableColumnSpec(l.usageFinished, width: 190),
          ],
          rows: [
            for (final row in rows)
              [
                SelectableText(
                  row.cursor,
                  maxLines: 1,
                  style: TextStyles.code.copyWith(
                    color: Palette.from(context).text,
                  ),
                ),
                SelectableText(
                  row.output,
                  maxLines: 1,
                  style: TextStyles.code.copyWith(
                    color: Palette.from(context).text,
                  ),
                ),
                if (admin)
                  Text(
                    row.user?.isNotEmpty == true ? row.user! : l.usageNoUser,
                  ),
                Text(row.model, overflow: TextOverflow.ellipsis),
                Text(row.role),
                Text(number(l, row.input)),
                Text(number(l, row.outputTokens)),
                Text(number(l, row.total)),
                Text(time(row.started)),
                Text(time(row.finished)),
              ],
          ],
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: Space.s16),
            // "Load more": secondary, centered under the table (#67).
            child: Center(
              child: AppButton(
                key: const Key('events-more'),
                label: l.loadMore,
                busy: loading,
                onPressed: more,
              ),
            ),
          ),
      ],
    );
  }
}
