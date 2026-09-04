import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Expandable "Sources (N)" card rendered under an assistant message that
/// was answered with web-search grounding on (issue #6).
///
/// cortex_api has no dedicated citation/source field on `ExecuteResponse`
/// or `ChatCompletionResponse` today (see `ChatMessage.sources`'s doc
/// comment): the URLs shown here were extracted from the raw reply text,
/// this card renders whatever came back, it does not itself talk to any
/// backend.
class SourcesCard extends StatelessWidget {
  const SourcesCard({super.key, required this.sources});

  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          dense: true,
          leading: Icon(Icons.travel_explore, size: 18, color: scheme.primary),
          title: Text(
            l10n.sourcesCount(sources.length),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          children: [
            for (final url in sources)
              InkWell(
                onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.primary,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
