import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/file_picker.dart';
import '../../../../domain/models/output.dart';
import '../../../../domain/services/chat_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import '../../theme/app_icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/surfaces.dart';

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
  Widget _options(AppLocalizations l) {
    final chat = widget.chat, o = widget.chat.options;
    return MenuAnchor(
      childFocusNode: _optionsFocus,
      menuChildren: [
        for (final (mode, label) in _webChoices(l))
          MenuItemButton(
            key: ValueKey('web-${mode.name}'),
            closeOnActivate: false,
            leadingIcon: Icon(mode == o.web ? AppIcons.copied : AppIcons.web),
            onPressed: () => setState(() => o.web = mode),
            child: Text('${l.webLabel}: $label'),
          ),
        const Divider(),
        MenuItemButton(
          key: const Key('memory-switch'),
          closeOnActivate: false,
          leadingIcon: const Icon(AppIcons.memory),
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
          leadingIcon: const Icon(AppIcons.note),
          trailingIcon: o.thinking ? const Icon(AppIcons.copied) : null,
          onPressed: () => setState(() => o.thinking = !o.thinking),
          child: Text(l.thinkingToggle),
        ),
        if (chat.isNew && !chat.temporary && chat.personas.isNotEmpty)
          SubmenuButton(
            leadingIcon: const Icon(AppIcons.personas),
            menuChildren: [
              MenuItemButton(
                closeOnActivate: false,
                onPressed: () => setState(() => o.personaId = null),
                child: Text(l.noPersona),
              ),
              for (final persona in chat.personas)
                MenuItemButton(
                  closeOnActivate: false,
                  onPressed: () =>
                      setState(() => o.personaId = '${persona['persona_id']}'),
                  child: Text('${persona['name']}'),
                ),
            ],
            child: Text(l.personaPicker),
          ),
      ],
      builder: (context, controller, child) => TextButton(
        key: const Key('composer-options'),
        focusNode: _optionsFocus,
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

  double _actionWidth(BuildContext context, AppLocalizations l) {
    double width(String label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: TextStyles.label),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final result = painter.width;
      painter.dispose();
      return result;
    }

    final send = width(l.send), stop = width(l.stop);
    return (send > stop ? send : stop) +
        IconSizes.action +
        Space.s8 +
        Space.s32;
  }

  double _menuWidth(BuildContext context, String label, double maximum) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: TextStyles.compact),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + IconSizes.action + Space.s8 + Space.s32;
    painter.dispose();
    return width.clamp(Space.menuMinWidth, maximum).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = Palette.from(context);
    final chat = widget.chat, o = widget.chat.options;
    final size = SizeClass.of(MediaQuery.sizeOf(context).width);
    final compact = size == SizeClass.compact;
    final running = chat.running != null;
    final tokens = chat.estimate(text.text);
    final over = tokens > chat.budget.maxTokens;
    final near =
        tokens > chat.budget.maxTokens * Controls.budgetWarningFraction;
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
      if (o.web != WebChoice.off)
        '${l.webLabel}: ${_webChoices(l).firstWhere((item) => item.$1 == o.web).$2}',
      if (o.memory) l.memoryToggle,
      if (o.thinking) l.thinkingToggle,
      if (o.personaId != null) _personaLabel(l),
    ].join(' · ');
    final gutter = compact ? Space.s16 : Space.s24;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, Space.s8, gutter, Space.s16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Space.chatColumnWidth),
          child: LayoutBuilder(
            builder: (context, box) {
              Widget flex(Widget child) => box.hasBoundedHeight
                  ? Flexible(fit: FlexFit.loose, child: child)
                  : child;
              return Container(
                key: const Key('composer'),
                padding: const EdgeInsets.all(Space.s12),
                decoration: BoxDecoration(
                  color: p.raised,
                  border: Border.all(color: p.border, width: Controls.border),
                  borderRadius: BorderRadius.circular(
                    FoundationTokens.of(context).composerRadius,
                  ),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    FoundationTokens.of(context).composerRadius,
                  ),
                  border: Border.all(
                    color: _focus.hasFocus ? p.text : Colors.transparent,
                    width: Controls.focusRing,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (chat.files.isNotEmpty)
                      flex(
                        SingleChildScrollView(
                          child: Wrap(
                            spacing: Space.s8,
                            runSpacing: Space.s8,
                            children: [
                              for (final file in chat.files)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: box.maxWidth - Space.s24,
                                  ),
                                  child: InputChip(
                                    key: Key('file-${file.name}'),
                                    avatar: file.uploading
                                        ? SizedBox.square(
                                            dimension: IconSizes.chip,
                                            child:
                                                MediaQuery.disableAnimationsOf(
                                                  context,
                                                )
                                                ? const Icon(
                                                    AppIcons.loading,
                                                    size: IconSizes.chip,
                                                  )
                                                : CircularProgressIndicator(
                                                    strokeWidth:
                                                        Controls.border,
                                                    color: p.muted,
                                                  ),
                                          )
                                        : Icon(
                                            file.errorNumber == null
                                                ? AppIcons.file
                                                : AppIcons.error,
                                            size: IconSizes.chip,
                                            color: file.errorNumber == null
                                                ? p.muted
                                                : p.dangerForeground,
                                          ),
                                    label: Text(
                                      [
                                        file.name,
                                        _size(file.size),
                                        if (file.uploading) l.uploading,
                                        if (file.errorNumber != null)
                                          processMessage(l, file.errorNumber)
                                        else if (file.errorMessage != null)
                                          l.networkOffline,
                                      ].join(' · '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyles.label,
                                    ),
                                    deleteButtonTooltipMessage:
                                        l.removePersonaItem,
                                    onDeleted: () => chat.removeFile(file),
                                  ),
                                ),
                            ],
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
                        style: TextStyles.body,
                        decoration: InputDecoration(
                          hintText: l.composerHint,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          filled: false,
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
                          style: TextStyles.label.copyWith(color: p.muted),
                        ),
                      ),
                    if (near)
                      Text(
                        l.tokenCounter(tokens, chat.budget.maxTokens),
                        key: const Key('token-counter'),
                        style: TextStyles.label.copyWith(
                          color: over ? p.dangerForeground : p.muted,
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          key: const Key('attach'),
                          tooltip: l.attach,
                          icon: const Icon(AppIcons.attach),
                          onPressed: running ? null : _attach,
                        ),
                        const SizedBox(width: Space.s8),
                        Expanded(
                          child: compact
                              ? _options(l)
                              : Wrap(
                                  spacing: Space.s8,
                                  runSpacing: Space.s8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: _menuWidth(
                                        context,
                                        '${l.webLabel}: ${_webChoices(l).firstWhere((item) => item.$1 == o.web).$2}',
                                        Space.menuMaxWidth,
                                      ),
                                      child: AppSelect<WebChoice>(
                                        key: const Key('web-choice'),
                                        isExpanded: true,
                                        value: o.web,
                                        items: [
                                          for (final (mode, label)
                                              in _webChoices(l))
                                            DropdownMenuItem(
                                              value: mode,
                                              child: Text(
                                                '${l.webLabel}: $label',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                        onChanged: (value) =>
                                            setState(() => o.web = value!),
                                      ),
                                    ),
                                    AppChip(
                                      key: const Key('memory-switch'),
                                      label: l.memoryToggle,
                                      selected: o.memory,
                                      onSelected: (value) =>
                                          setState(() => o.memory = value),
                                    ),
                                    if (o.memory) _topicInput(l),
                                    AppChip(
                                      key: const Key('thinking-switch'),
                                      label: l.thinkingToggle,
                                      selected: o.thinking,
                                      onSelected: (value) =>
                                          setState(() => o.thinking = value),
                                    ),
                                    if (chat.isNew &&
                                        !chat.temporary &&
                                        chat.personas.isNotEmpty)
                                      SizedBox(
                                        width: _menuWidth(
                                          context,
                                          o.personaId == null
                                              ? l.noPersona
                                              : _personaLabel(l),
                                          Space.menuMaxWidth,
                                        ),
                                        child: AppSelect<String?>(
                                          key: const Key('persona-picker'),
                                          isExpanded: true,
                                          value: o.personaId,
                                          items: [
                                            DropdownMenuItem<String?>(
                                              value: null,
                                              child: Text(
                                                l.noPersona,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            for (final persona in chat.personas)
                                              DropdownMenuItem<String?>(
                                                value:
                                                    '${persona['persona_id']}',
                                                child: Text(
                                                  '${persona['name']}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                          onChanged: (value) => setState(
                                            () => o.personaId = value,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: Space.s8),
                        Tooltip(
                          message: reason ?? (running ? l.stop : l.send),
                          child: SizedBox(
                            key: const Key('composer-action-slot'),
                            width: _actionWidth(context, l),
                            height: Controls.height(size),
                            child: running
                                ? AppButton(
                                    key: const Key('stop'),
                                    label: l.stop,
                                    icon: AppIcons.stop,
                                    onPressed: () =>
                                        runApiAction(context, chat.stop),
                                  )
                                : AppButton.primary(
                                    key: const Key('send'),
                                    label: l.send,
                                    icon: AppIcons.send,
                                    onPressed: reason == null ? _send : null,
                                  ),
                          ),
                        ),
                      ],
                    ),
                    if (reason != null)
                      Text(
                        reason,
                        key: const Key('composer-disabled-reason'),
                        style: TextStyles.label.copyWith(color: p.muted),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
