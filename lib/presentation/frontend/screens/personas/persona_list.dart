import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../domain/services/persona_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/states.dart';
import '../memory/memory_card.dart' show initials;

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
    final l = AppLocalizations.of(context),
        p = Palette.from(context),
        items = personas.items;
    void create() => context.go('/v1/personas/new');
    final search = TextFormField(
      key: const Key('persona-search'),
      initialValue: personas.query,
      style: TextStyles.body,
      decoration: InputDecoration(
        hintText: l.searchPersonas,
        prefixIcon: const Icon(AppIcons.search, size: IconSizes.action),
        suffixIcon: IconButton(
          tooltip: l.searchPersonas,
          onPressed: personas.load,
          icon: const Icon(AppIcons.next, size: IconSizes.action),
        ),
      ),
      onChanged: (value) => personas.query = value,
      onFieldSubmitted: (_) => personas.load(),
    );
    final types = SegmentedButton<String>(
      key: const Key('persona-filter'),
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      segments: [
        for (final (value, label) in [
          ('all', l.allPersonaTypes),
          ('person', l.personType),
          ('bot', l.botType),
        ])
          ButtonSegment(
            value: value,
            label: Text(
              label,
              style: TextStyles.label,
              textAlign: TextAlign.center,
            ),
          ),
      ],
      selected: {personas.type ?? 'all'},
      onSelectionChanged: (value) {
        personas.type = value.first == 'all' ? null : value.first;
        personas.load();
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(Space.s16),
          child: LayoutBuilder(
            builder: (context, box) {
              final heading = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.personas, style: TextStyles.section),
                  const SizedBox(height: Space.s4),
                  Text(
                    l.personasPurpose,
                    style: TextStyles.compact.copyWith(color: p.muted),
                  ),
                ],
              );
              final action = AppButton.primary(
                label: l.newPersona,
                icon: AppIcons.add,
                onPressed: create,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (SizeClass.of(box.maxWidth) == SizeClass.compact) ...[
                    heading,
                    const SizedBox(height: Space.s16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: action,
                    ),
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: Space.s16),
                        action,
                      ],
                    ),
                  const SizedBox(height: Space.s24),
                  if (SizeClass.of(box.maxWidth) == SizeClass.compact) ...[
                    search,
                    const SizedBox(height: Space.s12),
                    types,
                  ] else
                    Row(
                      children: [
                        Expanded(child: search),
                        const SizedBox(width: Space.s16),
                        Flexible(child: types),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
        if (personas.loading && items != null) const LinearProgressIndicator(),
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
                    ? const Center(
                        child: SkeletonBox(width: Space.sidebarWidth),
                      )
                    : ErrorState(
                        message: apiFailure(l, personas.error),
                        retryLabel: l.retry,
                        onRetry: personas.load,
                      )
              : items.isEmpty
              ? EmptyState(
                  title: personas.query.isNotEmpty || personas.type != null
                      ? l.noPersonaMatches
                      : l.noPersonas,
                  icon: AppIcons.personas,
                  action: personas.query.isEmpty && personas.type == null
                      ? AppButton(
                          label: l.newPersona,
                          icon: AppIcons.add,
                          onPressed: create,
                        )
                      : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s16,
                    vertical: Space.s8,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: p.border, height: Space.s16),
                  itemBuilder: (context, index) {
                    final persona = items[index];
                    return FoundationFocus(
                      child: ListTile(
                        key: Key('persona-${persona.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Space.s8,
                          vertical: Space.s8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: p.surface,
                          foregroundColor: p.text,
                          child: Text(
                            initials(persona.name),
                            style: TextStyles.label,
                          ),
                        ),
                        title: Text(
                          persona.name,
                          style: TextStyles.compact,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: Space.s8,
                              children: [
                                Text(
                                  persona.type == 'bot'
                                      ? l.botType
                                      : l.personType,
                                  style: TextStyles.label.copyWith(
                                    color: p.muted,
                                  ),
                                ),
                                if (persona.isSelf)
                                  Text(
                                    l.you,
                                    style: TextStyles.label.copyWith(
                                      color: p.muted,
                                    ),
                                  ),
                              ],
                            ),
                            if (persona.aliases.isNotEmpty)
                              Text(
                                persona.aliases.join(', '),
                                style: TextStyles.compact.copyWith(
                                  color: p.muted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () => context.go(
                          '/v1/personas/${Uri.encodeComponent(persona.id)}',
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
