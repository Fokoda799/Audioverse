import 'package:flutter/material.dart';


/// ─────────────────────────────────────────────
/// Spacing
/// ─────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}


/// ─────────────────────────────────────────────
/// Border Radius
/// ─────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;
}


/// ─────────────────────────────────────────────
/// Shadows
/// ─────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> cardDark = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardLight = [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonPrimary = [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
