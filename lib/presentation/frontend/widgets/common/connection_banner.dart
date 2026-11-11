import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/online.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'states.dart';

/// One browser connection banner covers every route. It makes no test request.
class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({
    super.key,
    required this.child,
    this.changes,
    this.initialOnline,
  });
  final Widget child;
  final Stream<bool>? changes;
  final bool? initialOnline;
  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  late bool online = widget.initialOnline ?? browserOnline;
  StreamSubscription<bool>? subscription;
  @override
  void initState() {
    super.initState();
    subscription = (widget.changes ?? onlineChanges).listen((value) {
      if (mounted) setState(() => online = value);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (!online)
        Material(
          child: OfflineBanner(
            key: const Key('network-offline'),
            message: AppLocalizations.of(context).networkOffline,
          ),
        ),
      Expanded(child: widget.child),
    ],
  );
}
