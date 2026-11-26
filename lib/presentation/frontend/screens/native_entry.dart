import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../dal/remote/auth_api_adapter.dart';
import '../../../domain/services/auth_service.dart';
import '../../../domain/services/session_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../theme/app_icons.dart';

class NativeEntryPage extends StatefulWidget {
  const NativeEntryPage({super.key, required this.auth, required this.session});
  final AuthService auth;
  final SessionController session;

  @override
  State<NativeEntryPage> createState() => _NativeEntryPageState();
}

class _NativeEntryPageState extends State<NativeEntryPage>
    with WidgetsBindingObserver {
  NativeLoginAttempt? _attempt;
  bool _busy = false;
  bool _restoring = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
    if (widget.session.signedIn) _openChats();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _attempt != null && !_busy) {
      _checkStatus();
    }
  }

  Future<void> _restore() async {
    try {
      final pending = await widget.auth.restoreNativeLogin();
      if (mounted) {
        setState(() {
          _attempt = pending;
          _restoring = false;
        });
        if (pending != null) _checkStatus();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _message = AppLocalizations.of(context).nativeLoginError;
          _restoring = false;
        });
      }
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final attempt = await widget.auth.startNativeLogin();
      if (mounted) setState(() => _attempt = attempt);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).nativeLoginError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _checkStatus() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final status = await widget.auth.checkNativeLogin();
      if (!mounted) return;
      setState(() {
        _message = status == 'done'
            ? AppLocalizations.of(context).nativeBrowserOpened
            : status == 'cancelled'
            ? AppLocalizations.of(context).nativeLoginCancelled
            : null;
      });
    } on NativeHandoffException catch (error) {
      await _handleHandoffError(error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).nativeLoginError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final location = await widget.auth.finishNativeLogin();
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            location == null
                ? l.nativeLoggedIn
                : l.nativeLoggedInFrom(location),
          ),
        ),
      );
      await widget.session.refresh();
      _openChats();
    } on NativeHandoffException catch (error) {
      await _handleHandoffError(error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).nativeLoginError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.auth.cancelNativeLogin();
      if (mounted) {
        setState(() {
          _attempt = null;
          _message = AppLocalizations.of(context).nativeLoginCancelled;
        });
      }
    } on NativeHandoffException catch (error) {
      await _handleHandoffError(error);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = AppLocalizations.of(context).nativeLoginError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _localizedError(String code) {
    final l = AppLocalizations.of(context);
    return switch (code) {
      'HANDOFF_NOT_FINISHED' => l.nativeLoginNotFinished,
      'HANDOFF_EXPIRED' => l.nativeLoginExpired,
      'LOGIN_REFUSED_NETWORK' => l.nativeLoginRefused,
      'HANDOFF_CANCELLED' => l.nativeLoginCancelled,
      'HANDOFF_USED' => l.nativeLoginUsed,
      'TIMEOUT' => l.nativeLoginError,
      _ => l.nativeLoginError,
    };
  }

  Future<void> _handleHandoffError(NativeHandoffException error) async {
    if (const {
      'HANDOFF_EXPIRED',
      'HANDOFF_CANCELLED',
      'HANDOFF_USED',
      'LOGIN_REFUSED_NETWORK',
    }.contains(error.code)) {
      await widget.auth.discardNativeLogin();
      if (mounted) {
        setState(() {
          _attempt = null;
          _message = _localizedError(error.code);
        });
      }
    } else if (mounted) {
      setState(() => _message = _localizedError(error.code));
    }
  }

  void _openChats() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/v1/chats');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Icon(AppIcons.chats, size: 42, color: colors.primary),
                const SizedBox(height: 24),
                Text(
                  l.nativeWelcomeTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  l.nativeWelcomeBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (_attempt case final attempt?) ...[
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l.nativeMatchCode,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          SelectableText(
                            attempt.matchCode,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.nativeBrowserOpened,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _finish,
                    child: Text(
                      _busy ? l.nativeLoginChecking : l.nativeFinishLogin,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _cancel,
                    child: Text(l.nativeCancelLogin),
                  ),
                ] else ...[
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _busy || _restoring ? null : _start,
                    child: Text(l.nativeSignIn),
                  ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, style: TextStyle(color: colors.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
