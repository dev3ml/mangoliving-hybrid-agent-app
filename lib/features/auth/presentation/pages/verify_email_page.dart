import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../controllers/auth_controller.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final TextEditingController _code = TextEditingController();
  Timer? _ticker;
  int _cooldown = 60;
  bool _busy = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _cooldown <= 0) return;
      setState(() => _cooldown -= 1);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _continueToApp() async {
    await ref.read(authControllerProvider.notifier).finishEmailVerification();
    if (mounted) context.go(AppRoutes.overview);
  }

  Future<void> _submit() async {
    final String code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifyEmail(code);
      if (mounted) context.go(AppRoutes.overview);
    } on Object catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    if (_cooldown > 0 || _resending) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      final result =
          await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      if (result.alreadyVerified) {
        await _continueToApp();
        return;
      }
      setState(() {
        _cooldown = result.cooldownSeconds ?? 60;
        _info = 'A new code has been sent to your email.';
      });
    } on VerificationCooldownException catch (error) {
      if (mounted) {
        setState(() {
          _cooldown = error.retryAfterSeconds;
          _error = error.message;
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String email =
        ref.watch(authControllerProvider).valueOrNull?.user.email ?? 'your email';
    final String? notice = ref.watch(signupNoticeProvider);

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : AppColors.mutedWash,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: const <Widget>[ThemeToggleButton()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We sent a 6-digit code to $email. The code expires in 15 minutes.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (notice != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(notice, style: theme.textTheme.bodySmall),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      if (_info != null && _error == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            _info!,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      TextField(
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        autofillHints: const <String>[AutofillHints.oneTimeCode],
                        style: theme.textTheme.headlineSmall,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          hintText: '000000',
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          TextButton(
                            onPressed: _cooldown > 0 || _resending ? null : _resend,
                            child: Text(
                              _cooldown > 0
                                  ? 'Resend in ${_cooldown}s'
                                  : _resending
                                      ? 'Sending…'
                                      : 'Resend code',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy ? null : _continueToApp,
                            child: const Text("I'll do this later"),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: Text(_busy ? 'Verifying…' : 'Verify email'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
