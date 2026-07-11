import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(isDark: false);

  static ThemeData get dark => _buildTheme(isDark: true);

  static ThemeData _buildTheme({required bool isDark}) {
    final colors = isDark ? _DarkPalette() : _LightPalette();
    final textTheme = AppTypography.textTheme(isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.secondary,
        onSecondary: colors.background,
        error: colors.danger,
        onError: Colors.white,
        surface: colors.surface,
        onSurface: colors.secondary,
      ),
      textTheme: textTheme,
      dividerColor: colors.border,
      disabledColor: colors.disabled,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: colors.disabled,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.button(Colors.white),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.disabled,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: AppTypography.button(colors.primary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          disabledForegroundColor: colors.disabled,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.button(colors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        hintStyle: AppTypography.body(colors.textSecondary),
        labelStyle: AppTypography.small(colors.textSecondary),
        errorStyle: AppTypography.caption(colors.danger),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: colors.disabled),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.secondary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.subtitle(colors.secondary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surface,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTypography.caption(colors.primary),
        unselectedLabelStyle: AppTypography.caption(colors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

abstract class _AppPalette {
  Color get primary;
  Color get secondary;
  Color get success;
  Color get warning;
  Color get danger;
  Color get background;
  Color get surface;
  Color get textSecondary;
  Color get border;
  Color get disabled;
}

class _LightPalette implements _AppPalette {
  @override
  Color get primary => AppColors.primary;

  @override
  Color get secondary => AppColors.secondary;

  @override
  Color get success => AppColors.success;

  @override
  Color get warning => AppColors.warning;

  @override
  Color get danger => AppColors.danger;

  @override
  Color get background => AppColors.background;

  @override
  Color get surface => AppColors.surface;

  @override
  Color get textSecondary => AppColors.textSecondary;

  @override
  Color get border => AppColors.border;

  @override
  Color get disabled => AppColors.disabled;
}

class _DarkPalette implements _AppPalette {
  @override
  Color get primary => AppColorsDark.primary;

  @override
  Color get secondary => AppColorsDark.secondary;

  @override
  Color get success => AppColorsDark.success;

  @override
  Color get warning => AppColorsDark.warning;

  @override
  Color get danger => AppColorsDark.danger;

  @override
  Color get background => AppColorsDark.background;

  @override
  Color get surface => AppColorsDark.surface;

  @override
  Color get textSecondary => AppColorsDark.textSecondary;

  @override
  Color get border => AppColorsDark.border;

  @override
  Color get disabled => AppColorsDark.disabled;
}
