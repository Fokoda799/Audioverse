import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────
/// Color Tokens
/// ─────────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1D4ED8);
  static const accent = Color(0xFF22C55E);

  // Neutrals – Dark surface
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkCard = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);

  // Neutrals – Light surface
  static const lightBackground = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);

  // Text
  static const textPrimaryDark = Color(0xFFF1F5F9);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textPrimaryLight = Color(0xFF0F172A);
  static const textSecondaryLight = Color(0xFF64748B);

  // Semantic
  static const error = Color(0xFFEF4444);
  static const errorSurface = Color(0xFF450A0A);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
}
