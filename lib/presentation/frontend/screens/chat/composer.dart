import '../../handlers/api_action.dart';
import '../../handlers/process_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/utils/file_picker.dart';
import '../../../../domain/services/chat_controller.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/buttons.dart';

/// Composer fixed at the bottom (30.2, 30.4).
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

  @override
  void initState() {
    super.initState();
    text.addListener(() => setState(() {}));
    _focus.onKeyEvent = (node, event) {
      // Enter sends, Shift+Enter is a new line.
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
  void dispose() {
    text.dispose();
    _topic.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final chat = widget.chat;
    final value = text.text.trim();
    if ((value.isEmpty && chat.files.isEmpty) ||
        chat.overLimit(value) ||
        chat.running != null) {
      return;
    }
    chat.options.topic = _topic.text.trim();
    chat.send(value);
    text.clear();
  }

  Future<void> _attach() async {
    for (final f in await widget.picker()) {
      widget.chat.attach(
        AttachedFile(f.name, f.bytes.length, f.contentType, f.bytes),
      );
    }
  }

  String _size(int bytes) => bytes >= 1 << 20
      ? '${(bytes / (1 << 20)).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).ceil()} KB';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.of(Theme.of(context).brightness);
    final chat = widget.chat;
    final o = chat.options;
    final tokens = chat.estimate(text.text);
    final over = tokens > chat.budget.maxTokens;
    final near = tokens > chat.budget.maxTokens * 0.8;
    final running = chat.running != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.s16,
        Space.s8,
        Space.s16,
        Space.s16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Container(
            key: const Key('composer'),
            padding: const EdgeInsets.all(Space.s12),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border.all(color: p.border),
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: ChipTheme(
              data: Theme.of(context).chipTheme.copyWith(
                backgroundColor: Colors.transparent,
                selectedColor: p.text.withValues(alpha: 0.06),
                side: BorderSide.none,
                labelStyle: TextStyles.compact.copyWith(color: p.muted),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (chat.files.isNotEmpty)
                    Wrap(
                      spacing: Space.s8,
                      runSpacing: Space.s8,
                      children: [
                        for (final f in chat.files)
                          InputChip(
                            key: Key('file-${f.name}'),
                            avatar: f.uploading
                                ? SizedBox.square(
                                    dimension: 14,
                                    child:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? const Icon(
                                            Icons.hourglass_empty,
                                            size: 14,
                                          )
                                        : const CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                  )
                                : Icon(
                                    f.errorNumber != null
                                        ? Icons.error_outline
                                        : Icons.attach_file,
                                    size: 16,
                                    color: f.errorNumber != null
                                        ? p.danger
                                        : null,
                                  ),
                            label: Text(
                              [
                                f.name,
                                _size(f.size),
                                if (f.uploading) l.uploading,
                                if (f.errorNumber != null)
                                  processMessage(l, f.errorNumber)
                                else if (f.errorMessage != null)
                                  l.networkOffline,
                              ].join(' · '),
                              style: TextStyles.label,
                            ),
                            deleteButtonTooltipMessage: l.removePersonaItem,
                            onDeleted: () => chat.removeFile(f),
                          ),
                      ],
                    ),
                  TextField(
                    key: const Key('composer-text'),
                    controller: text,
                    focusNode: _focus,
                    minLines: 1,
                    maxLines: 8,
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
                  if (near)
                    Text(
                      over
                          ? '${l.overLimit} ${l.tokenCounter(tokens, chat.budget.maxTokens)}'
                          : l.tokenCounter(tokens, chat.budget.maxTokens),
                      key: const Key('token-counter'),
                      style: TextStyles.label.copyWith(
                        color: over ? p.danger : p.muted,
                      ),
                    ),
                  Wrap(
                    spacing: Space.s8,
                    runSpacing: Space.s8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      IconButton(
                        key: const Key('attach'),
                        tooltip: l.attach,
                        icon: const Icon(Icons.attach_file),
                        onPressed: running ? null : _attach,
                      ),
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width < 600
                            ? 136
                            : 176,
                        child: DropdownButton<WebChoice>(
                          isExpanded: true,
                          isDense: true,
                          itemHeight: null,
                          key: const Key('web-choice'),
                          value: o.web,
                          underline: const SizedBox(),
                          items: [
                            for (final (v, label) in [
                              (WebChoice.off, l.webOff),
                              (WebChoice.fast, l.webFast),
                              (WebChoice.medium, l.webMedium),
                              (WebChoice.deep, l.webDeep),
                            ])
                              DropdownMenuItem(
                                value: v,
                                child: Text(
                                  '${l.webLabel}: $label',
                                  style: TextStyles.compact,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => o.web = v!),
                        ),
                      ),
                      FilterChip(
                        key: const Key('memory-switch'),
                        label: Text(
                          l.memoryToggle,
                          style: TextStyles.compact.copyWith(
                            color: o.memory ? p.accent : p.muted,
                          ),
                        ),
                        selected: o.memory,
                        showCheckmark: false,
                        onSelected: (v) => setState(() => o.memory = v),
                      ),
                      if (o.memory)
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _topic,
                            style: TextStyles.compact,
                            decoration: InputDecoration(
                              hintText: l.topicHint,
                              isDense: true,
                            ),
                          ),
                        ),
                      FilterChip(
                        key: const Key('thinking-switch'),
                        label: Text(
                          l.thinkingToggle,
                          style: TextStyles.compact.copyWith(
                            color: o.thinking ? p.accent : p.muted,
                          ),
                        ),
                        selected: o.thinking,
                        showCheckmark: false,
                        onSelected: (v) => setState(() => o.thinking = v),
                      ),
                      if (chat.isNew &&
                          !chat.temporary &&
                          chat.personas.isNotEmpty)
                        SizedBox(
                          width: MediaQuery.sizeOf(context).width < 600
                              ? MediaQuery.sizeOf(context).width - Space.s24
                              : 240,
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            itemHeight: null,
                            key: const Key('persona-picker'),
                            value: o.personaId,
                            hint: Text(
                              l.personaPicker,
                              style: TextStyles.compact,
                            ),
                            underline: const SizedBox(),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  l.noPersona,
                                  style: TextStyles.compact,
                                ),
                              ),
                              for (final persona in chat.personas)
                                DropdownMenuItem<String?>(
                                  value: '${persona['persona_id']}',
                                  child: Text(
                                    '${persona['name']}',
                                    style: TextStyles.compact,
                                  ),
                                ),
                            ],
                            onChanged: (v) => setState(() => o.personaId = v),
                          ),
                        ),
                      running
                          ? AppButton(
                              key: const Key('stop'),
                              label: l.stop,
                              icon: Icons.stop,
                              onPressed: () => runApiAction(context, chat.stop),
                            )
                          : AppButton.primary(
                              key: const Key('send'),
                              label: l.send,
                              icon: Icons.arrow_upward,
                              onPressed:
                                  over ||
                                      chat.files.any((f) => f.uploading) ||
                                      (text.text.trim().isEmpty &&
                                          chat.files.isEmpty)
                                  ? null
                                  : _send,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
