import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 24,
    this.strokeWidth = 3,
    this.color,
  }) : fullScreen = false;

  const AppLoader.fullScreen({
    super.key,
    this.color,
  })  : size = 40,
        strokeWidth = 3,
        fullScreen = true;

  final double size;
  final double strokeWidth;
  final Color? color;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? AppColors.primary;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: loaderColor,
      ),
    );

    if (!fullScreen) return indicator;

    return ColoredBox(
      color: Colors.black26,
      child: Center(child: indicator),
    );
  }
}
