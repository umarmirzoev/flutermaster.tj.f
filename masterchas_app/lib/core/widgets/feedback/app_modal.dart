import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppModal {
  AppModal._();

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final textColor = isDark ? AppColorsDark.secondary : AppColors.secondary;

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: AppTypography.subtitle(textColor),
                ),
                const SizedBox(height: AppSpacing.md),
                content,
                if (confirmLabel != null || cancelLabel != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (cancelLabel != null)
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(cancelLabel),
                        ),
                      if (confirmLabel != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        FilledButton(
                          onPressed: () {
                            onConfirm?.call();
                            Navigator.of(context).pop();
                          },
                          child: Text(confirmLabel),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
