/// Mirrors cortex_api's native `POST /execute` response schema (see
/// `lib/presentation/api/schemas/execute.py`, `ExecuteResponse`). `steps` is
/// intentionally not modeled: the chat UI only surfaces the final answer,
/// per-driver step telemetry is out of scope for this client.
class ExecuteResponse {
  const ExecuteResponse({
    required this.requestId,
    required this.tierRequested,
    required this.tierExecuted,
    required this.strategyId,
    required this.taskType,
    required this.success,
    required this.response,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.costUsd,
    required this.latencyMs,
    this.errorType,
  });

  factory ExecuteResponse.fromJson(Map<String, dynamic> json) {
    return ExecuteResponse(
      requestId: json['request_id'] as String? ?? '',
      tierRequested: json['tier_requested'] as int? ?? 0,
      tierExecuted: json['tier_executed'] as int? ?? 0,
      strategyId: json['strategy_id'] as String? ?? '',
      taskType: json['task_type'] as String? ?? '',
      success: json['success'] as bool? ?? false,
      response: json['response'] as String? ?? '',
      inputTokens: json['input_tokens'] as int? ?? 0,
      outputTokens: json['output_tokens'] as int? ?? 0,
      totalTokens: json['total_tokens'] as int? ?? 0,
      costUsd: (json['cost_usd'] as num?)?.toDouble() ?? 0.0,
      latencyMs: json['latency_ms'] as int? ?? 0,
      errorType: json['error_type'] as String?,
    );
  }

  final String requestId;
  final int tierRequested;
  final int tierExecuted;
  final String strategyId;
  final String taskType;
  final bool success;
  final String response;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final double costUsd;
  final int latencyMs;
  final String? errorType;
}
