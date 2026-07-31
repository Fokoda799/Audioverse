import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// The small print under the email field on the register screen:
/// "By continuing, you agree to our Terms of Service and Privacy
/// Policy. You can delete your account at any time."
///
/// The account-deletion mention matters beyond just being polite —
/// Apple's App Store review requires apps that support account
/// creation to also make account deletion easy to find, and putting
/// a pointer to it right on the sign-up screen is a simple way to
/// satisfy that.
///
/// This widget only renders text and reports taps — it deliberately
/// doesn't launch URLs or navigate itself, so you can wire each
/// callback to a WebView, an external browser (url_launcher), or an
/// in-app legal screen, whatever you're already using.
class LegalFooterText extends StatelessWidget {
  const LegalFooterText({
    super.key,
    required this.onTermsTap,
    required this.onPrivacyTap,
    required this.onDeleteAccountInfoTap,
  });

  final VoidCallback onTermsTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onDeleteAccountInfoTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor =
    isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final linkStyle = AppTextStyles.labelSmall(AppColors.primary);
    final baseStyle = AppTextStyles.labelSmall(mutedColor);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: linkStyle,
            // TapGestureRecognizer is what makes a span inside a
            // single Text.rich block individually tappable — a
            // plain GestureDetector can't wrap just one word.
            recognizer: TapGestureRecognizer()..onTap = onTermsTap,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
          ),
          const TextSpan(text: '. You can '),
          TextSpan(
            text: 'delete your account',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onDeleteAccountInfoTap,
          ),
          const TextSpan(text: ' at any time.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
