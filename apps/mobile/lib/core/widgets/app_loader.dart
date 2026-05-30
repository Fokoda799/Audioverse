import 'package:flutter/material.dart';
import 'package:Audioverse/core/theme/theme.dart';

/// ─────────────────────────────────────────────
/// AppLoader
///
/// Centered loading indicator. Can be used as
/// a full-screen overlay or inline.
///
/// [overlay] wraps in a semi-transparent scrim.
/// ─────────────────────────────────────────────
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 2.5,
    this.color,
    this.overlay = false,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool overlay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loaderColor = color ?? AppColors.primary;

    final loader = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
        backgroundColor: (isDark
            ? AppColors.darkBorder
            : AppColors.lightBorder)
            .withOpacity(0.4),
      ),
    );

    if (!overlay) return Center(child: loader);

    return Container(
      color: Colors.black.withOpacity(0.35),
      child: Center(child: loader),
    );
  }
}

/// Convenience: full-screen overlay loader
class AppOverlayLoader extends StatelessWidget {
  const AppOverlayLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black38,
      child: Center(
        child: AppLoader(size: 40, strokeWidth: 3),
      ),
    );
  }
}
