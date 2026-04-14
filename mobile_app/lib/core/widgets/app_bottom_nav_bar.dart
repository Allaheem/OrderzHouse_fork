// ??? ????????
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../ui/screenutil_helpers.dart';

/// Navigation item for bottom navigation bar
class NavItem {
  final String title;
  final IconData icon;
  final String route;

  const NavItem({required this.title, required this.icon, required this.route});
}

/// Bottom navigation bar: white background, outline icons, label under each icon.
/// Active item orange (#FB923C), inactive grey. No shadow, subtle top border.
/// SafeArea for bottom. Same tabs/routes and navigation logic.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final ValueChanged<int>? onTap;

  static const Color activeColor = AppColors.gradientStart; // #FB923C
  static Color get inactiveColor => Colors.grey.shade400;
  static const Color barBackground = Colors.white;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final baseHeight = AppContentLayout.bottomNavBarHeight(context);
    final totalHeight = baseHeight + bottomPadding;

    return Container(
      width: double.infinity,
      height: totalHeight,
      decoration: BoxDecoration(
        color: barBackground,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Container(
            height: baseHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = index == currentIndex;

                return Expanded(
                  child: _NavItemWidget(
                    item: item,
                    isSelected: isSelected,
                    onTap: () {
                      if (index == currentIndex) return;
                      if (onTap != null) {
                        onTap!(index);
                      } else {
                        final route = item.route;
                        if (route.isNotEmpty) {
                          context.go(route);
                        }
                      }
                    },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppBottomNavBar.activeColor
        : AppBottomNavBar.inactiveColor;
    final iconSize = AppContentLayout.bottomNavIconSize(context);
    final labelSize = AppContentLayout.bottomNavLabelFontSize(context);

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: color,
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              item.title,
              style: TextStyle(
                color: color,
                fontSize: labelSize,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                letterSpacing: 0.05,
                height: 1.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
