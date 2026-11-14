import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../dal/remote/cortex_api.dart';
import '../../../../domain/models/api.dart';
import '../../../../domain/models/persona.dart';
import '../../../../domain/services/persona_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/segmented_switch.dart';
import '../../widgets/common/states.dart';
import '../../widgets/common/surfaces.dart';
import 'persona_form.dart';
import 'schema_fields.dart' show personaValue;

const _base = '/v1/settings/personas';

/// Personas tab of Settings (#66): master and detail, like a contacts app.
/// The list is on the left (320); the detail, or the form, is on the right.
/// When the area is narrow, the list is the page and the detail and the form
/// are full pages.
class PersonasPage extends StatefulWidget {
  const PersonasPage({
    super.key,
    required this.controller,
    required this.api,
    this.id,
    this.edit = false,
    this.creating = false,
  });
  final PersonaController controller;
  final CortexApi api;
  final String? id;
  final bool edit, creating;
  @override
  State<PersonasPage> createState() => _PersonasPageState();
}

class _PersonasPageState extends State<PersonasPage> {
  PersonaController get c => widget.controller;
  late final _search = TextEditingController(text: c.query);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Widget _avatar(Palette p, Persona persona, double size) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: p.tagBackground, shape: BoxShape.circle),
    child: persona.type == 'bot'
        ? Icon(
            AppIcons.bot,
            size: size >= Space.s48 ? IconSizes.large : IconSizes.small,
            color: p.text2,
          )
        : Text(
            initials(persona.name),
            style:
                (size >= Space.s48
                        ? TextStyles.title3
                        : TextStyles.caption1Strong)
                    .copyWith(color: p.text),
          ),
  );

  Widget _you(Palette p, AppLocalizations l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.s4),
    decoration: BoxDecoration(
      color: p.selected,
      borderRadius: BorderRadius.circular(Radii.small),
    ),
    child: Text(
      l.you,
      style: TextStyles.caption1Strong.copyWith(color: p.text),
    ),
  );

  /// A list row (#66): 56 high, 32 px avatar, name `body1Strong`, the first
  /// alias or the role in `caption1` `muted`, and the "You" badge.
  Widget _row(AppLocalizations l, Palette p, Persona persona) {
    final selected = widget.id == persona.id;
    final second = persona.aliases.isNotEmpty
        ? persona.aliases.first
        : '${persona.attributes['role'] ?? (persona.type == 'bot' ? l.botType : l.personType)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s2),
      child: Material(
        color: selected ? p.selected : Colors.transparent,
        borderRadius: BorderRadius.circular(Radii.control),
        child: InkWell(
          key: Key('persona-${persona.id}'),
          borderRadius: BorderRadius.circular(Radii.control),
          hoverColor: p.subtleHover,
          onTap: () => context.go('$_base/${Uri.encodeComponent(persona.id)}'),
          child: Semantics(
            selected: selected,
            // 56 high; it grows with large text.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.s8,
                  vertical: Space.s4,
                ),
                child: Row(
                  children: [
                    _avatar(p, persona, Space.s32),
                    const SizedBox(width: Space.s12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  persona.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.body1Strong.copyWith(
                                    color: p.text,
                                  ),
                                ),
                              ),
                              if (persona.isSelf) ...[
                                const SizedBox(width: Space.s8),
                                _you(p, l),
                              ],
                            ],
                          ),
                          Text(
                            second,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.caption1.copyWith(color: p.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(AppLocalizations l, Palette p) {
    final items = c.items;
    return Column(
      key: const Key('persona-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.s8, 0, Space.s8, Space.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton.primary(
                key: const Key('new-persona'),
                label: l.newPersona,
                icon: AppIcons.add,
                size: ButtonSize.medium,
                onPressed: () => context.go('$_base/new'),
              ),
              const SizedBox(height: Space.s12),
              AppInput(
                key: const Key('persona-search'),
                controller: _search,
                hint: l.searchPersonas,
                onChanged: (v) => c.query = v,
                onSubmitted: (_) => c.load(),
              ),
              const SizedBox(height: Space.s8),
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedSwitch<String>(
                  key: const Key('persona-filter'),
                  label: l.personaType,
                  selected: c.type ?? 'all',
                  onChanged: (v) {
                    c.type = v == 'all' ? null : v;
                    c.load();
                  },
                  options: [
                    SegmentOption(
                      value: 'all',
                      text: l.allPersonaTypes,
                      tooltip: l.allPersonaTypes,
                    ),
                    SegmentOption(
                      value: 'person',
                      text: l.personaPeople,
                      tooltip: l.personaPeople,
                    ),
                    SegmentOption(
                      value: 'bot',
                      text: l.personaBots,
                      tooltip: l.personaBots,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (c.loading && items != null) const AppProgressBar(),
        Expanded(
          child: items == null
              ? c.error == null
                    ? const Center(child: SkeletonBox(width: 200))
                    : ErrorState(
                        message: apiFailure(l, c.error),
                        retryLabel: l.retry,
                        onRetry: c.load,
                      )
              : items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(Space.s16),
                  child: Text(
                    l.noPersonaMatches,
                    style: TextStyles.body1.copyWith(color: p.muted),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Space.s8,
                    Space.s4,
                    Space.s8,
                    Space.s16,
                  ),
                  children: [for (final x in items) _row(l, p, x)],
                ),
        ),
      ],
    );
  }

  Widget _right(AppLocalizations l, bool page) {
    if (widget.creating) {
      return PersonaForm(api: widget.api, onChanged: c.load);
    }
    if (widget.id != null && widget.edit) {
      return PersonaForm(api: widget.api, id: widget.id, onChanged: c.load);
    }
    if (widget.id != null) {
      return PersonaDetail(
        key: ValueKey('persona-detail-${widget.id}'),
        api: widget.api,
        id: widget.id!,
        page: page,
        onChanged: c.load,
      );
    }
    return Center(
      child: Text(
        l.personaSelect,
        style: TextStyles.body1.copyWith(color: Palette.from(context).muted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final items = c.items;
        final none =
            items != null &&
            items.isEmpty &&
            c.query.isEmpty &&
            c.type == null &&
            !c.loading;
        final open = widget.id != null || widget.creating;
        if (none && !open) {
          return EmptyState(
            key: const Key('persona-empty'),
            title: l.noPersonas,
            icon: AppIcons.personas,
            action: AppButton.primary(
              label: l.newPersona,
              icon: AppIcons.add,
              onPressed: () => context.go('$_base/new'),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, box) {
            final split = box.maxWidth >= 720;
            if (!split) {
              if (!open) return _list(l, p);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.s8),
                      child: AppButton(
                        key: const Key('persona-back'),
                        label: l.personaBack,
                        kind: ButtonKind.subtle,
                        size: ButtonSize.small,
                        onPressed: () => context.go(_base),
                      ),
                    ),
                  ),
                  Expanded(child: _right(l, true)),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 320, child: _list(l, p)),
                Container(width: Strokes.thin, color: p.divider),
                Expanded(child: _right(l, false)),
              ],
            );
          },
        );
      },
    );
  }
}

/// The persona detail (#66): 64 px avatar, name `title3`, type and aliases,
/// the attributes as a 2 column grid of facts, "Used in" from the memory
/// overview, and the actions Edit and Delete.
class PersonaDetail extends StatefulWidget {
  const PersonaDetail({
    super.key,
    required this.api,
    required this.id,
    this.page = false,
    this.onChanged,
  });
  final CortexApi api;
  final String id;
  final bool page;
  final VoidCallback? onChanged;
  @override
  State<PersonaDetail> createState() => _PersonaDetailState();
}

class _PersonaDetailState extends State<PersonaDetail> {
  Persona? persona;
  int? mentions;
  ApiError? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.api.persona(widget.id);
      if (!mounted) return;
      setState(() {
        persona = result;
        error = null;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() => error = e);
      return;
    } catch (_) {
      if (mounted) setState(() => error = const ApiError(0, null, ''));
      return;
    }
    // "Used in": the people facet of the memory overview (cortex_api #121).
    try {
      final overview = await widget.api.memoryOverview();
      final name = persona!.name.trim().toLowerCase();
      final aliases = persona!.aliases.map((a) => a.trim().toLowerCase());
      final hit = overview.peopleFacet
          .where(
            (f) =>
                f.label.trim().toLowerCase() == name ||
                aliases.contains(f.label.trim().toLowerCase()),
          )
          .firstOrNull;
      if (mounted) setState(() => mentions = hit?.count ?? 0);
    } catch (_) {}
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    if (!await showConfirmDialog(
      context,
      title: l.deletePersona,
      message: l.deletePersonaConfirm,
      confirm: l.delete,
      cancel: l.cancel,
      destructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    try {
      await widget.api.deletePersona(widget.id);
      if (!mounted) return;
      widget.onChanged?.call();
      context.go(_base);
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
    final p = Palette.from(context);
    final x = persona;
    if (x == null) {
      if (error == null) return const Center(child: AppSpinner(page: true));
      return ErrorState(
        message: apiFailure(l, error),
        retryLabel: l.retry,
        onRetry: _load,
      );
    }
    final facts = [
      for (final e in x.attributes.entries)
        if (e.value != null && '${e.value}'.isNotEmpty)
          (e.key, personaValue(e.value, l)),
    ];
    final size = ButtonSize.of(SizeClass.of(MediaQuery.sizeOf(context).width));
    return SingleChildScrollView(
      key: const Key('persona-detail'),
      padding: EdgeInsets.all(widget.page ? Space.s16 : Space.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            MessageBar(message: apiFailure(l, error), kind: NoticeKind.error),
            const SizedBox(height: Space.s16),
          ],
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.tagBackground,
                  shape: BoxShape.circle,
                ),
                child: x.type == 'bot'
                    ? Icon(
                        AppIcons.large(AppIcons.bot),
                        size: IconSizes.large,
                        color: p.text2,
                      )
                    : Text(
                        initials(x.name),
                        style: TextStyles.title3.copyWith(color: p.text),
                      ),
              ),
              const SizedBox(width: Space.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        x.name,
                        style: TextStyles.title3.copyWith(color: p.text),
                      ),
                    ),
                    Text(
                      [
                        x.type == 'bot' ? l.botType : l.personType,
                        if (x.isSelf) l.you,
                        ...x.aliases,
                      ].join(' · '),
                      style: TextStyles.body1.copyWith(color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: Space.s24),
            LayoutBuilder(
              builder: (context, box) {
                final cell = (box.maxWidth - Space.s16) / 2;
                return Wrap(
                  spacing: Space.s16,
                  runSpacing: Space.s12,
                  children: [
                    for (final (label, value) in facts)
                      SizedBox(
                        width: box.maxWidth < 360 ? box.maxWidth : cell,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyles.caption1.copyWith(
                                color: p.muted,
                              ),
                            ),
                            Text(
                              value,
                              style: TextStyles.body1.copyWith(color: p.text),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          if (mentions != null) ...[
            const SizedBox(height: Space.s24),
            Text(
              l.personaUsedIn,
              style: TextStyles.caption1.copyWith(color: p.muted),
            ),
            Text(
              l.personaMentions(mentions!),
              key: const Key('persona-used-in'),
              style: TextStyles.body1.copyWith(color: p.text),
            ),
          ],
          const SizedBox(height: Space.s24),
          Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              AppButton(
                key: const Key('edit-persona'),
                label: l.personaEdit,
                icon: AppIcons.rename,
                onPressed: busy
                    ? null
                    : () => context.go(
                        '$_base/${Uri.encodeComponent(widget.id)}/edit',
                      ),
              ),
              TextButton.icon(
                key: const Key('delete-persona-detail'),
                style: buttonStyle(p, ButtonAppearance.subtle, size: size)
                    .copyWith(
                      foregroundColor: WidgetStatePropertyAll(
                        p.dangerForeground,
                      ),
                      iconColor: WidgetStatePropertyAll(p.dangerForeground),
                    ),
                onPressed: busy ? null : _delete,
                icon: Icon(AppIcons.delete, size: size.icon),
                label: Text(l.deletePersona),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Up to two initials of a name, for the avatar.
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return parts.take(2).map((w) => w.characters.first.toUpperCase()).join();
}
