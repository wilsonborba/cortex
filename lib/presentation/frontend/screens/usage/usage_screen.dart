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
          padding: const EdgeInsets.all(Space.s12),
          child: Wrap(
            spacing: Space.s8,
            children: [
              for (final view in UsageView.values)
                TextButton(
                  onPressed: view == widget.view
                      ? null
                      : () => context.go(
                          view == UsageView.usage
                              ? '/v1/usage'
                              : '/v1/usage/${view.name}',
                        ),
                  child: Semantics(
                    selected: view == widget.view,
                    child: Text(viewTitle(l, view)),
                  ),
                ),
            ],
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

class UsageSummary extends StatelessWidget {
  const UsageSummary({super.key, required this.data});
  final UsageData data;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final weight = data.weight;
    Widget row(String title, num? value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Space.s8),
      child: Text(
        '$title: ${value == null ? l.notAvailableYet : number(l, value)}',
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.usageWindow(data.windowHours), style: TextStyles.subsection),
        row(l.usageInputTokens, data.tokens['input']),
        row(l.usageOutputTokens, data.tokens['output']),
        row(l.usageTotalTokens, data.tokens['total']),
        row(l.usageImages, data.items['images']),
        row(l.usageAudio, data.items['audio']),
        const SizedBox(height: Space.s24),
        Text(l.usagePriority, style: TextStyles.subsection),
        Text(l.usagePriorityHelp),
        row(l.usageWeight, weight['value']),
        row(l.usageAccountAge, weight['age']),
        row(l.usageFrequency, weight['frequency']),
        row(l.usageAccountDays, weight['account_days']),
        row(l.usageSignInDays, weight['sign_in_days_90']),
        Text(l.usageWeightFormula),
      ],
    );
  }
}

class TimingTable extends StatelessWidget {
  const TimingTable({super.key, required this.rows});
  final List<TimingAverage> rows;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (rows.isEmpty) return EmptyState(title: l.usageEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.timing, style: TextStyles.subsection),
        Text(l.usageTimingHelp),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s12),
            child: Text(
              '${kindTitle(l, row.kind)}: ${row.milliseconds == null ? l.notAvailableYet : seconds(l, row.milliseconds! / 1000)}',
            ),
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
    final p = Palette.of(Theme.of(context).brightness);
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
        const SizedBox(height: Space.s24),
        // One series at a time keeps this chart monochrome. The text rows are
        // also available to screen readers and at large text sizes.
        ExcludeSemantics(
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                minY: 0,
                gridData: const FlGridData(show: false),
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
                      getTitlesWidget: (value, meta) =>
                          Text('${value.toInt() + 1}', style: TextStyles.label),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(enabled: false),
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
                  : const Duration(milliseconds: 150),
            ),
          ),
        ),
        for (var i = 0; i < widget.rows.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s8),
            child: Text(
              '${i + 1}. ${kindTitle(l, widget.rows[i].kind)}: ${metricText(l, widget.rows[i], metric)}',
            ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: 56,
            dataRowMaxHeight: double.infinity,
            columns: [
              for (final title in [
                l.usageRequest,
                l.usageOutput,
                if (admin) l.usageUser,
                l.usageModel,
                l.usageRole,
                l.usageInputTokens,
                l.usageOutputTokens,
                l.usageTotalTokens,
                l.usageStarted,
                l.usageFinished,
              ])
                DataColumn(label: Text(title)),
            ],
            rows: [
              for (final row in rows)
                DataRow(
                  cells: [
                    DataCell(
                      SelectableText(
                        row.cursor,
                        style: const TextStyle(fontFamily: TextStyles.mono),
                      ),
                    ),
                    DataCell(
                      SelectableText(
                        row.output,
                        style: const TextStyle(fontFamily: TextStyles.mono),
                      ),
                    ),
                    if (admin)
                      DataCell(
                        Text(
                          row.user?.isNotEmpty == true
                              ? row.user!
                              : l.usageNoUser,
                        ),
                      ),
                    DataCell(Text(row.model)),
                    DataCell(Text(row.role)),
                    DataCell(Text(number(l, row.input))),
                    DataCell(Text(number(l, row.outputTokens))),
                    DataCell(Text(number(l, row.total))),
                    DataCell(Text(time(row.started))),
                    DataCell(Text(time(row.finished))),
                  ],
                ),
            ],
          ),
        ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.only(top: Space.s16),
            child: AppButton(
              key: const Key('events-more'),
              label: l.loadMore,
              busy: loading,
              onPressed: more,
            ),
          ),
      ],
    );
  }
}
