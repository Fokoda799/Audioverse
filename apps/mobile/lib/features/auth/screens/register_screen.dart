import 'package:Audioverse/features/auth/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/auth/widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.onRegister,
    this.onLogin,
  });

  final Future<void> Function(String name, String email, String password)? onRegister;
  final VoidCallback? onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isLoading = false;
  bool _formEverSubmitted = false;

  bool _nameValid = false;
  bool _emailValid = false;
  bool _passwordValid = false;
  bool _confirmValid = false;

  bool get _canSubmit => _nameValid && _emailValid && _passwordValid && _confirmValid && !_isLoading;

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

    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    setState(() {
      _nameValid = AppValidators.name(_nameController.text) == null;
      _emailValid = AppValidators.email(_emailController.text) == null;
      _passwordValid = AppValidators.password(_passwordController.text) == null;
      _confirmValid = _confirmPasswordController.text == _passwordController.text && _confirmPasswordController.text.isNotEmpty;
    });
    if (_formEverSubmitted) _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _formEverSubmitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await (widget.onRegister?.call(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          ) ??
          context.read<AuthProvider>().register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
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
                        child: _buildFormCard(isDark),
                      ),

                      const SizedBox(height: AppSpacing.lg),

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

  Widget _buildHeadline(bool isDark) {
    return Column(
      children: [
        Text(
          'Create account',
          style: AppTextStyles.displayLarge(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Join AudioVerse today',
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
          'Already have an account? ',
          style: AppTextStyles.bodyMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        GestureDetector(
          onTap: widget.onLogin ?? () {},
          child: Text(
            'Log in',
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

  Widget _buildFormCard(bool isDark) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        autovalidateMode: _formEverSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              focusNode: _nameFocus,
              hintText: 'Full name',
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: AppValidators.name,
              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
            ),
            const SizedBox(height: AppSpacing.md),
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
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              validator: AppValidators.password,
              onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmFocus),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _confirmPasswordController,
              focusNode: _confirmFocus,
              hintText: 'Confirm password',
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Create account',
              isLoading: _isLoading,
              isDisabled: !_canSubmit,
              onPressed: _canSubmit ? _handleRegister : null,
              trailingIcon: _isLoading ? null : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
