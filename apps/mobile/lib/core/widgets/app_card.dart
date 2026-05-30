import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// ─────────────────────────────────────────────
/// AppCard
///
/// Frosted-glass-inspired card used to wrap forms
/// and content sections. Automatically adapts to
/// light / dark theme.
/// ─────────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.width,
    this.constraints,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? width;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.xl;

    return Container(
      width: width,
      margin: margin,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder.withOpacity(0.6)
              : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Padding(
          padding: padding ??
              const EdgeInsets.all(AppSpacing.lg),
          child: child,
        ),
      ),
    );
  }
}
