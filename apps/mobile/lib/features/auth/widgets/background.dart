import 'package:Audioverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';


Widget buildBackground(bool isDark) {
  return Stack(
    children: [
      // Base background image
      Positioned.fill(
        child: Image.network(
          isDark
              ? 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=2069&auto=format&fit=crop'
              : 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=1973&auto=format&fit=crop',
          fit: BoxFit.cover,
        ),
      ),
      // Tint overlay to maintain readability and match brand colors
      Positioned.fill(
        child: Container(
          color: (isDark ? AppColors.darkBackground : AppColors.lightBackground)
              .withValues(alpha: isDark ? 0.75 : 0.7),
        ),
      ),
      // Original decorative blobs
      Positioned.fill(
        child: CustomPaint(
          painter: _BackgroundPainter(isDark: isDark),
        ),
      ),
    ],
  );
}


class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right accent blob
    final blobPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.08),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.08),
          radius: size.width * 0.55,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.08),
      size.width * 0.55,
      blobPaint,
    );

    // Bottom-left accent blob
    final blobPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: isDark ? 0.10 : 0.05),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.05, size.height * 0.88),
          radius: size.width * 0.45,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.88),
      size.width * 0.45,
      blobPaint2,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.isDark != isDark;
}