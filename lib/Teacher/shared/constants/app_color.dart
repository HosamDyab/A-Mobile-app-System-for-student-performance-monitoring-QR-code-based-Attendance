import 'package:flutter/material.dart';

/// Centralized color constants for the application
/// 
/// All colors used throughout the app should reference this class
/// to maintain consistency and make theme changes easier.
class AppColors {
  // Prevent instantiation
  AppColors._();

  /// Primary brand color - Orange (#FF6B00)
  static const Color primary = Color(0xFFFF6B00);
  
  /// Success/Green color for positive actions (#2E7D32)
  static const Color success = Color(0xFF2E7D32);
  
  /// Warning/Amber color for cautionary messages (#FFA726)
  static const Color warning = Color(0xFFFFA726);
  
  /// Error/Red color for error states (#D32F2F)
  static const Color error = Color(0xFFD32F2F);

  // Additional semantic colors
  /// Background color for light theme
  static const Color lightBackground = Color(0xFFF5F5F5);
  
  /// Background color for dark theme
  static const Color darkBackground = Color(0xFF1A1A1A);
  
  /// Surface color for cards and containers
  static const Color surface = Colors.white;
  
  /// Text color for light theme
  static const Color textPrimary = Color(0xFF212121);
  
  /// Secondary text color
  static const Color textSecondary = Color(0xFF757575);
  
  /// Border color
  static const Color border = Color(0xFFE0E0E0);
  
  /// Divider color
  static const Color divider = Color(0xFFBDBDBD);
}