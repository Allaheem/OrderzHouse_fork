// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable top glow background widget
/// Provides a very subtle gradient at the top (Explore style) and white below
/// Use this to wrap page bodies for consistent background styling
class TopGlowBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;

  const TopGlowBackground({
    super.key,
    required this.child,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background gradient layer (subtle top glow - very light pinkish tint)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.topGlowStart, // Very subtle pinkish tint
                  AppColors.topGlowEnd, // Pure white at bottom
                ],
                stops: [0.0, 0.15], // Fades to white within ~15% of height
              ),
            ),
          ),
        ),
        // Content layer
        if (useSafeArea) SafeArea(child: child) else child,
      ],
    );
  }
}
