// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';

/// Circular gradient FAB with app theme gradient and plus icon. No shadow.
/// Reusable for Explore and MyProjects "Create Project" action.
class GradientFab extends StatelessWidget {
  const GradientFab({
    super.key,
    required this.onPressed,
    this.size = 58,
    this.icon = Icons.add,
    this.iconSize = 30,
  });

  final VoidCallback? onPressed;
  final double size;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.primaryButtonGradient,
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
