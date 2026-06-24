import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppBadgeVariant { success, warning, danger, info }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.info,
  });

  final String label;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.caption(colors.foreground),
      ),
    );
  }

  _BadgeColors _resolveColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return switch (variant) {
      AppBadgeVariant.success => _BadgeColors(
          background: AppColors.success.withValues(alpha: 0.12),
          foreground: AppColors.success,
        ),
      AppBadgeVariant.warning => _BadgeColors(
          background: AppColors.warning.withValues(alpha: 0.12),
          foreground: AppColors.warning,
        ),
      AppBadgeVariant.danger => _BadgeColors(
          background: AppColors.danger.withValues(alpha: 0.12),
          foreground: AppColors.danger,
        ),
      AppBadgeVariant.info => _BadgeColors(
          background: (isDark ? AppColorsDark.primary : AppColors.primary)
              .withValues(alpha: 0.12),
          foreground: isDark ? AppColorsDark.primary : AppColors.primary,
        ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
