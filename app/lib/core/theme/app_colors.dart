import 'package:flutter/material.dart';

abstract final class AppColors {
  // Primary
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF5E92F3);
  static const primaryDark = Color(0xFF003C8F);
  static const onPrimary = Colors.white;

  // Secondary
  static const secondary = Color(0xFF455A64);
  static const secondaryLight = Color(0xFF718792);
  static const secondaryDark = Color(0xFF1C313A);
  static const onSecondary = Colors.white;

  // Surfaces — Light
  static const surfaceLight = Color(0xFFF8F9FA);
  static const backgroundLight = Colors.white;
  static const cardLight = Colors.white;
  static const dividerLight = Color(0xFFE0E0E0);

  // Surfaces — Dark
  static const surfaceDark = Color(0xFF1E1E1E);
  static const backgroundDark = Color(0xFF121212);
  static const cardDark = Color(0xFF2C2C2C);
  static const dividerDark = Color(0xFF3A3A3A);

  // Text — Light
  static const textPrimaryLight = Color(0xFF1A1A1A);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textDisabledLight = Color(0xFFB0B0B0);

  // Text — Dark
  static const textPrimaryDark = Color(0xFFF5F5F5);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const textDisabledDark = Color(0xFF6B6B6B);

  // Feedback
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFC62828);
  static const warning = Color(0xFFF9A825);
  static const info = Color(0xFF1565C0);
}
