import 'package:flutter/material.dart';

/// Modern gradient color scheme for the app
class AppColors {
  AppColors._();

  // Primary Blue Gradient
  static const Color primaryBlue = Color(0xFF3B82F6); // Modern blue
  static const Color primaryBlueDark = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  // Secondary Orange Gradient
  static const Color secondaryOrange = Color(0xFFF97316); // Vibrant orange
  static const Color secondaryOrangeDark = Color(0xFFEA580C);
  static const Color secondaryOrangeLight = Color(0xFFFB923C);

  // Tertiary Black/Gray
  static const Color tertiaryBlack = Color(0xFF1F2937);
  static const Color tertiaryGray = Color(0xFF374151);
  static const Color tertiaryLightGray = Color(0xFF6B7280);

  // Accent Colors
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentRed = Color(0xFFEF4444);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF1F5F9);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueDark],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryOrange, secondaryOrangeDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPurple, accentCyan],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundLight, surfaceLight],
  );

  // Animated Gradient (for dynamic backgrounds)
  static List<Color> get animatedGradientColors => [
        primaryBlue.withOpacity(0.1),
        secondaryOrange.withOpacity(0.1),
        accentPurple.withOpacity(0.1),
        accentCyan.withOpacity(0.1),
      ];
}

