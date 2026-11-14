import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/file_picker.dart';
import '../../../../domain/models/output.dart';
import '../../../../domain/services/chat_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/surfaces.dart';
import '../../widgets/common/progress.dart';

class Composer extends StatefulWidget {
  const Composer({super.key, required this.chat, this.picker = pickFiles});
  final ChatController chat;
  final Future<List<PickedFile>> Function() picker;
  @override
  State<Composer> createState() => ComposerState();
}

class ComposerState extends State<Composer> {
  final text = TextEditingController();
  final _topic = TextEditingController();
  final _focus = FocusNode();
  final _optionsFocus = FocusNode();
  String? _pendingText;
  OutputView? _pendingOutput;
  @override
  void initState() {
    super.initState();
    _topic.text = widget.chat.options.topic ?? '';
    text.addListener(_textChanged);
    _focus.addListener(_textChanged);
    widget.chat.addListener(_chatChanged);
    _focus.onKeyEvent = (node, event) {
      final range = text.value.composing;
      if (range.isValid && !range.isCollapsed) return KeyEventResult.ignored;
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.isShiftPressed) {
        _send();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void didUpdateWidget(Composer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chat != widget.chat) {
      oldWidget.chat.removeListener(_chatChanged);
      widget.chat.addListener(_chatChanged);
      _pendingOutput = null;
      _pendingText = null;
    }
  }

  void _textChanged() {
    if (mounted) setState(() {});
  }

  void _chatChanged() {
    final output = _pendingOutput;
    if (output != null && !output.running) {
      if (output.status == 'failed' &&
          output.answer.isEmpty &&
          text.text.isEmpty &&
          _pendingText != null) {
        text.text = _pendingText!;
      }
      _pendingText = null;
      _pendingOutput = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.chat.removeListener(_chatChanged);
    text.dispose();
    _topic.dispose();
    _focus.dispose();
    _optionsFocus.dispose();
    super.dispose();
  }

  void _send() {
    final chat = widget.chat;
    final range = text.value.composing;
    final raw = text.text;
    final value = raw.trim();
    if ((range.isValid && !range.isCollapsed) ||
        value.isEmpty ||
        chat.overLimit(raw) ||
        chat.running != null ||
        chat.files.any((file) => file.uploading)) {
      return;
    }
    chat.options.topic = _topic.text.trim();
    _pendingText = raw;
    text.clear();
    chat.send(value);
    _pendingOutput = chat.exchanges.lastOrNull?.output;
    _chatChanged();
  }

  Future<void> _attach() async {
    for (final file in await widget.picker()) {
      widget.chat.attach(
        AttachedFile(
          file.name,
          file.bytes.length,
          file.contentType,
          file.bytes,
        ),
      );
    }
  }

  String _size(int bytes) => bytes >= 1 << 20
      ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';
  List<(WebChoice, String)> _webChoices(AppLocalizations l) => [
    (WebChoice.off, l.webOff),
    (WebChoice.fast, l.webFast),
    (WebChoice.medium, l.webMedium),
    (WebChoice.deep, l.webDeep),
  ];
  String _personaLabel(AppLocalizations l) =>
      widget.chat.personas
          .where((p) => '${p['persona_id']}' == widget.chat.options.personaId)
          .firstOrNull?['name']
          ?.toString() ??
      l.personaPicker;
  Widget _topicInput(AppLocalizations l) => SizedBox(
    width: Space.topicInputWidth,
    child: TextField(
      key: const Key('memory-topic'),
      controller: _topic,
      style: TextStyles.compact,
      onChanged: (value) => widget.chat.options.topic = value,
      decoration: InputDecoration(hintText: l.topicHint, isDense: true),
    ),
  );
  String _webLabel(AppLocalizations l) => _webChoices(
    l,
  ).firstWhere((item) => item.$1 == widget.chat.options.web).$2;

  /// Fluent radio menu items for the web modes: the checkmark on the current.
  List<Widget> _webItems(AppLocalizations l) => [
    for (final (mode, label) in _webChoices(l))
      MenuItemButton(
        key: ValueKey('web-${mode.name}'),
        closeOnActivate: false,
        leadingIcon: Icon(
          AppIcons.copied,
          color: mode == widget.chat.options.web ? null : Colors.transparent,
        ),
        onPressed: () => setState(() => widget.chat.options.web = mode),
        child: Text('${l.webLabel}: $label'),
      ),
  ];

  List<Widget> _personaItems(AppLocalizations l) => [
    MenuItemButton(
      closeOnActivate: false,
      leadingIcon: Icon(
        AppIcons.copied,
        color: widget.chat.options.personaId == null
            ? null
            : Colors.transparent,
      ),
      onPressed: () => setState(() => widget.chat.options.personaId = null),
      child: Text(l.noPersona),
    ),
    for (final persona in widget.chat.personas)
      MenuItemButton(
        closeOnActivate: false,
        leadingIcon: Icon(
          AppIcons.copied,
          color: widget.chat.options.personaId == '${persona['persona_id']}'
              ? null
              : Colors.transparent,
        ),
        onPressed: () => setState(
          () => widget.chat.options.personaId = '${persona['persona_id']}',
        ),
        child: Text('${persona['name']}'),
      ),
  ];

  /// Subtle menu button of the toolbar (#64): icon and label `body1`.
  Widget _menuButton({
    required Key key,
    required IconData icon,
    required String label,
    required List<Widget> items,
  }) => MenuAnchor(
    clipBehavior: Clip.none,
    menuChildren: items,
    builder: (context, controller, _) => TextButton.icon(
      key: key,
      style: _toolStyle(Palette.from(context), false),
      onPressed: () =>
          controller.isOpen ? controller.close() : controller.open(),
      icon: Icon(icon, size: IconSizes.action),
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Space.topicInputWidth),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ),
  );

  /// Subtle toggle button (#64): icon and label; on = `selected` fill and the
  /// filled icon.
  Widget _toggle({
    required Key key,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Semantics(
    toggled: value,
    child: TextButton.icon(
      key: key,
      style: _toolStyle(Palette.from(context), value),
      onPressed: () => onChanged(!value),
      icon: Icon(value ? selectedIcon : icon, size: IconSizes.action),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );

  /// Subtle 32 high toolbar button: `text2`, hover `subtleHover`, radius 4.
  ButtonStyle _toolStyle(Palette p, bool selected) => TextButton.styleFrom(
    minimumSize: const Size(Space.s32, Space.s32),
    fixedSize: const Size.fromHeight(Space.s32),
    padding: const EdgeInsets.symmetric(horizontal: Space.s8),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: selected ? p.text : p.text2,
    backgroundColor: selected ? p.selected : Colors.transparent,
    textStyle: TextStyles.body1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.control),
    ),
  ).copyWith(overlayColor: WidgetStatePropertyAll(p.subtleHover));

  Widget _options(AppLocalizations l) {
    final chat = widget.chat, o = widget.chat.options;
    return MenuAnchor(
      clipBehavior: Clip.none,
      childFocusNode: _optionsFocus,
      menuChildren: [
        ..._webItems(l),
        const MenuGroupDivider(),
        MenuItemButton(
          key: const Key('memory-switch'),
          closeOnActivate: false,
          leadingIcon: Icon(
            o.memory ? AppIcons.memorySelected : AppIcons.memory,
          ),
          trailingIcon: o.memory ? const Icon(AppIcons.copied) : null,
          onPressed: () => setState(() => o.memory = !o.memory),
          child: Text(l.memoryToggle),
        ),
        if (o.memory)
          Padding(
            padding: const EdgeInsets.all(Space.s12),
            child: _topicInput(l),
          ),
        MenuItemButton(
          key: const Key('thinking-switch'),
          closeOnActivate: false,
          leadingIcon: Icon(o.thinking ? AppIcons.noteSelected : AppIcons.note),
          trailingIcon: o.thinking ? const Icon(AppIcons.copied) : null,
          onPressed: () => setState(() => o.thinking = !o.thinking),
          child: Text(l.thinkingToggle),
        ),
        if (chat.isNew && !chat.temporary && chat.personas.isNotEmpty)
          SubmenuButton(
            leadingIcon: const Icon(AppIcons.personas),
            menuChildren: _personaItems(l),
            child: Text(l.personaPicker),
          ),
      ],
      builder: (context, controller, child) => TextButton(
        key: const Key('composer-options'),
        focusNode: _optionsFocus,
        style: _toolStyle(Palette.from(context), false),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        child: Text(
          l.composerOptions,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Attachment tag (#64): 24 high, `document_text` 16, the name (at most 24
  /// characters), the size in `caption1` `muted`, a 2 px upload bar at the
  /// bottom while it uploads and a 16 px dismiss button. An error gives a
  /// `dangerBorder` border and the message as a tooltip and a live region.
  Widget _attachment(AppLocalizations l, Palette p, AttachedFile file) {
    final error = file.errorNumber != null
        ? processMessage(l, file.errorNumber)
        : file.errorMessage != null
        ? l.networkOffline
        : null;
    final name = file.name.characters.length <= 24
        ? file.name
        : '${file.name.characters.take(23)}…';
    final tag = Container(
      key: Key('file-${file.name}'),
      height: Space.s24,
      decoration: BoxDecoration(
        color: p.tagBackground,
        border: Border.all(
          color: error == null ? p.stroke : p.dangerBorder,
          width: Strokes.thin,
        ),
        borderRadius: BorderRadius.circular(Radii.control),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.control - Strokes.thin),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Space.s6, right: Space.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    error == null ? AppIcons.file : AppIcons.error,
                    size: IconSizes.small,
                    color: error == null ? p.text2 : p.dangerForeground,
                  ),
                  const SizedBox(width: Space.s4),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.caption1.copyWith(color: p.text),
                    ),
                  ),
                  const SizedBox(width: Space.s4),
                  Text(
                    file.uploading ? l.uploading : _size(file.size),
                    style: TextStyles.caption1.copyWith(color: p.muted),
                  ),
                  IconButton(
                    tooltip: l.removePersonaItem,
                    onPressed: () => widget.chat.removeFile(file),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      fixedSize: const Size.square(Space.s20),
                      minimumSize: const Size.square(Space.s20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(AppIcons.close, size: IconSizes.small),
                  ),
                ],
              ),
            ),
            if (file.uploading)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AppProgressBar(),
              ),
          ],
        ),
      ),
    );
    if (error == null) return tag;
    return Semantics(
      liveRegion: true,
      label: error,
      child: Tooltip(message: error, child: tag),
    );
  }

  /// Send (#64): the one primary button, icon only 32 x 32, `send` filled 20,
  /// radius 4. While an answer runs it is Stop: secondary, `stop` filled.
  Widget _action(Palette p, AppLocalizations l, bool running, String? reason) {
    final style =
        buttonStyle(
          p,
          running ? ButtonAppearance.secondary : ButtonAppearance.primary,
          size: ButtonSize.medium,
        ).copyWith(
          fixedSize: const WidgetStatePropertyAll(Size.square(Space.s32)),
          minimumSize: const WidgetStatePropertyAll(Size.square(Space.s32)),
          maximumSize: const WidgetStatePropertyAll(Size.square(Space.s32)),
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        );
    return Semantics(
      key: Key(running ? 'stop' : 'send'),
      button: true,
      label: running ? l.stop : l.send,
      excludeSemantics: true,
      child: FilledButton(
        style: style,
        onPressed: running
            ? () => runApiAction(context, widget.chat.stop)
            : reason == null
            ? _send
            : null,
        child: Icon(
          running ? AppIcons.stopSelected : AppIcons.sendSelected,
          size: IconSizes.action,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = Palette.from(context);
    final chat = widget.chat, o = widget.chat.options;
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    final compact = size == SizeClass.compact;
    final running = chat.running != null;
    final tokens = chat.estimate(text.text);
    final max = chat.budget.maxTokens;
    final over = tokens > max;
    final near = tokens > max * Controls.budgetWarningFraction;
    final uploading = chat.files.any((file) => file.uploading);
    final reason = running
        ? null
        : over
        ? l.overLimit
        : uploading
        ? l.composerUploadReason
        : text.text.trim().isEmpty
        ? l.composerEmptyReason
        : null;
    final summary = [
      if (o.web != WebChoice.off) '${l.webLabel}: ${_webLabel(l)}',
      if (o.memory) l.memoryToggle,
      if (o.thinking) l.thinkingToggle,
      if (o.personaId != null) _personaLabel(l),
    ].join(' · ');
    final radius = BorderRadius.circular(Radii.dialog);
    return Padding(
      // 16 px from the bottom; compact: 8 px and full width minus 16 (#64).
      padding: EdgeInsets.fromLTRB(
        compact ? Space.s8 : Space.s24,
        Space.s8,
        compact ? Space.s8 : Space.s24,
        compact ? Space.s8 : Space.s16,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.chatColumnWidth),
          child: LayoutBuilder(
            builder: (context, box) {
              Widget flex(Widget child) => box.hasBoundedHeight
                  ? Flexible(fit: FlexFit.loose, child: child)
                  : child;
              final focusDuration = FoundationTokens.of(
                context,
              ).duration(context, MotionDurations.normal);
              return Container(
                key: const Key('composer'),
                decoration: BoxDecoration(
                  color: p.raised,
                  border: Border.all(color: p.stroke, width: Controls.border),
                  borderRadius: radius,
                  boxShadow: Shadows.shadow4(Theme.of(context).brightness),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    Radii.dialog - Controls.border,
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Space.s12,
                          vertical: Space.s8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (chat.files.isNotEmpty)
                              flex(
                                SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: Space.s8,
                                    ),
                                    child: Wrap(
                                      spacing: Space.s8,
                                      runSpacing: Space.s8,
                                      children: [
                                        for (final file in chat.files)
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  box.maxWidth - Space.s24,
                                            ),
                                            child: _attachment(l, p, file),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            flex(
                              TextField(
                                key: const Key('composer-text'),
                                controller: text,
                                focusNode: _focus,
                                minLines: 1,
                                maxLines: Controls.composerMaxLines,
                                style: TextStyles.body2.copyWith(color: p.text),
                                decoration: InputDecoration(
                                  hintText: l.composerHint,
                                  hintStyle: TextStyles.body2.copyWith(
                                    color: p.muted,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: Space.s6,
                                  ),
                                ),
                              ),
                            ),
                            if (compact && summary.isNotEmpty)
                              Tooltip(
                                message: summary,
                                child: Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyles.caption1.copyWith(
                                    color: p.muted,
                                  ),
                                ),
                              ),
                            const SizedBox(height: Space.s4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  key: const Key('attach'),
                                  tooltip: l.attach,
                                  style: IconButton.styleFrom(
                                    fixedSize: const Size.square(Space.s32),
                                    minimumSize: const Size.square(Space.s32),
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  icon: const Icon(
                                    AppIcons.attach,
                                    size: IconSizes.action,
                                  ),
                                  onPressed: running ? null : _attach,
                                ),
                                const SizedBox(width: Space.s4),
                                Expanded(
                                  child: compact
                                      ? Align(
                                          alignment: Alignment.centerLeft,
                                          child: _options(l),
                                        )
                                      : Wrap(
                                          spacing: Space.s4,
                                          runSpacing: Space.s4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _menuButton(
                                              key: const Key('web-choice'),
                                              icon: AppIcons.web,
                                              label: _webLabel(l),
                                              items: _webItems(l),
                                            ),
                                            _toggle(
                                              key: const Key('memory-switch'),
                                              icon: AppIcons.memory,
                                              selectedIcon:
                                                  AppIcons.memorySelected,
                                              label: l.memoryToggle,
                                              value: o.memory,
                                              onChanged: (v) =>
                                                  setState(() => o.memory = v),
                                            ),
                                            if (o.memory) _topicInput(l),
                                            _toggle(
                                              key: const Key('thinking-switch'),
                                              icon: AppIcons.note,
                                              selectedIcon:
                                                  AppIcons.noteSelected,
                                              label: l.thinkingToggle,
                                              value: o.thinking,
                                              onChanged: (v) => setState(
                                                () => o.thinking = v,
                                              ),
                                            ),
                                            if (chat.isNew &&
                                                !chat.temporary &&
                                                chat.personas.isNotEmpty)
                                              _menuButton(
                                                key: const Key(
                                                  'persona-picker',
                                                ),
                                                icon: AppIcons.personas,
                                                label: o.personaId == null
                                                    ? l.noPersona
                                                    : _personaLabel(l),
                                                items: _personaItems(l),
                                              ),
                                          ],
                                        ),
                                ),
                                if (near) ...[
                                  const SizedBox(width: Space.s8),
                                  SizedBox(
                                    height: Space.s32,
                                    child: Center(
                                      child: Text(
                                        l.tokenCounter(tokens, max),
                                        key: const Key('token-counter'),
                                        style: TextStyles.caption1.copyWith(
                                          color: over
                                              ? p.dangerForeground
                                              : tokens > max * 0.9
                                              ? p.warningForeground
                                              : p.muted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(width: Space.s8),
                                AppTooltip(
                                  message:
                                      reason ?? (running ? l.stop : l.send),
                                  child: SizedBox.square(
                                    key: const Key('composer-action-slot'),
                                    dimension: Space.s32,
                                    child: _action(p, l, running, reason),
                                  ),
                                ),
                              ],
                            ),
                            // Only reasons the person can act on are written.
                            if (over || uploading)
                              Padding(
                                padding: const EdgeInsets.only(top: Space.s4),
                                child: Text(
                                  reason!,
                                  key: const Key('composer-disabled-reason'),
                                  style: TextStyles.caption1.copyWith(
                                    color: over ? p.dangerForeground : p.muted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Focus: a 2 px brand bar at the bottom inside the
                      // radius, growing from the center (#64, #61 pattern).
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Center(
                          child: AnimatedFractionallySizedBox(
                            key: const Key('composer-focus-bar'),
                            duration: focusDuration,
                            curve: MotionCurves.decelerateMid,
                            widthFactor: _focus.hasFocus ? 1 : 0,
                            child: Container(
                              height: Strokes.thick,
                              color: _focus.hasFocus
                                  ? p.brandStroke1
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
