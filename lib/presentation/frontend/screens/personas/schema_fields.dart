import '../../theme/app_icons.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/persona.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/surfaces.dart';

String personaValue(Object? value, AppLocalizations l) {
  if (value == null) return '';
  if (value is bool) return value ? l.personaYes : l.personaNo;
  if (value is num) {
    return NumberFormat.decimalPattern(l.localeName).format(value);
  }
  if (value is List) {
    return value.map((item) => personaValue(item, l)).join(', ');
  }
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${personaValue(entry.value, l)}')
        .join(', ');
  }
  return value.toString();
}

String? fieldError(AppLocalizations l, String? message) {
  if (message == null) return null;
  final text = message.toLowerCase();
  if (text.contains('required') || text.contains('missing')) {
    return l.personaFieldRequired;
  }
  if (text.contains('unknown') || text.contains('undeclared')) {
    return l.personaFieldUnknown;
  }
  if (text.contains('type')) return l.personaFieldType;
  return l.personaFieldInvalid;
}

Map<String, dynamic> newAttributes(
  List<PersonaField> fields, {
  String prefix = '',
}) {
  final values = <String, dynamic>{};
  for (final field in fields) {
    if (!field.name.startsWith(prefix)) continue;
    final name = field.name.substring(prefix.length);
    if (name.contains('.') || name.contains('[]')) continue;
    if (field.type == 'boolean') values[name] = false;
    if (field.type == 'array') values[name] = <Object?>[];
    if (field.type == 'object') {
      values[name] = newAttributes(fields, prefix: '${field.name}.');
    }
  }
  return values;
}

/// Render declared fields. The API is the validator; this widget only edits
/// values and converts native number/date controls to their JSON types.
class SchemaFields extends StatelessWidget {
  const SchemaFields({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.errors = const {},
    this.prefix = '',
    this.enabled = true,
    this.focusFor,
  });
  final FocusNode Function(String)? focusFor;
  final List<PersonaField> fields;
  final Map<String, dynamic> values;
  final VoidCallback onChanged;
  final Map<String, String> errors;
  final String prefix;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final direct = fields.where(
      (field) =>
          field.name.startsWith(prefix) &&
          !field.name.substring(prefix.length).contains('.') &&
          !field.name.substring(prefix.length).contains('[]'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final field in direct)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!['boolean', 'object', 'array'].contains(field.type)) ...[
                  Text(
                    '${field.name.substring(prefix.length)}${field.required ? ' *' : ''}',
                    style: TextStyles.label,
                  ),
                  const SizedBox(height: Space.s8),
                ],
                Builder(
                  builder: (context) {
                    final name = field.name.substring(prefix.length);
                    final label = '$name${field.required ? ' *' : ''}';
                    final value = values[name];
                    final error =
                        errors[field.name] ??
                        errors['attributes.${field.name}'] ??
                        errors.entries
                            .where(
                              (e) => e.key
                                  .replaceFirst('attributes.', '')
                                  .startsWith('${field.name}['),
                            )
                            .firstOrNull
                            ?.value;
                    void change(Object? value) {
                      if (value == null) {
                        values.remove(name);
                      } else {
                        values[name] = value;
                      }
                      onChanged();
                    }

                    final decoration = InputDecoration(
                      errorText: fieldError(l, error),
                    );
                    final key = Key('attribute-${field.name}');
                    switch (field.type) {
                      case 'boolean':
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FoundationFocus(
                              child: SwitchListTile(
                                key: key,
                                focusNode: focusFor?.call(field.name),
                                contentPadding: EdgeInsets.zero,
                                title: Text(label),
                                value: value == true,
                                onChanged: enabled ? change : null,
                              ),
                            ),
                            if (error != null)
                              Text(
                                fieldError(l, error)!,
                                style: TextStyle(
                                  color: Palette.from(context).dangerForeground,
                                ),
                              ),
                          ],
                        );
                      case 'array':
                        return ListField(
                          key: key,
                          focusNode: focusFor?.call(field.name),
                          focusFor: focusFor,
                          enabled: enabled,
                          label: label,
                          value: (value as List? ?? const []).cast<Object?>(),
                          onChanged: change,
                          error: fieldError(l, error),
                          itemFields: fields
                              .where(
                                (f) => f.name.startsWith('${field.name}[].'),
                              )
                              .toList(),
                          prefix: '${field.name}[].',
                          errors: errors,
                        );
                      case 'object':
                        final nested = (value as Map? ?? <String, dynamic>{})
                            .cast<String, dynamic>();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(label, style: TextStyles.compact),
                            if (error != null) Text(fieldError(l, error)!),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: Space.s12,
                                top: Space.s8,
                              ),
                              child: SchemaFields(
                                fields: fields,
                                enabled: enabled,
                                values: nested,
                                prefix: '${field.name}.',
                                focusFor: focusFor,
                                errors: errors,
                                onChanged: () => change(nested),
                              ),
                            ),
                          ],
                        );
                      case 'date':
                      case 'datetime':
                        Future<void> pick() async {
                          final original =
                              DateTime.tryParse('$value')?.toLocal() ??
                              DateTime.now();
                          final day = await showDatePicker(
                            context: context,
                            initialDate: original,
                            firstDate: DateTime(1),
                            lastDate: DateTime(9999, 12, 31),
                          );
                          if (day == null || !context.mounted) return;
                          if (field.type == 'datetime') {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(original),
                            );
                            if (time != null && context.mounted) {
                              change(
                                DateTime(
                                  day.year,
                                  day.month,
                                  day.day,
                                  time.hour,
                                  time.minute,
                                ).toUtc().toIso8601String(),
                              );
                            }
                          } else {
                            change(
                              '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
                            );
                          }
                        }
                        return TextFormField(
                          key: ValueKey('${field.name}-$value'),
                          focusNode: focusFor?.call(field.name),
                          initialValue: value?.toString() ?? '',
                          enabled: enabled,
                          readOnly: true,
                          decoration: decoration.copyWith(
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: l.choosePersonaDate,
                                  onPressed: enabled ? pick : null,
                                  icon: const Icon(AppIcons.calendar),
                                ),
                                if (value != null)
                                  IconButton(
                                    tooltip: l.clear,
                                    onPressed: enabled
                                        ? () => change(null)
                                        : null,
                                    icon: const Icon(AppIcons.close),
                                  ),
                              ],
                            ),
                          ),
                          onTap: enabled ? pick : null,
                        );
                      default:
                        final numeric =
                            field.type == 'integer' || field.type == 'float';
                        return TextFormField(
                          key: key,
                          focusNode: focusFor?.call(field.name),
                          enabled: enabled,
                          initialValue: value == null
                              ? ''
                              : value is num
                              ? NumberFormat.decimalPattern(
                                  l.localeName,
                                ).format(value)
                              : value.toString(),
                          keyboardType: numeric
                              ? const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                )
                              : TextInputType.text,
                          decoration: decoration.copyWith(
                            helperText: field.type == 'integer'
                                ? l.personaInteger
                                : numeric
                                ? l.personaNumber
                                : null,
                          ),
                          onChanged: (text) {
                            if (!numeric) {
                              change(text);
                              return;
                            }
                            num? parsed;
                            try {
                              parsed = NumberFormat.decimalPattern(
                                l.localeName,
                              ).parse(text);
                            } catch (_) {}
                            change(
                              parsed != null && parsed.isFinite ? parsed : text,
                            );
                          },
                        );
                    }
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ListField extends StatefulWidget {
  const ListField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
    this.itemFields = const [],
    this.prefix = '',
    this.enabled = true,
    this.errors = const {},
    this.focusNode,
    this.focusFor,
  });
  final FocusNode? focusNode;
  final FocusNode Function(String)? focusFor;
  final Map<String, String> errors;
  final String label;
  final List<Object?> value;
  final ValueChanged<List<Object?>> onChanged;
  final String? error;
  final List<PersonaField> itemFields;
  final String prefix;
  final bool enabled;
  @override
  State<ListField> createState() => _ListFieldState();
}

