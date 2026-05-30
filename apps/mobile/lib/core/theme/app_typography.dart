import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// Typography
/// ─────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  static const _fontFamily = 'SF Pro Display'; // fallback to system

  static TextStyle displayLarge(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle displayMedium(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle titleLarge(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.2,
  );

  static TextStyle bodyLarge(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle labelLarge(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.2,
  );

  static TextStyle labelSmall(Color color) => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: color,
  );
}
