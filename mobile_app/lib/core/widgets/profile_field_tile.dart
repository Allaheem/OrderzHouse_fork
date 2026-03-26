// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable profile field tile widget matching the reference design
class ProfileFieldTile extends StatefulWidget {
  final String label;
  final String? value;
  final TextEditingController? controller;
  final IconData icon;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? errorText;

  const ProfileFieldTile({
    super.key,
    required this.label,
    this.value,
    this.controller,
    required this.icon,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.errorText,
  });

  @override
  State<ProfileFieldTile> createState() => _ProfileFieldTileState();
}

class _ProfileFieldTileState extends State<ProfileFieldTile> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.controller?.text.isNotEmpty == true
        ? widget.controller!.text
        : (widget.value ?? '');

    return IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.errorText != null
                ? AppColors.error.withOpacity(0.3)
                : (_isFocused ? AppColors.accentOrange : AppColors.border),
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColorLight,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Label
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Value/Input
                  if (widget.readOnly || widget.controller == null)
                    Text(
                      displayValue.isEmpty ? '—' : displayValue,
                      style: TextStyle(
                        color: displayValue.isEmpty
                            ? AppColors.textTertiary
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    )
                  else
                    TextFormField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      readOnly: widget.readOnly,
                      keyboardType: widget.keyboardType,
                      validator: widget.validator,
                      onChanged: widget.onChanged,
                      cursorColor: AppColors.accentOrange,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 0,
                          vertical: 0,
                        ),
                        isDense: true,
                        hintText: '',
                      ),
                    ),
                  // Error text
                  if (widget.errorText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.errorText!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Icon (no background, larger size, grey color)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(widget.icon, color: AppColors.iconGray, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
