import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/utils/validators.dart';
import 'package:Audioverse/core/widgets/widgets.dart';
import 'package:Audioverse/features/auth/auth_provider.dart';

import 'package:Audioverse/features/auth/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onForgotPassword,
    this.onCreateAccount,
    // onLogin is REMOVED — the screen calls AuthProvider directly.
    // Navigation after login is handled by the router's redirect.
  });

  final VoidCallback? onForgotPassword;
  final VoidCallback? onCreateAccount;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus        = FocusNode();
  final _passwordFocus     = FocusNode();

  bool _formEverSubmitted = false;
  bool _emailValid        = false;
  bool _passwordValid     = false;

  // No _isLoading here — we read it from AuthProvider
  // to avoid duplicated state

  late AnimationController _entranceController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
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

    _slideAnims = intervals.map((i) =>
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(
          parent: _entranceController,
          curve: Interval(i.begin, i.end, curve: Curves.easeOut),
        )),
    ).toList();

    _fadeAnims = intervals.map((i) =>
        Tween<double>(begin: 0, end: 1)
            .animate(CurvedAnimation(
          parent: _entranceController,
          curve: Interval(i.begin, i.end, curve: Curves.easeOut),
        )),
    ).toList();

    _entranceController.forward();
  }

  void _onFieldChanged() {
    setState(() {
      _emailValid    = AppValidators.email(_emailController.text) == null;
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

    final auth = context.read<AuthProvider>();

    await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (auth.isLoggedIn && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // watch() — subscribes to AuthProvider rebuilds.
    // Every notifyListeners() call re-runs this build method.
    final auth = context.watch<AuthProvider>();

    // Derived from provider state — no local _isLoading needed
    final canSubmit = _emailValid && _passwordValid && !auth.isLoading;

    final scaffold = Scaffold(
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
                      if (!isKeyboardVisible) ...[
                        AnimatedSection(
                          slide: _slideAnims[0],
                          fade: _fadeAnims[0],
                          child: buildLogo(isDark),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // AnimatedSection(
                      //   slide: _slideAnims[1],
                      //   fade: _fadeAnims[1],
                      //   child: _buildHeadline(isDark),
                      // ),

                      const SizedBox(height: AppSpacing.lg),

                      AnimatedSection(
                        slide: _slideAnims[2],
                        fade: _fadeAnims[2],
                        child: _buildFormCard(isDark, isKeyboardVisible, auth, canSubmit),
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
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: AppButton(
                    label: "Skip for now",
                    variant: AppButtonVariant.ghost,
                    width: 100.0,
                    onPressed: () {
                      auth.setGuest();
                      context.go("/home");
                    }
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) return scaffold;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: scaffold,
    );
  }

  Widget _buildHeadline(bool isDark) {
    return Column(
      children: [
        Text('Welcome back',
            style: AppTextStyles.displayLarge(
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            )),
        const SizedBox(height: AppSpacing.xs),
        Text('Glad to see you again',
            style: AppTextStyles.bodyMedium(
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            )),
      ],
    );
  }

  Widget _buildFormCard(
      bool isDark,
      bool isKeyboardVisible,
      AuthProvider auth,  // passed from build() — no extra watch() needed
      bool canSubmit,
      ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        autovalidateMode: _formEverSubmitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
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
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
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

            // const SizedBox(height: AppSpacing.sm),
            //
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: widget.onForgotPassword,
            //     style: TextButton.styleFrom(
            //       padding: const EdgeInsets.symmetric(
            //           horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            //       minimumSize: Size.zero,
            //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            //     ),
            //     child: Text('Forgot password?',
            //         style: AppTextStyles.bodyMedium(AppColors.primary)),
            //   ),
            // ),

            const SizedBox(height: AppSpacing.md),

            // ── Error message from provider ─────────────────
            // Only shows when auth.errorMessage is non-null
            if (auth.errorMessage != null) ...[
              _ErrorBanner(message: auth.errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],

            AppButton(
              label: 'Log in',
              isLoading: auth.isLoading,   // from provider, not local state
              isDisabled: !canSubmit,
              onPressed: canSubmit ? _handleLogin : null,
              trailingIcon: auth.isLoading
                  ? null
                  : const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),

            if (!isKeyboardVisible) ...[
              const SizedBox(height: AppSpacing.md),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.md),
              _buildSocialButtons(isDark, context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isDark, BuildContext context) {
    final auth = context.read<AuthProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(
          tooltip: 'Sign in with Google',
          icon: Image.asset(
            'assets/icons/google.png',
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata_rounded,
                size: 30, color: AppColors.primary),
          ),
          isDark: isDark,
          onTap: () async {
            await auth.googleSignIn();
            if (auth.isLoggedIn && context.mounted) {
              context.go('/home');
            }
          },
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: AppTextStyles.bodyMedium(
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            )),
        GestureDetector(
          onTap: widget.onCreateAccount,
          child: Text('Create account',
              style: AppTextStyles.bodyMedium(AppColors.primary).copyWith(
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              )),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small private widgets — kept here since they're login-specific
// ─────────────────────────────────────────────────────────────

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
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodyMedium(AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or',
              style: AppTextStyles.bodyMedium(
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              )),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
  });

  final Widget icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 250, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: isDark ? [] : AppShadows.cardLight,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
