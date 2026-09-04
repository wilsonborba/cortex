import 'attachment.dart';

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
    this.needsWeb = false,
    this.temporary = false,
    this.attachments = const [],
    this.attachmentJobId,
  });

  final String prompt;
  final String tenantId;
  final String taskType;

  /// When true, requests memory-aware execution (server-side memory
  /// recall). Sent both as the top-level `use_memory` flag and inside
  /// `capabilities.memory`, matching how cortex_api's own OR-ed routing
  /// (`payload.capabilities.memory or payload.use_memory`) reads it.
  final bool useMemory;

  /// When true, requests web-search grounding for this call. Sent both as
  /// the top-level `needs_web` flag and inside `capabilities.web`, mirroring
  /// how cortex_api reads `payload.capabilities.web or payload.needs_web`
  /// (see `lib/presentation/api/routes/execute.py`).
  final bool needsWeb;

  /// Incognito/temporary-session flag: forwarded as `capabilities.temporary`
  /// on cortex_api's real `CapabilitySchema`. Incognito requests must never
  /// set [useMemory]; the caller is responsible for that (see
  /// `ChatService.sendEphemeralMessage`), this flag alone does not disable
  /// memory server-side.
  final bool temporary;

  /// Files attached from the prompt dock, encoded exactly like cortex_api's
  /// `Attachment` schema (`filename`, `mime_type`, `data_base64`). See
  /// [ChatAttachment.isAcceptedByBackendToday]: only `image/...` and
  /// `audio/...` are accepted by cortex_api's ingestion today, anything
  /// else (documents) is included here per the real schema shape but is
  /// expected to be rejected server-side until document ingestion ships.
  final List<ChatAttachment> attachments;

  /// Id of a finished `/attachments/video` job whose summary to inject as
  /// context. Not produced by this client yet (no video upload flow), the
  /// field is modeled so a future upload step can set it without another
  /// schema change.
  final String? attachmentJobId;

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'tenant_id': tenantId,
    'task_type': taskType,
    'use_memory': useMemory,
    'needs_web': needsWeb,
    'capabilities': {
      'memory': useMemory,
      'web': needsWeb,
      'temporary': temporary,
    },
    if (attachments.isNotEmpty)
      'attachments': attachments.map((a) => a.toJson()).toList(),
    if (attachmentJobId != null) 'attachment_job_id': attachmentJobId,
  };
}
