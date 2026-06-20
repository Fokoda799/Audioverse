import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';
import 'package:Audioverse/core/widgets/widgets.dart';

// SearchErrorState
//
// Shown when SearchProvider.errorMessage is set — network failure,
// server error, etc. Named SearchErrorState (not just ErrorState) to
// avoid colliding with similarly-named private error widgets in other
// screens (e.g. ContentDetailScreen's _ErrorView) now that this is a
// public, importable widget rather than a file-private class.
//
// search_error_state.dart

class SearchErrorState extends StatelessWidget {
  const SearchErrorState({
    super.key,
    required this.message,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onRetry,
  });

  final String message;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 36, color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge(textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium(textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Try again',
              onPressed: onRetry,
              variant: AppButtonVariant.primary,
              width: 160,
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
