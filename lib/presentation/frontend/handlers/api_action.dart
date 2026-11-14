import 'package:flutter/material.dart';
import '../../../domain/models/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'process_messages.dart';
import '../widgets/common/toast.dart';
import '../widgets/common/states.dart' show NoticeKind;

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
      showToast(
        context,
        message: apiFailure(
          l,
          error is ApiError ? error : const ApiError(0, null, ''),
        ),
        kind: NoticeKind.error,
        actionLabel: l.retry,
        onAction: () => runApiAction(context, action),
      );
    }
    return false;
  }
}
