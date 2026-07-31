import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/auth/auth_provider.dart';
import 'package:Audioverse/features/auth/widgets/widgets.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onLogin});

  final VoidCallback? onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _formEverSubmitted = false;
  bool _emailValid = false;

  late AnimationController _entranceController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _emailController.addListener(_onFieldChanged);
  }

  void _setupAnimations() {
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Four staggered groups, same easing pattern as the rest of the
    // auth flow (login_screen.dart uses this exact interval set) so
    // register and login feel like the same app.
    final intervals = [
      const Interval(0.0, 0.5),
      const Interval(0.1, 0.6),
      const Interval(0.25, 0.85),
      const Interval(0.55, 1.0),
    ];

    _slideAnims = intervals
        .map((i) => Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(i.begin, i.end, curve: Curves.easeOut),
    )))
        .toList();

    _fadeAnims = intervals
        .map((i) => Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(i.begin, i.end, curve: Curves.easeOut),
    )))
        .toList();

    _entranceController.forward();
  }

  void _onFieldChanged() {
    setState(() {
      _emailValid = AppValidators.email(_emailController.text) == null;
    });
    if (_formEverSubmitted) _formKey.currentState?.validate();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    setState(() => _formEverSubmitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();

    // requestEmailVerification only asks the backend to send the
    // link — it must NOT create the account or log anyone in yet.
    // See auth_provider_additions.dart for the method itself.
    // final sent = await auth.requestEmailVerification(email);
    final sent = true;

    if (!mounted || !sent) return;

    // push (not go) so the back button returns here in case the
    // user typed the wrong address and wants to fix it.
    context.push('/register/check-email', extra: email);
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    await auth.googleSignIn();
    if (auth.isLoggedIn && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final canSubmit = _emailValid && !auth.isLoading;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final double size = isKeyboardVisible ? 80 : 120;

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
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSection(
                        slide: _slideAnims[0],
                        fade: _fadeAnims[0],
                        child: buildLogo(isDark),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      AnimatedSection(
                        slide: _slideAnims[0],
                        fade: _fadeAnims[0],
                        child: AnimatedHeroGraphic(size: size),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 3 — headline
                      AnimatedSection(
                        slide: _slideAnims[1],
                        fade: _fadeAnims[1],
                        child: _buildHeadline(isDark),
                      ),

                      const SizedBox(height: AppSpacing.xxxl),

                      // 4-6 — Google button, divider, email field
                      AnimatedSection(
                        slide: _slideAnims[2],
                        fade: _fadeAnims[2],
                        child: _buildFormCard(isDark, auth, canSubmit),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // 7-8 — login link + legal text
                      AnimatedSection(
                        slide: _slideAnims[3],
                        fade: _fadeAnims[3],
                        child: _buildFooter(context, isDark),
                      ),

                      // const SizedBox(height: AppSpacing.sm),
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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: isKeyboardVisible ? AppTextStyles.bodyLarge(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ) : AppTextStyles.displayLarge(
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Listen. Learn. Imagine.',
          textAlign: TextAlign.center,
          style: isKeyboardVisible ? AppTextStyles.bodyMedium(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ) : AppTextStyles.labelLarge(
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, AuthProvider auth, bool canSubmit) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal:  AppSpacing.sm, vertical: AppSpacing.md),
      child: Form(
        key: _formKey,
        autovalidateMode: _formEverSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isKeyboardVisible) ...[
              GoogleSignInButton(
                onPressed: _handleGoogleSignIn,
                isLoading: auth.isLoading,
              ),

              const SizedBox(height: AppSpacing.md),
              const OrDivider(),
              const SizedBox(height: AppSpacing.md),
            ],

            AppTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              hintText: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              validator: AppValidators.email,
              onFieldSubmitted: (_) => _handleContinue(),
              onActionPressed: canSubmit ? _handleContinue : null,
              actionIcon: Icons.arrow_forward_rounded,
              isLoading: auth.isLoading
            ),

            if (auth.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              _ErrorBanner(message: auth.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        if (!isKeyboardVisible) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: AppTextStyles.bodyMedium(
                  isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              GestureDetector(
                onTap: widget.onLogin ?? () => context.go('/login'),
                child: Text(
                  'Log in',
                  style: AppTextStyles.bodyMedium(AppColors.primary).copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        LegalFooterText(
          onTermsTap: () => context.push('/legal/terms'),
          onPrivacyTap: () => context.push('/legal/privacy'),
          onDeleteAccountInfoTap: () => context.push('/legal/delete-account'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyMedium(AppColors.error)),
          ),
        ],
      ),
    );
  }
}
