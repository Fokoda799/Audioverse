import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// Button variant enum
enum AppButtonVariant { primary, secondary, ghost }

/// ─────────────────────────────────────────────
/// AppButton
///
/// Reusable button with three variants:
///   • primary   – filled blue, glow shadow
///   • secondary – outlined, no fill
///   • ghost     – text only
///
/// Automatically switches to disabled state when
/// [onPressed] is null or [isDisabled] is true.
/// Shows a spinner when [isLoading] is true.
/// ─────────────────────────────────────────────
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 56,
    this.icon,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final Widget? icon;
  final Widget? trailingIcon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  bool get _isInteractive =>
      !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

  void _handleTapDown(TapDownDetails _) {
    if (_isInteractive) _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isInteractive) _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _isInteractive ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: _buildDecoration(isDark),
          child: _buildContent(isDark),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    final disabled = !_isInteractive;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          gradient: disabled
              ? null
              : const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          color: disabled
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : null,
          boxShadow: disabled ? [] : AppShadows.buttonPrimary,
        );

      case AppButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: disabled
                ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                : AppColors.primary,
            width: 1.5,
          ),
          color: Colors.transparent,
        );

      case AppButtonVariant.ghost:
        return const BoxDecoration();
    }
  }

  Widget _buildContent(bool isDark) {
    final disabled = !_isInteractive;

    Color labelColor;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        labelColor = disabled
            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
            : Colors.white;
        break;
      case AppButtonVariant.secondary:
        labelColor = disabled
            ? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)
            : AppColors.primary;
        break;
      case AppButtonVariant.ghost:
        labelColor = AppColors.primary;
        break;
    }

    return Center(
      child: widget.isLoading
          ? SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(labelColor),
        ),
      )
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            widget.label,
            style: AppTextStyles.labelLarge(labelColor),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: AppSpacing.sm),
            widget.trailingIcon!,
          ],
        ],
      ),
    );
  }
}
