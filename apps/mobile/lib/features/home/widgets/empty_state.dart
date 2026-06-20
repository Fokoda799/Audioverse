import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

// EmptyState
//
// A single reusable "nothing here" widget, used wherever a section has
// no data to show: empty content grid, empty search results, no
// continue-listening history yet, etc. Each call site supplies its own
// icon and copy so the message stays specific to what's actually empty,
// per the design system's writing guidance — an empty screen should be
// an invitation to act, not a generic placeholder.
//
// empty_state.dart

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String message;

  // Compact mode: smaller icon/spacing, used for inline sections
  // (e.g. an empty Continue Listening row) rather than a full-screen state.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 28 : 36,
              color: AppColors.textSecondaryDark,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleLarge(AppColors.textPrimaryDark),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }
}
