import 'package:flutter/material.dart';
import '../../../domain/models/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'process_messages.dart';

/// Keep an action failure visible and let the user repeat the same action.
Future<bool> runApiAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiFailure(
              l,
              error is ApiError ? error : const ApiError(0, null, ''),
            ),
          ),
          action: SnackBarAction(
            label: l.retry,
            onPressed: () => runApiAction(context, action),
          ),
        ),
      );
    }
    return false;
  }
}
