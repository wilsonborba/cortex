import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../l10n/generated/app_localizations.dart';

/// Renders a single fenced code block (```lang ... ```) from an assistant
/// message as a monospace panel with a small toolbar: the detected
/// language on the left, and a "Copy" button on the right that copies the
/// code to the clipboard with instant visual feedback (issue #7).
class CodeBlockView extends StatefulWidget {
  const CodeBlockView({super.key, required this.code, this.language});

  final String code;
  final String? language;

  @override
  State<CodeBlockView> createState() => _CodeBlockViewState();
}

class _CodeBlockViewState extends State<CodeBlockView> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasLanguage = widget.language != null && widget.language!.isNotEmpty;
    final label = hasLanguage ? widget.language! : l10n.codeBlockPlainLabel;

    final lineCount = widget.code.split('\n').length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF101014) : const Color(0xFFF3F3F6);
    final headerBg = isDark ? const Color(0xFF16161C) : const Color(0xFFE9E9EE);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: isDark ? 0.28 : 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(
                bottom: BorderSide(
                  color: scheme.outline.withValues(alpha: isDark ? 0.2 : 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '// $lineCount lines',
                  style: TextStyle(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check : Icons.copy_all_rounded,
                          size: 13,
                          color: _copied ? scheme.primary : scheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? l10n.codeBlockCopiedLabel : l10n.codeBlockCopyLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _copied ? scheme.primary : scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bridges `flutter_markdown`'s parsed element tree to [CodeBlockView] for
/// fenced code blocks. The `markdown` package renders those as
/// `<pre><code class="language-xxx">...</code></pre>`; this builder is
/// registered as `MarkdownBody(builders: {'pre': CodeBlockElementBuilder()})`
/// so flutter_markdown hands it the `pre` element instead of rendering its
/// own plain, unstyled code block.
class CodeBlockElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    md.Element? codeElement;
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is md.Element && child.tag == 'code') {
        codeElement = child;
        break;
      }
    }

    final classes = codeElement?.attributes['class'];
    String? language;
    if (classes != null && classes.startsWith('language-')) {
      language = classes.substring('language-'.length);
    }

    var code = element.textContent;
    // Fenced code blocks always carry a single trailing newline from the
    // parser, strip it so the rendered block doesn't show a blank last line.
    if (code.endsWith('\n')) {
      code = code.substring(0, code.length - 1);
    }

    return CodeBlockView(code: code, language: language);
  }
}
