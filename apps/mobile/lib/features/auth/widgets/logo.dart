import 'package:Audioverse/core/theme/theme.dart';
import 'package:flutter/material.dart';


Widget buildLogo(bool isDark) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset(
        "assets/icons/app_icon_foreground.png",
        width: 30,
        height: 32,
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        'AudioVerse',
        style: AppTextStyles.displayMedium(
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    ],
  );
}