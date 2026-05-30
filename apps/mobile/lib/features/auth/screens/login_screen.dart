import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/auth/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onLogin,
    this.onForgotPassword,
    this.onCreateAccount,
  });

  final Future<void> Function(String email, String password)? onLogin;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _formEverSubmitted = false;

  bool _emailValid = false;
  bool _passwordValid = false;
  bool get _canSubmit => _emailValid && _passwordValid && !_isLoading;

  late AnimationController _entranceController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
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

    _slideAnims = intervals.map((interval) {
      return Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(interval.begin, interval.end, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _fadeAnims = intervals.map((interval) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(interval.begin, interval.end, curve: Curves.easeOut),
        ),
      );
    }).toList();

    _entranceController.forward();

    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _emailValid = AppValidators.email(_emailController.text) == null;
      _passwordValid = AppValidators.password(_passwordController.text) == null;
    });
    if (_formEverSubmitted) _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _formEverSubmitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await (widget.onLogin?.call(
        _emailController.text.trim(),
        _passwordController.text,
      ) ??
          Future.delayed(const Duration(seconds: 2)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
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
                      // Logo - Hidden when keyboard is visible to prevent overflow
                      if (!isKeyboardVisible) ...[
                        AnimatedSection(
                          slide: _slideAnims[0],
                          fade: _fadeAnims[0],
                          child: buildLogo(isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Title + subtitle
                      AnimatedSection(
                        slide: _slideAnims[1],
                        fade: _fadeAnims[1],
                        child: _buildFormCard(isDark, isKeyboardVisible),
                      ),

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

  // ── Headline ─────────────────────────────────

  Widget _buildHeadline(bool isDark) {
    return Column(
      children: [
        Text(
          'Welcome back',
          style: AppTextStyles.displayLarge(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Glad to see you again',
          style: AppTextStyles.bodyMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        GestureDetector(
          onTap: widget.onCreateAccount,
          child: Text(
            'Create account',
            style: AppTextStyles.bodyMedium(AppColors.primary).copyWith(
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.arrow_forward_rounded,
          size: 14,
          color: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, bool isKeyboardVisible) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        autovalidateMode: _formEverSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              validator: AppValidators.email,
              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              hintText: 'Password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              validator: AppValidators.password,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onForgotPassword,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: AppTextStyles.bodyMedium(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Log in',
              isLoading: _isLoading,
              isDisabled: !_canSubmit,
              onPressed: _canSubmit ? _handleLogin : null,
              trailingIcon: _isLoading ? null : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
            if (!isKeyboardVisible) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'or',
                      style: AppTextStyles.bodyMedium(isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildSocialButtons(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isDark) {
    final buttonColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    Widget socialBtn(Widget icon, String tooltip, VoidCallback onTap) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: buttonColor,
              border: Border.all(color: borderColor),
              boxShadow: isDark ? [] : AppShadows.cardLight,
            ),
            child: Center(child: icon),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        socialBtn(
          Image.network(
            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
            width: 24,
            height: 24,
          ),
          'Sign in with Google',
          () {},
        ),
        const SizedBox(width: AppSpacing.lg),
        socialBtn(
          Icon(Icons.apple, color: isDark ? Colors.white : Colors.black, size: 34),
          'Sign in with Apple',
          () {},
        ),
      ],
    );
  }
}
