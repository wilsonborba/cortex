import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import '../../theme/tokens.dart';

Future<void>? _ready;
Future<void> prepareCodeSyntax() => _ready ??= Highlighter.initialize(['rust']);

/// A real snippet of the Rust code (24.N.1.a): at most 25 lines, the file path
/// below, Ubuntu Sans Mono, monochrome highlight.
class CodeSnippet extends StatefulWidget {
  const CodeSnippet({
    super.key,
    required this.asset,
    required this.path,
    required this.caption,
  });
  final String asset;
  final String path;
  final String caption;

  @override
  State<CodeSnippet> createState() => _CodeSnippetState();
}

class _CodeSnippetState extends State<CodeSnippet> {
  Palette? _palette;
  Future<TextSpan>? _source;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final palette = Palette.from(context);
    if (palette != _palette) {
      _palette = palette;
      _source = _load(palette);
    }
  }

  @override
  void didUpdateWidget(CodeSnippet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _source = _load(_palette!);
  }

  TextSpan _neutral(TextSpan span, Palette p) => TextSpan(
    text: span.text,
    style: span.style?.copyWith(
      color: span.style?.color == p.muted ? p.muted : p.text,
    ),
    children: span.children
        ?.map((child) => child is TextSpan ? _neutral(child, p) : child)
        .toList(),
  );
  Future<TextSpan> _load(Palette p) async {
    await prepareCodeSyntax();
    final code = await rootBundle.loadString(widget.asset);
    final theme = HighlighterTheme.fromConfiguration(
      jsonEncode({
        'settings': [
          {
            'scope': 'comment',
            'settings': {'foreground': _hex(p.muted), 'fontStyle': 'italic'},
          },
          {
            'scope': 'string',
            'settings': {'foreground': _hex(p.muted)},
          },
          {
            'scope': ['keyword', 'storage', 'storage.type'],
            'settings': {'foreground': _hex(p.text), 'fontStyle': 'bold'},
          },
        ],
      }),
      TextStyle(
        fontFamily: TextStyles.mono,
        fontSize: TextStyles.code.fontSize,
        height: TextStyles.code.height,
        color: p.text,
      ),
    );
    return _neutral(
      Highlighter(language: 'rust', theme: theme).highlight(code),
      p,
    );
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = Palette.from(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.caption, style: TextStyles.caption1),
        const SizedBox(height: Space.s8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.s16),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.stroke),
            borderRadius: BorderRadius.circular(
              FoundationTokens.of(context).groupRadius,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: FutureBuilder<TextSpan>(
              future: _source,
              builder: (_, s) =>
                  s.hasData ? Text.rich(s.data!) : const SizedBox(height: 120),
            ),
          ),
        ),
        const SizedBox(height: Space.s4),
        Text(
          widget.path,
          style: TextStyles.caption1.copyWith(
            color: p.muted,
            fontFamily: TextStyles.mono,
          ),
        ),
      ],
    );
  }
}
