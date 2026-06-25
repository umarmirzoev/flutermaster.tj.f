import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(label: 'Главная', icon: LucideIcons.house),
    _NavItem(label: 'Услуги', icon: LucideIcons.wrench),
    _NavItem(label: 'Мастера', icon: LucideIcons.users),
    _NavItem(label: 'Магазин', icon: LucideIcons.shopping_bag),
    _NavItem(label: 'Профиль', icon: LucideIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final selectedColor = isDark ? AppColorsDark.primary : AppColors.primary;
    final unselectedColor =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = index == currentIndex;
              final color = isSelected ? selectedColor : unselectedColor;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.icon, size: 22, color: color),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          item.label,
                          style: AppTypography.caption(color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
