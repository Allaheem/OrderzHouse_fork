// ??? ????????
import 'package:flutter/material.dart';
import 'gradient_button.dart';

/// Primary button - now uses gradient instead of solid color
/// Wrapper around PrimaryGradientButton for backward compatibility
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PrimaryGradientButton(
      onPressed: onPressed,
      label: label,
      isLoading: isLoading,
      isEnabled: isEnabled,
      icon: icon,
    );
  }
}
