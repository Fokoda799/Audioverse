import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

// EmptyResultsState
//
// "No results for X" state — shown when SearchProvider.hasNoResults is
// true (i.e. the user searched and got zero matches). Distinct from
// ExploreSection, which shows when the user HASN'T searched yet —
// these are two different empty conditions with different copy and
// different visuals, so they stay as separate widgets rather than one
// "empty state" doing double duty with conditional text.
//
// empty_results_state.dart

class EmptyResultsState extends StatelessWidget {
  const EmptyResultsState({
    super.key,
    required this.query,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String query;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;

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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No results for "$query"',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge(textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try different keywords or check your spelling.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
