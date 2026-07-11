import 'package:flutter/material.dart';

const brandGreen = Color(0xFF57B55E);

class HomePalette {
  const HomePalette({
    required this.pageBg,
    required this.cardBg,
    required this.text,
    required this.muted,
    required this.border,
    required this.shellBg,
    required this.searchBg,
    required this.masterCardBg,
    required this.promoCodeBg,
    required this.promoCodeText,
    required this.headerGradient,
    required this.headerCardBg,
    required this.productImageBg,
    required this.inputFill,
  });

  final Color pageBg;
  final Color cardBg;
  final Color text;
  final Color muted;
  final Color border;
  final Color shellBg;
  final Color searchBg;
  final Color masterCardBg;
  final Color promoCodeBg;
  final Color promoCodeText;
  final List<Color> headerGradient;
  final Color headerCardBg;
  final Color productImageBg;
  final Color inputFill;

  factory HomePalette.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (dark) {
      return const HomePalette(
        pageBg: Color(0xFF000000),
        cardBg: Color(0xFF1A1A1A),
        text: Color(0xFFF5F5F5),
        muted: Color(0xFF9CA3AF),
        border: Color(0xFF2D2D2D),
        shellBg: Color(0xFF111111),
        searchBg: Color(0xFF252525),
        masterCardBg: Color(0xFF252525),
        promoCodeBg: Color(0xFF2A2A2A),
        promoCodeText: brandGreen,
        headerGradient: [
          Color(0xFF0F2418),
          Color(0xFF163322),
          Color(0xFF1A3D28),
        ],
        headerCardBg: Color(0xFF1A1A1A),
        productImageBg: Color(0xFF252525),
        inputFill: Color(0xFF252525),
      );
    }
    return const HomePalette(
      pageBg: Color(0xFFF5F6F8),
      cardBg: Colors.white,
      text: Color(0xFF1C1C1C),
      muted: Color(0xFF8B95A5),
      border: Color(0xFFE8ECF0),
      shellBg: Color(0xFFDDE2E8),
      searchBg: Colors.white,
      masterCardBg: Color(0xFFE9F0E5),
      promoCodeBg: Colors.white,
      promoCodeText: brandGreen,
      headerGradient: [
        Color(0xFF3B8F42),
        Color(0xFF57B55E),
        Color(0xFF6DD674),
      ],
      headerCardBg: Colors.white,
      productImageBg: Colors.white,
      inputFill: Color(0xFFF3F4F8),
    );
  }
}
