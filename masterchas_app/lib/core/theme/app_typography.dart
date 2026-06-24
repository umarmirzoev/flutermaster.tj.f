import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle h1(Color color) =>
      _base(fontSize: 48, fontWeight: FontWeight.w700, color: color);

  static TextStyle h2(Color color) =>
      _base(fontSize: 36, fontWeight: FontWeight.w700, color: color);

  static TextStyle h3(Color color) =>
      _base(fontSize: 30, fontWeight: FontWeight.w700, color: color);

  static TextStyle h4(Color color) =>
      _base(fontSize: 24, fontWeight: FontWeight.w700, color: color);

  static TextStyle subtitle(Color color) =>
      _base(fontSize: 20, fontWeight: FontWeight.w600, color: color);

  static TextStyle bodyLarge(Color color) =>
      _base(fontSize: 18, fontWeight: FontWeight.w600, color: color);

  static TextStyle body(Color color) =>
      _base(fontSize: 16, fontWeight: FontWeight.w400, color: color);

  static TextStyle bodyMedium(Color color) =>
      _base(fontSize: 16, fontWeight: FontWeight.w500, color: color);

  static TextStyle bodySemibold(Color color) =>
      _base(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextStyle small(Color color) =>
      _base(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  static TextStyle smallMedium(Color color) =>
      _base(fontSize: 14, fontWeight: FontWeight.w500, color: color);

  static TextStyle smallSemibold(Color color) =>
      _base(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  static TextStyle caption(Color color) =>
      _base(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  static TextStyle button(Color color) =>
      _base(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  static TextTheme textTheme({required bool isDark}) {
    final primaryText = isDark ? AppColorsDark.secondary : AppColors.secondary;
    final secondaryText =
        isDark ? AppColorsDark.textSecondary : AppColors.textSecondary;

    return TextTheme(
      displayLarge: h1(primaryText),
      displayMedium: h2(primaryText),
      displaySmall: h3(primaryText),
      headlineMedium: h4(primaryText),
      titleLarge: subtitle(primaryText),
      titleMedium: bodyLarge(primaryText),
      bodyLarge: body(primaryText),
      bodyMedium: bodyMedium(primaryText),
      bodySmall: small(primaryText),
      labelLarge: button(primaryText),
      labelMedium: smallMedium(primaryText),
      labelSmall: caption(secondaryText),
    );
  }
}
