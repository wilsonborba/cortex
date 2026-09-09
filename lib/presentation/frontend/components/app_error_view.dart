import 'package:flutter/material.dart';

import '../../../core/utils/csrf.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../widgets/support/on_support.dart';
import 'app_theme.dart';

/// Generic, friendly "something went wrong" card shown in place of whatever
/// broke, matching Cortex's own dark monochrome glass aesthetic rather than
/// certifications' Material look (see `certifications/lib/presentation/
/// components/app_error_view.dart`, read for the visual pattern only).
///
/// Unlike certifications' version, this never sends an anonymous telemetry
/// report on button press and never shows the raw exception to the user:
/// [technicalSummary] is only ever used to pre-fill a support ticket the
/// user reviews and sends themselves.
class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, this.technicalSummary});

  /// Built from a Flutter render/build error (wired as `ErrorWidget.builder`
  /// in `main.dart`).
  factory AppErrorView.fromFlutterError(FlutterErrorDetails details) {
    return AppErrorView(technicalSummary: summarizeFlutterError(details));
  }

  /// A short, non-user-facing technical summary (exception, library, route)
  /// used only to pre-fill the support ticket's body. Null when this view is
  /// used purely as a friendly banner with no underlying error object (not
  /// currently exercised, kept optional for flexibility).
  final String? technicalSummary;

  /// Builds a compact, non-technical-looking-but-actually-technical summary
  /// from [details], for a support ticket body only - never rendered to the
  /// user directly.
  static String summarizeFlutterError(FlutterErrorDetails details) {
    final buffer = StringBuffer()
      ..writeln('Exception: ${details.exceptionAsString()}');
    if (details.library != null) buffer.writeln('Library: ${details.library}');
    final context = details.context?.toDescription();
    if (context != null && context.isNotEmpty) buffer.writeln('Context: $context');
    return buffer.toString().trim();
  }

  /// Same idea as [summarizeFlutterError], for a plain caught error/exception
  /// (e.g. a failed chat send) instead of a [FlutterErrorDetails].
  static String summarizeError(Object error, {String? route}) {
    final buffer = StringBuffer()..writeln('Error: $error');
    if (route != null && route.isNotEmpty) buffer.writeln('Route: $route');
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Same live cookie check `SessionService` uses by default: whether the
    // support CTA even makes sense here (a login flow should never be forced
    // from an error screen, see this feature's spec).
    final loggedIn = (readCsrfToken() ?? '').isNotEmpty;

    return Material(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: AppTheme.glassDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.genericErrorTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.genericErrorMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (loggedIn) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _openSupport(context, l10n),
                      icon: const Icon(Icons.support_agent_outlined, size: 18),
                      label: Text(l10n.contactSupportAction),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSupport(BuildContext context, AppLocalizations l10n) {
    // Defense in depth: this view can render in place of a widget anywhere
    // in the tree, so a healthy `Navigator` ancestor is not guaranteed (the
    // crash itself could be the reason one is missing).
    final navigator = Navigator.maybeOf(context);
    if (navigator == null) return;
    final summary = technicalSummary;
    navigator.push(
      MaterialPageRoute(
        builder: (_) => OnSupportScreen(
          initialComposeSubject: l10n.errorReportTicketSubject,
          initialComposeBody: summary == null
              ? l10n.errorReportTicketBodyIntro
              : '${l10n.errorReportTicketBodyIntro}\n\n$summary',
        ),
      ),
    );
  }
}
