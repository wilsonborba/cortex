import '../../handlers/process_messages.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../dal/remote/cortex_api.dart';
import '../../../../domain/models/api.dart';
import '../../../../domain/models/persona.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../basic_pages.dart';
import 'schema_fields.dart';

class PersonaForm extends StatefulWidget {
  const PersonaForm({super.key, required this.api, this.id, this.onChanged});
  final CortexApi api;
  final String? id;
  final VoidCallback? onChanged;
  @override
  State<PersonaForm> createState() => _PersonaFormState();
}

class _PersonaFormState extends State<PersonaForm> {
  final name = TextEditingController();
  String type = 'person';
  List<String> aliases = [];
  bool isSelf = false;
  Map<String, dynamic> attributes = {};
  PersonaSchema? schema;
  ApiError? error;
  bool loading = true;
  bool busy = false;
  bool notFound = false;
  int request = 0;
  @override
  void initState() {
    super.initState();
    scheduleLoad();
  }

  @override
  void didUpdateWidget(PersonaForm old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id || old.api != widget.api) scheduleLoad();
  }

  void scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final current = ++request;
    setState(() {
      loading = true;
      error = null;
      notFound = false;
    });
    try {
      final persona = widget.id == null
          ? null
          : await widget.api.persona(widget.id!);
      final nextType = persona?.type ?? type;
      final nextSchema = await widget.api.personaSchema(nextType);
      if (!mounted || current != request) return;
      setState(() {
        type = nextType;
        schema = nextSchema;
        name.text = persona?.name ?? name.text;
        aliases = persona == null ? aliases : [...persona.aliases];
        isSelf = persona?.isSelf ?? isSelf;
        attributes = persona == null
            ? newAttributes(nextSchema.fields)
            : (jsonDecode(jsonEncode(persona.attributes)) as Map).cast();
        loading = false;
      });
    } on ApiError catch (e) {
      if (mounted && current == request) {
        setState(() {
          error = e;
          loading = false;
          notFound = widget.id != null && e.status == 404;
        });
      }
    } catch (_) {
      if (mounted && current == request) {
        setState(() {
          error = const ApiError(0, null, '');
          loading = false;
        });
      }
    }
  }

  Future<void> changeType(String value) async {
    final current = ++request;
    setState(() {
      type = value;
      schema = null;
      attributes = {};
      loading = true;
      error = null;
    });
    try {
      final next = await widget.api.personaSchema(value);
      if (!mounted || current != request) return;
      setState(() {
        schema = next;
        attributes = newAttributes(next.fields);
        loading = false;
      });
    } on ApiError catch (e) {
      if (mounted && current == request) {
        setState(() {
          error = e;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted && current == request) {
        setState(() {
          error = const ApiError(0, null, '');
          loading = false;
        });
      }
    }
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.api.savePersona(
        id: widget.id,
        type: type,
        name: name.text,
        aliases: aliases,
        isSelf: isSelf,
        attributes: attributes,
      );
      if (!mounted) return;
      widget.onChanged?.call();
      setState(() {
        busy = false;
        name.text = result.name;
        aliases = [...result.aliases];
        isSelf = result.isSelf;
        attributes = result.attributes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).personaSaved)),
      );
      if (widget.id == null) {
        context.go('/v1/personas/${Uri.encodeComponent(result.id)}');
      }
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = const ApiError(0, null, '');
        });
      }
    }
  }

  Future<void> remove() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deletePersona),
        content: Text(l.deletePersonaConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          AppButton.destructive(
            label: l.delete,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.api.deletePersona(widget.id!);
      if (!mounted) return;
      widget.onChanged?.call();
      context.go('/v1/personas');
    } on ApiError catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = e;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = const ApiError(0, null, '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (notFound) return const NotFoundPage();
    if (loading) return const Center(child: SkeletonBox(width: 240));
    if (schema == null) {
      return ErrorState(
        message: apiFailure(l, error),
        retryLabel: l.retry,
        onRetry: load,
      );
    }
    final errors = error?.fieldErrors ?? const <String, String>{};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Space.s16),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.id == null ? l.newPersona : l.editPersona,
                style: TextStyles.subsection,
              ),
              const SizedBox(height: Space.s16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s16),
                  child: Text(
                    apiFailure(l, error),
                    style: TextStyle(
                      color: Palette.of(Theme.of(context).brightness).danger,
                    ),
                  ),
                ),
              if (widget.id == null)
                DropdownButtonFormField<String>(
                  key: const Key('persona-type'),
                  initialValue: type,
                  decoration: InputDecoration(labelText: l.personaType),
                  items: [
                    DropdownMenuItem(
                      value: 'person',
                      child: Text(l.personType),
                    ),
                    DropdownMenuItem(value: 'bot', child: Text(l.botType)),
                  ],
                  onChanged: busy ? null : (value) => changeType(value!),
                )
              else
                Text(
                  type == 'bot' ? l.botType : l.personType,
                  style: TextStyles.label,
                ),
              const SizedBox(height: Space.s16),
              TextField(
                key: const Key('persona-name'),
                controller: name,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: '${l.personaName} *',
                  errorText: fieldError(
                    l,
                    errors['name'] ?? errors['canonical_name'],
                  ),
                ),
              ),
              const SizedBox(height: Space.s16),
              ListField(
                key: const Key('persona-aliases'),
                label: l.personaAliases,
                enabled: !busy,
                value: aliases,
                onChanged: (value) =>
                    setState(() => aliases = value.cast<String>()),
                error: fieldError(
                  l,
                  errors.entries
                      .where((entry) => entry.key.startsWith('aliases'))
                      .firstOrNull
                      ?.value,
                ),
              ),
              SwitchListTile(
                key: const Key('persona-self'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.personaIsSelf),
                value: isSelf,
                onChanged: busy
                    ? null
                    : (value) => setState(() => isSelf = value),
              ),
              Text(l.personaRequiredLegend, style: TextStyles.label),
              const SizedBox(height: Space.s12),
              SchemaFields(
                key: ValueKey('$type-${schema!.version}-${widget.id}'),
                fields: schema!.fields,
                enabled: !busy,
                values: attributes,
                errors: errors,
                onChanged: () => setState(() {}),
              ),
              Wrap(
                spacing: Space.s12,
                runSpacing: Space.s12,
                children: [
                  AppButton(
                    key: const Key('save-persona'),
                    label: l.save,
                    busy: busy,
                    onPressed: save,
                  ),
                  if (widget.id != null)
                    AppButton.destructive(
                      key: const Key('delete-persona'),
                      label: l.deletePersona,
                      onPressed: busy ? null : remove,
                    ),
                  TextButton(
                    onPressed: busy ? null : () => context.go('/v1/personas'),
                    child: Text(l.cancel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
