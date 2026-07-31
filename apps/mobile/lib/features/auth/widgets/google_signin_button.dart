import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  /// Called on tap. Pass `null` to disable the button (e.g. while
  /// another sign-in request is already in flight).
  final VoidCallback? onPressed;

  /// Shows a spinner instead of the label/icon when true.
  final bool isLoading;

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
    isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        // Material + InkWell (rather than a plain GestureDetector) so
        // the button gets the platform-correct tap ripple for free.
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: isLoading ? null : onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: isDark ? [] : AppShadows.cardLight,
            ),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Same asset + fallback pattern the codebase
                // already uses in login_screen.dart, so this
                // still renders correctly even before you add
                // a real google.png asset.
                Image.asset(
                  'assets/icons/google.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.g_mobiledata_rounded,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: AppTextStyles.labelLarge(textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
