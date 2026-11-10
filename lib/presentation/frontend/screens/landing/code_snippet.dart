import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import '../../theme/tokens.dart';

Future<void>? _ready;

/// A real snippet of the Rust code (24.N.1.a): at most 25 lines, the file path
/// below, Ubuntu Sans Mono, monochrome highlight.
class CodeSnippet extends StatelessWidget {
  const CodeSnippet({
    super.key,
    required this.asset,
    required this.path,
    required this.caption,
  });
  final String asset;
  final String path;
  final String caption;

  Future<TextSpan> _load(Palette p) async {
    _ready ??= Highlighter.initialize(['rust']);
    await _ready;
    final code = await rootBundle.loadString(asset);
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
        fontSize: 13,
        height: 1.5,
        color: p.text,
      ),
    );
    return Highlighter(language: 'rust', theme: theme).highlight(code);
  }

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption, style: TextStyles.label),
        const SizedBox(height: Space.s8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Space.s16),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border.all(color: p.border),
            borderRadius: BorderRadius.circular(Radii.card),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: FutureBuilder<TextSpan>(
              future: _load(p),
              builder: (_, s) =>
                  s.hasData ? Text.rich(s.data!) : const SizedBox(height: 120),
            ),
          ),
        ),
        const SizedBox(height: Space.s4),
        Text(
          path,
          style: TextStyles.label.copyWith(
            color: p.muted,
            fontFamily: TextStyles.mono,
          ),
        ),
      ],
    );
  }
}
