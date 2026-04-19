// ??? ????????
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../ui/screenutil_helpers.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Premium quick actions row (5 items). Phone: horizontal strip. Tablet: equal columns, larger targets.
class QuickActionsRow extends StatelessWidget {
  final List<QuickAction> actions;

  const QuickActionsRow({super.key, required this.actions});

  static bool _isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  @override
  Widget build(BuildContext context) {
    final hx = AppContentLayout.bodyHorizontalPadding(context);
    if (_isTablet(context)) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hx),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final a in actions)
              Expanded(
                child: _buildTabletItem(context, a),
              ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.sm),
              _buildPhoneItem(context, actions[i]),
            ],
          ],
        ),
      ),
    );
  }

  /// iPad / tablet: large touch targets, readable labels, uses full width.
  Widget _buildTabletItem(BuildContext context, QuickAction action) {
    const double box = 76;
    const double iconSize = 32;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: box,
                  height: box,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColorLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    color: AppColors.accentOrange,
                    size: iconSize,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: AppFont.f13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Phone: scrollable row with compact chips.
  Widget _buildPhoneItem(BuildContext context, QuickAction action) {
    return SizedBox(
      width: AppContentLayout.quickActionItemWidth(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowColorLight,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    action.icon,
                    color: AppColors.accentOrange,
                    size: 26,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  action.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: AppFont.f11,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
