import '../theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/return_path.dart';
import '../../../domain/services/auth_service.dart';
import '../../../domain/services/session_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import '../widgets/common/buttons.dart';
import '../widgets/common/states.dart';

/// Unknown path or id (28.4).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: EmptyState(
        title: l.notFoundTitle,
        message: l.notFoundMessage,
        icon: AppIcons.notFound,
        action: AppButton.primary(
          label: l.goToChats,
          onPressed: () => context.go('/v1/chats'),
        ),
      ),
    );
  }
}

/// Title and content area of one signed-in screen.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: Space.contentMaxWidth),
      child: Padding(
        padding: const EdgeInsets.all(Space.s24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: TextStyles.title3),
            const SizedBox(height: Space.s24),
            Expanded(child: child),
          ],
        ),
      ),
    ),
  );
}

/// A signed-out visit to a protected path: keep the path, open the SSO (28.2).
class LoginRedirectPage extends StatefulWidget {
  const LoginRedirectPage({super.key, required this.auth, required this.from});
  final AuthService auth;
  final String from;
  @override
  State<LoginRedirectPage> createState() => _LoginRedirectPageState();
}

class _LoginRedirectPageState extends State<LoginRedirectPage> {
  @override
  void initState() {
    super.initState();
    widget.auth.signIn(returnPath: widget.from);
  }

  @override
  Widget build(BuildContext context) => const SigningInPage();
}

/// Sign in wait (#62): a 32 px spinner with the label "Signing you in" plus a
/// non breaking space and an ellipsis, centered. The label is a live region.
class SigningInPage extends StatelessWidget {
  const SigningInPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = Palette.from(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSpinner(page: true, label: l.signingIn),
            const SizedBox(height: Space.s8),
            Semantics(
              liveRegion: true,
              child: Text(
                l.signingIn,
                style: TextStyles.body1.copyWith(color: p.text2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The SSO returns here with auth_exchange_token. After the exchange the token
/// leaves the URL, and the user goes back to the saved path (28.2, 28.3).
class SyncPage extends StatefulWidget {
  const SyncPage({
    super.key,
    required this.auth,
    required this.session,
    required this.uri,
  });
  final AuthService auth;
  final SessionController session;
  final Uri uri;
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  @override
  void initState() {
    super.initState();
    _exchange();
  }

  Future<void> _exchange() async {
    await widget.auth.consumeReturn(widget.uri);
    await widget.session.refresh();
    if (!mounted) return;
    final path = takeReturnPath();
    // context.go replaces the URL, so the token is not kept in the address.
    context.go(path != null && path.startsWith('/v1/') ? path : '/v1/chats');
  }

  @override
  Widget build(BuildContext context) => const SigningInPage();
}
