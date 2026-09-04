import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Sticky-vs-manual auto-scroll bookkeeping for a chat message list
/// (issue #7): wraps a plain [ScrollController] and tracks whether the
/// list is currently "sticky" (close enough to the bottom that new
/// streamed tokens should keep auto-scrolling it) or the user has
/// manually scrolled up (auto-scroll pauses until they scroll back down or
/// tap the [ScrollToBottomButton]).
///
/// Distinguishing a user-initiated scroll from this class's own
/// programmatic `animateTo`/`jumpTo` calls matters because otherwise every
/// auto-scroll-to-bottom would itself be misread as "the user scrolled up
/// and away", the [_isProgrammatic] flag set immediately around
/// [scrollToBottom] is what tells them apart.
class StickyScrollController {
  StickyScrollController({this.stickyThreshold = 96});

  /// How close (in logical pixels) to `maxScrollExtent` counts as "sticky".
  final double stickyThreshold;

  final ScrollController controller = ScrollController();

  bool _isProgrammatic = false;
  bool _isSticky = true;

  /// Whether the list should keep auto-scrolling as new content arrives.
  bool get isSticky => _isSticky;

  void dispose() => controller.dispose();

  /// Feed every [ScrollNotification] from a `NotificationListener` here.
  /// Returns true when [isSticky] changed as a result (callers should
  /// `setState` to update the floating button's visibility).
  bool handleNotification(ScrollNotification notification) {
    // Ignore notifications caused by this controller's own animateTo/jumpTo
    // calls, only a real user drag should be able to break stickiness.
    if (_isProgrammatic) return false;
    if (notification is! ScrollUpdateNotification &&
        notification is! ScrollEndNotification &&
        notification is! OverscrollNotification) {
      return false;
    }
    if (!controller.hasClients) return false;

    final metrics = notification.metrics;
    final distanceFromBottom = metrics.maxScrollExtent - metrics.pixels;
    final nowSticky = distanceFromBottom <= stickyThreshold;
    if (nowSticky == _isSticky) return false;
    _isSticky = nowSticky;
    return true;
  }

  /// Scrolls to the bottom and re-enables sticky mode. Called both by the
  /// floating button and by the app's own auto-scroll-while-streaming
  /// logic (with `animate: false` for the latter, so token-by-token
  /// updates don't queue up a pile of competing animations).
  Future<void> scrollToBottom({bool animate = true}) async {
    if (!controller.hasClients) return;
    _isProgrammatic = true;
    _isSticky = true;
    final target = controller.position.maxScrollExtent;
    try {
      if (animate) {
        await controller.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        controller.jumpTo(target);
      }
    } finally {
      _isProgrammatic = false;
    }
  }

  /// Auto-scroll hook to call after the message list rebuilds (e.g. a new
  /// streamed token arrived). No-ops while the user has scrolled away
  /// (`!isSticky`), that is the whole point of "smart" auto-scroll.
  void maybeAutoScroll() {
    if (!_isSticky || !controller.hasClients) return;
    scrollToBottom(animate: false);
  }
}

/// Floating "scroll to bottom" affordance shown once the user has scrolled
/// away from the end of the message list. Tapping it jumps back to the
/// bottom and re-enables sticky auto-scroll.
class ScrollToBottomButton extends StatelessWidget {
  const ScrollToBottomButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.scrollToBottomTooltip,
      child: Material(
        color: scheme.onSurface.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        elevation: 3,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: scheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}
