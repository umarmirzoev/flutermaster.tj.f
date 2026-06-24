import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppToastVariant { success, warning, error, info }

class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    AppToastVariant variant = AppToastVariant.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = _resolveColors(variant);
    final icon = _resolveIcon(variant);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: colors.background,
          content: Row(
            children: [
              Icon(icon, color: colors.foreground, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.smallMedium(colors.foreground),
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static _ToastColors _resolveColors(AppToastVariant variant) {
    return switch (variant) {
      AppToastVariant.success => const _ToastColors(
          background: AppColors.success,
          foreground: Colors.white,
        ),
      AppToastVariant.warning => const _ToastColors(
          background: AppColors.warning,
          foreground: Colors.white,
        ),
      AppToastVariant.error => const _ToastColors(
          background: AppColors.danger,
          foreground: Colors.white,
        ),
      AppToastVariant.info => const _ToastColors(
          background: AppColors.primary,
          foreground: Colors.white,
        ),
    };
  }

  static IconData _resolveIcon(AppToastVariant variant) {
    return switch (variant) {
      AppToastVariant.success => Icons.check_circle_outline,
      AppToastVariant.warning => Icons.warning_amber_outlined,
      AppToastVariant.error => Icons.error_outline,
      AppToastVariant.info => Icons.info_outline,
    };
  }
}

class _ToastColors {
  const _ToastColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
