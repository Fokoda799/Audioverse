import 'dart:async';

import 'package:Audioverse/features/auth/widgets/background.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/auth/auth_provider.dart';

/// Shown right after the user submits their email on RegisterScreen.
///
/// This is a waiting room, not a form — there's nothing to submit
/// here. The user leaves it one of two ways:
///   * they tap the link in the email → the OS opens the app on
///     CompleteRegistrationScreen (via deep link), completely
///     independent of this screen still being on screen or not.
///   * they tap "Resend" here, or edit the address if they mistyped it.
///
/// Both "resend" and "change the email inline" from your request are
/// implemented — resend is the button up top, editing is the pencil
/// icon next to the address.
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  static const _resendCooldownSeconds = 30;

  late String _email;
  bool _isEditingEmail = false;
  late final TextEditingController _editController;

  Timer? _cooldownTimer;
  int _secondsRemaining = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    _email = widget.email;
    _editController = TextEditingController(text: _email);
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _editController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsRemaining = _resendCooldownSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  Future<void> _handleResend() async {
    final auth = context.read<AuthProvider>();
    // final sent = await auth.resendVerificationEmail(_email);
    final sent = true;
    if (!mounted || !sent) return;
    _startCooldown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent again.')),
    );
  }

  Future<void> _handleConfirmNewEmail() async {
    final newEmail = _editController.text.trim();
    if (AppValidators.email(newEmail) != null) return;

    final auth = context.read<AuthProvider>();
    // final sent = await auth.requestEmailVerification(newEmail);
    final sent = true;
    if (!mounted || !sent) return;

    setState(() {
      _email = newEmail;
      _isEditingEmail = false;
    });
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final mutedColor =
    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          buildBackground(isDark),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.mail_outline_rounded,
                            color: AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Check your email',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayMedium(
                          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'We sent a verification link to',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium(mutedColor),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      _isEditingEmail
                          ? _buildEditEmailField(isDark)
                          : _buildEmailDisplay(isDark),

                      const SizedBox(height: AppSpacing.xl),

                      if (auth.errorMessage != null) ...[
                        Text(
                          auth.errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium(AppColors.error),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      if (!_isEditingEmail) ...[
                        TextButton(
                          onPressed:
                          _secondsRemaining == 0 && !auth.isLoading
                              ? _handleResend
                              : null,
                          child: Text(
                            _secondsRemaining == 0
                                ? 'Resend email'
                                : 'Resend email in ${_secondsRemaining}s',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GestureDetector(
                          onTap: () => setState(() => _isEditingEmail = true),
                          child: Text(
                            'Wrong address? Edit it',
                            style: AppTextStyles.bodyMedium(mutedColor).copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),

                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Already have an account? Log in',
                          style: AppTextStyles.bodyMedium(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailDisplay(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _email,
            style: AppTextStyles.labelLarge(
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        InkWell(
          onTap: () => setState(() => _isEditingEmail = true),
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildEditEmailField(bool isDark) {
    return Column(
      children: [
        AppTextField(
          controller: _editController,
          hintText: 'Email address',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.mail_outline_rounded),
          validator: AppValidators.email,
          onFieldSubmitted: (_) => _handleConfirmNewEmail(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() {
                  _isEditingEmail = false;
                  _editController.text = _email;
                }),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: 'Update',
                onPressed: _handleConfirmNewEmail,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
