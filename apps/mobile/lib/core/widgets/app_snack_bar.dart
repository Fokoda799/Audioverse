import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

enum AppSnackBarType {
  success,
  error,
  info,
  warning,
}

class AppSnackBar {
  AppSnackBar._();

  static void show(
      BuildContext context, {
        required String message,
        AppSnackBarType type = AppSnackBarType.info,
        Duration duration = const Duration(seconds: 3),
        SnackBarAction? action,
      }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: _backgroundColor(type),
        elevation: 0,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        action: action,
        content: Row(
          children: [
            Icon(
              _icon(type),
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _backgroundColor(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Colors.green.shade600;

      case AppSnackBarType.error:
        return AppColors.error;

      case AppSnackBarType.warning:
        return Colors.orange.shade700;

      case AppSnackBarType.info:
        return AppColors.primary;
    }
  }

  static IconData _icon(AppSnackBarType type) {
    switch (type) {
      case AppSnackBarType.success:
        return Icons.check_circle_outline;

      case AppSnackBarType.error:
        return Icons.error_outline;

      case AppSnackBarType.warning:
        return Icons.warning_amber_rounded;

      case AppSnackBarType.info:
        return Icons.info_outline;
    }
  }
}
