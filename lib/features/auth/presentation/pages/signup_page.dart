import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/env_config.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/mango_living_logo.dart';
import '../../../../core/widgets/theme_toggle_button.dart';
import '../../domain/signup_form.dart';
import '../controllers/auth_controller.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final TextEditingController _license = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _smsConsent = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    _license.dispose();
    super.dispose();
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final ({String firstName, String lastName}) name =
        SignupForm.splitName(_name.text);
    final SignupOutcome? outcome;
    try {
      outcome = await ref.read(authControllerProvider.notifier).signup(
              email: _email.text,
              password: _password.text,
              firstName: name.firstName,
              lastName: name.lastName,
              mobileNumber: _mobile.text,
              smsConsent: _smsConsent,
              licenseNumber: _license.text,
            );
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
      return;
    }
    if (!mounted || outcome == null) return;
    if (outcome.session.user.isEmailVerified) {
      context.go(AppRoutes.overview);
      return;
    }
    context.go(AppRoutes.verifyEmail);
  }

  Future<void> _openLegal(String path) async {
    final String base = EnvConfig.buyerAppUrl.replaceAll(RegExp(r'/+$'), '');
    final Uri uri = Uri.parse('$base$path');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<dynamic> auth = ref.watch(authControllerProvider);
    final bool loading = auth.isLoading;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool showSms = _mobile.text.length == 10;

    return Scaffold(
      backgroundColor: isDark ? theme.colorScheme.surface : AppColors.mutedWash,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: loading ? null : _backToLogin,
        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const MangoLivingLogo(),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Create your account',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Sign up to get started with MangoLiving™',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          autofillHints: const <String>[AutofillHints.name],
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            hintText: 'John Doe',
                          ),
                          inputFormatters: <TextInputFormatter>[
                            _NameInputFormatter(),
                          ],
                          validator: (String? value) =>
                              SignupForm.validateName(value ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          autofillHints: const <String>[AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'john@example.com',
                          ),
                          validator: (String? value) =>
                              SignupForm.validateEmail(value ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _mobile,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          autofillHints: const <String>[
                            AutofillHints.telephoneNumber,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Mobile number',
                            hintText: '(555) 000-0000',
                            prefixText: '+1 ',
                          ),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          onChanged: (String value) {
                            if (value.length != 10 && _smsConsent) {
                              setState(() => _smsConsent = false);
                            } else {
                              setState(() {});
                            }
                          },
                          validator: (String? value) =>
                              SignupForm.validateMobile(value ?? ''),
                        ),
                        if (showSms) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _smsConsent,
                            onChanged: loading
                                ? null
                                : (bool? value) => setState(
                                      () => _smsConsent = value ?? false,
                                    ),
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              'I agree to receive SMS account notifications, reminders, and in-app message alerts from MangoLiving™ (optional)',
                              style: theme.textTheme.bodySmall,
                            ),
                            subtitle: Text(
                              'Message frequency may vary. Standard message and data rates may apply. Reply STOP to opt out or HELP for help. Consent is not required to create your account.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          autofillHints: const <String>[AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) =>
                              SignupForm.validatePassword(value ?? ''),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _confirm,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.next,
                          enabled: !loading,
                          decoration: InputDecoration(
                            labelText: 'Confirm password',
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (String? value) =>
                              SignupForm.validateConfirmPassword(
                                _password.text,
                                value ?? '',
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextFormField(
                          controller: _license,
                          textInputAction: TextInputAction.done,
                          enabled: !loading,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'Real Estate Agent ID',
                            hintText: 'Enter your license number',
                            helperText: 'Required for verification',
                          ),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (String? value) =>
                              SignupForm.validateLicense(value ?? ''),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Container(
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
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Create account'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: loading ? null : _backToLogin,
                          child: const Text('Already have an account? Log in'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text.rich(
                          TextSpan(
                            text: 'By continuing, you agree to our ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            children: <InlineSpan>[
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () => _openLegal('/privacy'),
                                  child: Text(
                                    'Privacy Policy',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () => _openLegal('/terms'),
                                  child: Text(
                                    'Terms & Disclosures',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class _NameInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String next = SignupForm.sanitizeName(newValue.text);
    if (next == newValue.text) return newValue;
    final int end = newValue.selection.end.clamp(0, newValue.text.length);
    final int offset = SignupForm.sanitizeName(newValue.text.substring(0, end)).length;
    return TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: offset.clamp(0, next.length)),
    );
  }
}
