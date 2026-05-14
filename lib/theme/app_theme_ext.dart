import 'package:flutter/material.dart';
import 'app_colors.dart';

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bg => isDark ? const Color(0xFF0D0D0F) : AppColors.background;
  Color get surface => isDark ? const Color(0xFF1A1A1F) : AppColors.surface;
  Color get card => isDark ? const Color(0xFF1A1A1F) : AppColors.card;
  Color get textDark => isDark ? const Color(0xFFF0F0F0) : AppColors.textDark;
  Color get textGrey => isDark ? const Color(0xFF9CA3AF) : AppColors.textGrey;
  Color get textLight => isDark ? const Color(0xFF6B7280) : AppColors.textLight;
  Color get divider => isDark ? const Color(0xFF252530) : AppColors.divider;
  Color get inactive => isDark ? const Color(0xFF4B5563) : AppColors.inactive;
  Color get primarySurface => isDark ? const Color(0xFF2D1208) : AppColors.primarySurface;
}
