import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../feedback/app_loader.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.isLoading = false,
    this.isDisabled = false,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final bool expand;
  final Widget? icon;

  bool get _isInteractive => !isLoading && !isDisabled && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(context);
    final padding = _resolvePadding();
    final textStyle = AppTypography.button(colors.foreground);

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: AppLoader(color: colors.foreground, strokeWidth: 2),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: textStyle),
            ],
          );

    final button = Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: _isInteractive ? onPressed : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: expand ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: colors.border,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return Opacity(
      opacity: _isInteractive ? 1 : 0.5,
      child: button,
    );
  }

  EdgeInsets _resolvePadding() {
    return switch (size) {
      AppButtonSize.sm => const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      AppButtonSize.md => const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      AppButtonSize.lg => const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
    };
  }

  _ButtonColors _resolveColors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColorsDark.primary : AppColors.primary;
    final secondaryText =
        isDark ? AppColorsDark.secondary : AppColors.secondary;
    final secondaryBg = AppColors.secondary;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final borderColor = isDark ? AppColorsDark.border : AppColors.border;

    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonColors(
          background: primary,
          foreground: Colors.white,
        );
      case AppButtonVariant.secondary:
        if (isDark) {
          return _ButtonColors(
            background: surface,
            foreground: secondaryText,
            border: Border.all(color: borderColor),
          );
        }
        return _ButtonColors(
          background: secondaryBg,
          foreground: Colors.white,
        );
      case AppButtonVariant.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: primary,
          border: Border.all(color: primary),
        );
      case AppButtonVariant.ghost:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: primary,
        );
      case AppButtonVariant.danger:
        return _ButtonColors(
          background: AppColors.danger,
          foreground: Colors.white,
        );
    }
  }
}

class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    this.border,
  });

  final Color background;
  final Color foreground;
  final BoxBorder? border;
}
