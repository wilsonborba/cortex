class UsageData {
  const UsageData(this.windowHours, this.tokens, this.items, this.weight);
  factory UsageData.fromJson(Map<String, dynamic> value) => UsageData(
    (value['window_hours'] as num).toInt(),
    (value['tokens'] as Map).cast<String, num>(),
    (value['items'] as Map).cast<String, num>(),
    (value['loyalty_weight'] as Map).cast<String, num?>(),
  );
  final int windowHours;
  final Map<String, num> tokens, items;
  final Map<String, num?> weight;
}

class RunKind {
  const RunKind(this.webMode, this.thinking);
  factory RunKind.fromJson(Map<String, dynamic> value) =>
      RunKind(value['web_mode'] as String, value['thinking'] as bool);
  final String webMode;
  final bool thinking;
}

class TimingAverage {
  const TimingAverage(this.kind, this.milliseconds);
  factory TimingAverage.fromJson(Map<String, dynamic> value) => TimingAverage(
    RunKind.fromJson((value['kind'] as Map).cast()),
    (value['expected_ms'] as num?)?.toDouble(),
  );
  final RunKind kind;
  final double? milliseconds;
}

class GroupStats {
  const GroupStats(this.kind, this.values);
  factory GroupStats.fromJson(Map<String, dynamic> value) =>
      GroupStats(RunKind.fromJson((value['kind'] as Map).cast()), {
        for (final entry in value.entries)
          if (entry.value is num) entry.key: entry.value as num,
      });
  final RunKind kind;
  final Map<String, num> values;
}

class CallEvent {
  const CallEvent(
    this.cursor,
    this.output,
    this.user,
    this.model,
    this.role,
    this.input,
    this.outputTokens,
    this.total,
    this.started,
    this.finished,
  );
  factory CallEvent.fromJson(Map<String, dynamic> value) => CallEvent(
    value['request_id'] as String,
    value['output_id'] as String,
    value['user_id'] as String?,
    value['model'] as String,
    value['role'] as String,
    (value['input_tokens'] as num).toInt(),
    (value['output_tokens'] as num).toInt(),
    (value['total_tokens'] as num).toInt(),
    DateTime.parse(value['started_at'] as String),
    DateTime.parse(value['finished_at'] as String),
  );
  final String cursor, output, model, role;
  final String? user;
  final int input, outputTokens, total;
  final DateTime started, finished;
}

enum UsageView { usage, timing, stats, events }
