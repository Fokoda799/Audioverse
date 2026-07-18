import 'package:Audioverse/features/auth/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';


// ─────────────────────────────────────────────────────────────
// The forgot password flow has 3 steps:
//   Step 1 → Enter email → send code
//   Step 2 → Enter 6-digit code → verify
//   Step 3 → Enter new password → done
// ─────────────────────────────────────────────────────────────

enum _Step { email, code, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.onSendCode,
    this.onVerifyCode,
    this.onResetPassword,
    this.onBackToLogin,
  });

  /// Called with (email) → triggers POST /auth/forgot-password
  final Future<void> Function(String email)? onSendCode;

  /// Called with (email, code) → triggers POST /auth/verify-code
  final Future<void> Function(String email, String code)? onVerifyCode;

  /// Called with (email, code, newPassword) → triggers POST /auth/reset-password
  final Future<void> Function(String email, String code, String newPassword)? onResetPassword;

  /// Navigation back to LoginScreen
  final VoidCallback? onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {

  _Step _currentStep = _Step.email;

  // ── Shared state across steps ─────────────────────────────
  String _submittedEmail = '';
  String _verifiedCode = '';
  bool _isLoading = false;

  // ── Step 1: Email ─────────────────────────────────────────
  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailFormSubmitted = false;
  bool get _emailValid =>
      AppValidators.email(_emailController.text) == null;

  // ── Step 2: Code (6 individual digit boxes) ───────────────
  final List<TextEditingController> _codeControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
  List.generate(6, (_) => FocusNode());
  String get _fullCode =>
      _codeControllers.map((c) => c.text).join();
  bool get _codeComplete => _fullCode.length == 6;

  // Resend countdown
  int _resendCooldown = 0;

  // ── Step 3: New password ──────────────────────────────────
  final _passwordFormKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordFormSubmitted = false;
  bool get _passwordValid =>
      AppValidators.password(_newPasswordController.text) == null &&
          _confirmPasswordController.text == _newPasswordController.text &&
          _confirmPasswordController.text.isNotEmpty;

  // ── Entrance animation ────────────────────────────────────
  late AnimationController _entranceController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _emailController.addListener(() => setState(() {}));
    _newPasswordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  void _setupAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final intervals = [
      const Interval(0.0, 0.5),
      const Interval(0.1, 0.6),
      const Interval(0.2, 0.8),
      const Interval(0.55, 1.0),
    ];

    _slideAnims = intervals.map((i) {
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(i.begin, i.end, curve: Curves.easeOut),
      ));
    }).toList();

    _fadeAnims = intervals.map((i) {
      return Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(i.begin, i.end, curve: Curves.easeOut),
      ));
    }).toList();

    _entranceController.forward();
  }

  // Re-run entrance animation when the step changes
  void _animateToNextStep(VoidCallback stepChange) {
    _entranceController.reverse().then((_) {
      setState(stepChange);
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Step handlers ─────────────────────────────────────────

  Future<void> _handleSendCode() async {
    setState(() => _emailFormSubmitted = true);
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await (widget.onSendCode?.call(_emailController.text.trim()) ??
          Future.delayed(const Duration(seconds: 2)));
      _submittedEmail = _emailController.text.trim();
      _startResendCooldown();
      _animateToNextStep(() => _currentStep = _Step.code);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyCode() async {
    if (!_codeComplete) return;

    setState(() => _isLoading = true);
    try {
      await (widget.onVerifyCode?.call(_submittedEmail, _fullCode) ??
          Future.delayed(const Duration(seconds: 2)));
      _verifiedCode = _fullCode;
      _animateToNextStep(() => _currentStep = _Step.newPassword);
    } catch (e) {
      _showError('Invalid code. Please try again.');
      // Clear code boxes on wrong code
      for (final c in _codeControllers) {
        c.clear();
      }
      _codeFocusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    setState(() => _passwordFormSubmitted = true);
    if (!(_passwordFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await (widget.onResetPassword?.call(
        _submittedEmail,
        _verifiedCode,
        _newPasswordController.text,
      ) ??
          Future.delayed(const Duration(seconds: 2)));
      // On success — go back to login
      widget.onBackToLogin?.call();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendCode() async {
    if (_resendCooldown > 0) return;
    setState(() => _isLoading = true);
    try {
      await (widget.onSendCode?.call(_submittedEmail) ??
          Future.delayed(const Duration(seconds: 1)));
      _startResendCooldown();
      for (final c in _codeControllers) {
        c.clear();
      }
      _codeFocusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Counts down 60s before allowing resend
  void _startResendCooldown() {
    setState(() => _resendCooldown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // REUSED: shared logo widget
                      if (!isKeyboardVisible) ...[
                        AnimatedSection(
                          slide: _slideAnims[0],
                          fade: _fadeAnims[0],
                          child: buildLogo(isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Step indicator + headline
                      AnimatedSection(
                        slide: _slideAnims[1],
                        fade: _fadeAnims[1],
                        child: _buildHeadline(isDark),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Step content card
                      AnimatedSection(
                        slide: _slideAnims[2],
                        fade: _fadeAnims[2],
                        child: _buildStepCard(isDark),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Back to login
                      AnimatedSection(
                        slide: _slideAnims[3],
                        fade: _fadeAnims[3],
                        child: _buildFooter(isDark),
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

  // ── Headline — changes per step ───────────────────────────

  Widget _buildHeadline(bool isDark) {
    final titles = {
      _Step.email: ('Forgot password?', 'Enter your email to receive a code'),
      _Step.code: ('Check your email', 'We sent a 6-digit code to\n$_submittedEmail'),
      _Step.newPassword: ('New password', 'Choose a strong password'),
    };

    final (title, subtitle) = titles[_currentStep]!;

    return Column(
      children: [
        // Step dots indicator
        _buildStepDots(),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: AppTextStyles.displayLarge(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStepDots() {
    final stepIndex = _Step.values.indexOf(_currentStep);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == stepIndex;
        final isDone = i < stepIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isDone || isActive
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }

  // ── Card — switches content based on step ─────────────────

  Widget _buildStepCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: switch (_currentStep) {
        _Step.email      => _buildEmailStep(),
        _Step.code       => _buildCodeStep(isDark),
        _Step.newPassword => _buildNewPasswordStep(),
      },
    );
  }

  // ── STEP 1: Email input ───────────────────────────────────

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      autovalidateMode: _emailFormSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _emailController,
            hintText: 'Email address',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            validator: AppValidators.email,
            onFieldSubmitted: (_) => _handleSendCode(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Send code',
            isLoading: _isLoading,
            isDisabled: !_emailValid || _isLoading,
            onPressed: _emailValid && !_isLoading ? _handleSendCode : null,
            trailingIcon: _isLoading
                ? null
                : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── STEP 2: 6-digit code boxes ────────────────────────────

  Widget _buildCodeStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 6 individual digit input boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildCodeBox(i, isDark)),
        ),

        const SizedBox(height: AppSpacing.lg),

        AppButton(
          label: 'Verify code',
          isLoading: _isLoading,
          isDisabled: !_codeComplete || _isLoading,
          onPressed: _codeComplete && !_isLoading ? _handleVerifyCode : null,
          trailingIcon: _isLoading
              ? null
              : const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        ),

        const SizedBox(height: AppSpacing.md),

        // Resend code row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive it? ",
              style: AppTextStyles.bodyMedium(
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            GestureDetector(
              onTap: _resendCooldown == 0 ? _handleResendCode : null,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : 'Resend code',
                style: AppTextStyles.bodyMedium(
                  _resendCooldown > 0
                      ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
                      : AppColors.primary,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: _resendCooldown == 0 ? TextDecoration.underline : null,
                  decorationColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeBox(int index, bool isDark) {
    return SizedBox(
      width: 44,
      height: 54,
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        // Only allow digits
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTextStyles.displayMedium(
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        decoration: InputDecoration(
          counterText: '', // hides the "0/1" counter
          filled: true,
          fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            // Auto-advance to next box
            _codeFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            // Auto-retreat on delete
            _codeFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  // ── STEP 3: New password ──────────────────────────────────

  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      autovalidateMode: _passwordFormSubmitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _newPasswordController,
            hintText: 'New password',
            isPassword: true,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            validator: AppValidators.password,
          ),

          const SizedBox(height: AppSpacing.md),

          AppTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm new password',
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _newPasswordController.text) return 'Passwords do not match';
              return null;
            },
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),

          const SizedBox(height: AppSpacing.lg),

          AppButton(
            label: 'Reset password',
            isLoading: _isLoading,
            isDisabled: !_passwordValid || _isLoading,
            onPressed: _passwordValid && !_isLoading ? _handleResetPassword : null,
            trailingIcon: _isLoading
                ? null
                : const Icon(Icons.check_circle_outline_rounded,
                color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.arrow_back_rounded, size: 14, color: AppColors.primary),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: widget.onBackToLogin ?? () {},
          child: Text(
            'Back to login',
            style: AppTextStyles.bodyMedium(AppColors.primary).copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
