// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_colors.dart';

/// Reusable filter chip row widget
class FilterChipRow extends StatelessWidget {
  final List<String> options;
  final String selectedValue;
  final ValueChanged<String> onSelected;
  final String label;

  const FilterChipRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Text(
            '$label:',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          ...options.map((option) {
            final isSelected =
                option.toLowerCase() == selectedValue.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  option == 'all' ? 'All' : option.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.chipActiveText
                        : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onSelected(option);
                },
                selectedColor: AppColors.chipActiveBg,
                backgroundColor: AppColors.chipBg,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.chipActiveBg
                      : AppColors.chipBorder,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
