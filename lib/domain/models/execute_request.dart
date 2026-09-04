/// Mirrors cortex_api's native `POST /execute` request schema (see
/// `lib/presentation/api/schemas/execute.py`, `ExecuteRequest` /
/// `CapabilitySchema`). Only the fields this client actually sends are
/// modeled; every other field on the real schema has a server-side default
/// and is simply omitted here rather than faked.
///
/// `tier`, `force_model`, `force_provider` and `override_strategy` are
/// intentionally not exposed at all: the api_for_apps proxy strips/rewrites
/// them server-side to keep every call on Tier 0 (see its
/// `_EXECUTE_ESCAPE_HATCHES` in `cortex_route.py`), so this client never
/// offers a way to set them in the first place.
class ExecuteRequest {
  const ExecuteRequest({
    required this.prompt,
    this.tenantId = 'default',
    this.taskType = 'general',
    this.useMemory = false,
  });

  final String prompt;
  final String tenantId;
  final String taskType;

  /// When true, requests memory-aware execution (server-side memory
  /// recall). Sent both as the top-level `use_memory` flag and inside
  /// `capabilities.memory`, matching how cortex_api's own OR-ed routing
  /// (`payload.capabilities.memory or payload.use_memory`) reads it.
  final bool useMemory;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'tenant_id': tenantId,
    'task_type': taskType,
    'use_memory': useMemory,
    'capabilities': {'memory': useMemory},
  };
}
