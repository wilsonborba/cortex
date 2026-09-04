import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/settings.dart';
import '../../../dal/remote/cortex_logs_socket_adapter.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Small, dev-only affordance: an icon button that opens a collapsible
/// sheet streaming cortex_api's live log lines over WebSocket (see
/// `CortexLogsSocketAdapter`).
///
/// Not shown at all unless [AppSettings.enableLiveLogStreaming] is on, so
/// it never appears as a real feature in a normal build, and never on by
/// default even in development: opening the sheet is an explicit tap.
class TelemetryPanelButton extends StatelessWidget {
  const TelemetryPanelButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppSettings.enableLiveLogStreaming) return const SizedBox.shrink();
    return IconButton(
      tooltip: AppLocalizations.of(context).liveLogsTooltip,
      icon: const Icon(Icons.bug_report_outlined),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => const _TelemetryPanelSheet(),
      ),
    );
  }
}

class _TelemetryPanelSheet extends StatefulWidget {
  const _TelemetryPanelSheet();

  @override
  State<_TelemetryPanelSheet> createState() => _TelemetryPanelSheetState();
}

class _TelemetryPanelSheetState extends State<_TelemetryPanelSheet> {
  final _adapter = CortexLogsSocketAdapter();
  final _lines = <String>[];
  StreamSubscription<String>? _subscription;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    try {
      _subscription = _adapter.connect().listen(
        (line) => setState(() => _lines.add(line)),
        onError: (Object error) =>
            setState(() => _connectionError = error.toString()),
      );
    } catch (e) {
      _connectionError = e.toString();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _adapter.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.liveLogsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.liveLogsDescription,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Divider(),
              if (_connectionError != null)
                Text(
                  l10n.liveLogsConnectionError(_connectionError!),
                  style: TextStyle(color: scheme.error),
                )
              else if (_lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(l10n.liveLogsWaiting),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _lines.length,
                    itemBuilder: (context, index) => Text(
                      _lines[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
