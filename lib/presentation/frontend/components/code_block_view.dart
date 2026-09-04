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

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: scheme.onSurface.withValues(alpha: 0.06),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _copy,
                  icon: Icon(
                    _copied ? Icons.check : Icons.copy_all_outlined,
                    size: 14,
                  ),
                  label: Text(
                    _copied
                        ? l10n.codeBlockCopiedLabel
                        : l10n.codeBlockCopyLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 28),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _copied
                        ? Colors.green
                        : scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                widget.code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
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