class _ListFieldState extends State<ListField> {
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> add({int? index}) async {
    Object? value;
    if (widget.itemFields.isEmpty) {
      if (text.text.isEmpty) return;
      value = text.text;
    } else {
      final fields = index != null && widget.value[index] is Map
          ? (jsonDecode(jsonEncode(widget.value[index])) as Map)
                .cast<String, dynamic>()
          : newAttributes(widget.itemFields, prefix: widget.prefix);
      value = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) {
          final l = AppLocalizations.of(context);
          return StatefulBuilder(
            builder: (context, refresh) => AppDialog(
              title: widget.label,
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: SchemaFields(
                    fields: widget.itemFields,
                    values: fields,
                    prefix: widget.prefix,
                    focusFor: widget.focusFor,
                    errors: index == null
                        ? const {}
                        : {
                            for (final entry in widget.errors.entries)
                              if (entry.key
                                  .replaceFirst('attributes.', '')
                                  .startsWith(
                                    '${widget.prefix.substring(0, widget.prefix.length - 3)}[$index].',
                                  ))
                                entry.key
                                        .replaceFirst('attributes.', '')
                                        .replaceFirst('[$index].', '[].'):
                                    entry.value,
                          },
                    onChanged: () => refresh(() {}),
                  ),
                ),
              ),
              actions: [
                AppButton.primary(
                  label: l.addPersonaItem,
                  onPressed: () => Navigator.pop(context, fields),
                ),
                AppButton(
                  label: l.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      );
      if (value == null) return;
    }
    final next = [...widget.value];
    if (index == null) {
      next.add(value);
    } else {
      next[index] = value;
    }
    widget.onChanged(next);
    text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: TextStyles.label),
        const SizedBox(height: Space.s8),
        InputDecorator(
          decoration: InputDecoration(errorText: widget.error),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: Space.s8,
                children: [
                  for (var i = 0; i < widget.value.length; i++)
                    InputChip(
                      visualDensity: Controls.tagDensity,
                      label: Text(
                        personaValue(widget.value[i], l),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: widget.enabled && widget.itemFields.isNotEmpty
                          ? () => add(index: i)
                          : null,
                      deleteButtonTooltipMessage: l.removePersonaItem,
                      onDeleted: widget.enabled
                          ? () {
                              final next = [...widget.value]..removeAt(i);
                              widget.onChanged(next);
                            }
                          : null,
                    ),
                ],
              ),
              if (widget.itemFields.isEmpty)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: text,
                        focusNode: widget.focusNode,
                        enabled: widget.enabled,
                        decoration: InputDecoration(
                          hintText: l.addPersonaItem,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => add(),
                      ),
                    ),
                    IconButton(
                      tooltip: l.addPersonaItem,
                      onPressed: widget.enabled ? add : null,
                      icon: const Icon(AppIcons.add),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    focusNode: widget.focusNode,
                    onPressed: widget.enabled ? add : null,
                    icon: const Icon(AppIcons.add),
                    label: Text(l.addPersonaItem),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
