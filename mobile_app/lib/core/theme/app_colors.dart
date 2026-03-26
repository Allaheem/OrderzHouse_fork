// ??? ????????
import 'package:flutter/material.dart';

/// Design tokens - Single source of truth for all colors
/// Theme: Near-black + Orange accent (0xFFFB923C)
class AppColors {
  AppColors._();

  // Core Theme Colors
  static const Color primary = Color(0xFFFB923C); // Near-black base
  static const Color accentOrange = Color(0xFFFB923C); // Main accent

  // Primary Variants (near-black)
  static const Color primaryDark = Color(0xFF0A0A0A); // Pressed/darker
  static const Color primaryLight = Color(0xFF1F1F1F); // Slightly lighter

  // Button Gradient (Tailwind: from-orange-400 to-red-500)
  static const Color gradientStart = Color(0xFFFB923C); // Orange-400
  static const Color gradientEnd = Color(0xFFEF4444); // Red-500

  // Secondary (kept for compatibility)
  static const Color secondary = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFF97316); // Orange-500
  static const Color secondaryLight = Color(0xFFFDBA74); // Orange-300

  // Neutral Colors
  static const Color background = Color(0xFFFFFFFF); // Pure white
  static const Color surface = Color(0xFFFFFFFF); // White (card background)
  static const Color surfaceVariant = Color(0xFFF9FAFB);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F0F0F); // Near-black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color danger = Color(0xFFEF4444); // For logout/delete actions

  // Border Colors
  static const Color border = Color(0xFFE5E7EB); // Light gray
  static const Color borderLight = Color(0xFFF3F4F6);

  // Chip Colors
  static const Color chipBg = Color(
    0xFFFFFFFF,
  ); // White background for inactive
  static const Color chipActiveBg = Color(0xFF0F0F0F); // Near-black for active
  static const Color chipBorder = Color(0xFFE5E7EB); // Light gray border
  static const Color chipText = Color(
    0xFF0F0F0F,
  ); // Near-black text for inactive
  static const Color chipActiveText = Color(
    0xFFFFFFFF,
  ); // White text for active

  // Icon Colors
  static const Color iconGray = Color(0xFF6B7280); // Gray for inactive icons
  static const Color iconActive = Color(0xFFFB923C); // Orange for active icons
  static const Color iconBlack = Color(
    0xFF0F0F0F,
  ); // Near-black for default icons

  // Shadow Colors
  static const Color shadowColor = Color(
    0x0D000000,
  ); // Very light shadow (5% opacity)
  static const Color shadowColorLight = Color(
    0x05000000,
  ); // Lighter shadow (2% opacity)

  // Overlay
  static const Color overlay = Color(0x80000000);

  // Top Glow (subtle warm/orange tint)
  static const Color topGlowStart = Color(
    0x4DFFF7ED,
  ); // Orange-50 @ 30% opacity
  static const Color topGlowEnd = Color(0xFFFFFFFF); // Pure white
}
