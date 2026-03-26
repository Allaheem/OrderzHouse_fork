// ??? ????????
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Gradient definitions for the app
class AppGradients {
  AppGradients._();

  /// Primary button gradient - vertical gradient from orange to red
  /// Top: #FB923C (orange-400), Bottom: #EF4444 (red-500)
  /// Matches Tailwind: bg-gradient-to-b from-orange-400 to-red-500
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.gradientStart, // Orange-400
      AppColors.gradientEnd, // Red-500
    ],
  );

  // Legacy alias for backward compatibility
  static const LinearGradient primaryButton = primaryButtonGradient;
}
