import '../../theme/app_icons.dart';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/services/persona_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import 'schema_fields.dart';

class PersonaList extends StatefulWidget {
  const PersonaList({super.key, required this.controller});
  final PersonaController controller;
  @override
  State<PersonaList> createState() => _PersonaListState();
}

class _PersonaListState extends State<PersonaList> {
  PersonaController get personas => widget.controller;
  @override
  void initState() {
    super.initState();
    personas.addListener(changed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) personas.load();
    });
  }

  @override
  void dispose() {
    personas.removeListener(changed);
    super.dispose();
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    final items = personas.items;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.s16),
          child: Wrap(
            spacing: Space.s12,
            runSpacing: Space.s12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextFormField(
                  initialValue: personas.query,
                  decoration: InputDecoration(
                    labelText: l.searchPersonas,
                    suffixIcon: IconButton(
                      tooltip: l.searchPersonas,
                      onPressed: personas.load,
                      icon: const Icon(AppIcons.search),
                    ),
                  ),
                  onChanged: (value) => personas.query = value,
                  onFieldSubmitted: (_) => personas.load(),
                ),
              ),
              FoundationFocus(
                child: DropdownButton<String>(
                  key: const Key('persona-filter'),
                  value: personas.type ?? 'all',
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(l.allPersonaTypes),
                    ),
                    DropdownMenuItem(
                      value: 'person',
                      child: Text(l.personType),
                    ),
                    DropdownMenuItem(value: 'bot', child: Text(l.botType)),
                  ],
                  onChanged: (value) {
                    personas.type = value == 'all' ? null : value;
                    personas.load();
                  },
                ),
              ),
              AppButton(
                label: l.newPersona,
                icon: AppIcons.add,
                onPressed: () => context.go('/v1/personas/new'),
              ),
            ],
          ),
        ),
        if (personas.loading && items != null) const SkeletonBox(height: 4),
        if (personas.error != null && items != null)
          Padding(
            padding: const EdgeInsets.all(Space.s12),
            child: ErrorState(
              message: apiFailure(l, personas.error),
              retryLabel: l.retry,
              onRetry: personas.load,
            ),
          ),
        Expanded(
          child: items == null
              ? personas.error == null
                    ? const Center(child: SkeletonBox(width: 240))
                    : ErrorState(
                        message: apiFailure(l, personas.error),
                        retryLabel: l.retry,
                        onRetry: personas.load,
                      )
              : items.isEmpty
              ? EmptyState(title: l.noPersonas, icon: AppIcons.entity)
              : ListView.separated(
                  padding: const EdgeInsets.all(Space.s16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Space.s12),
                  itemBuilder: (context, index) {
                    final persona = items[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      color: p.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          FoundationTokens.of(context).groupRadius,
                        ),
                        side: BorderSide(color: p.border),
                      ),
                      child: FoundationFocus(
                        child: InkWell(
                          key: Key('persona-${persona.id}'),
                          onTap: () => context.go(
                            '/v1/personas/${Uri.encodeComponent(persona.id)}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(Space.s16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: Space.s8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(
                                      persona.type == 'bot'
                                          ? AppIcons.bot
                                          : AppIcons.entity,
                                    ),
                                    Text(
                                      persona.name,
                                      style: TextStyles.subsection,
                                    ),
                                    if (persona.isSelf)
                                      Chip(label: Text(l.you)),
                                  ],
                                ),
                                Text(
                                  persona.type == 'bot'
                                      ? l.botType
                                      : l.personType,
                                  style: TextStyles.label,
                                ),
                                if (persona.aliases.isNotEmpty)
                                  Wrap(
                                    spacing: Space.s8,
                                    children: [
                                      for (final alias in persona.aliases)
                                        Chip(label: Text(alias)),
                                    ],
                                  ),
                                if (persona.attributes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: Space.s8,
                                    ),
                                    child: Text(
                                      persona.attributes.entries
                                          .map(
                                            (e) =>
                                                '${e.key}: ${personaValue(e.value, l)}',
                                          )
                                          .join('\n'),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.compact,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
