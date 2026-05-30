import 'package:Audioverse/core/theme/theme.dart';
import 'package:flutter/material.dart';


Widget buildLogo(bool isDark) {
  return Column(
    children: [
      Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.headphones_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        'AudioVerse',
        style: AppTextStyles.displayMedium(
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Listen. Imagine. Inspire.',
        style: AppTextStyles.bodyMedium(
          isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    ],
  );
}