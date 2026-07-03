/// Client-side address validation (mirrors server rules, slightly stricter).
class AddressValidator {
  static const invalidMessage =
      'Укажите реальный адрес: улица и номер дома, например: ул. Рудаки 45, Душанбе';

  static bool isValid(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 8) return false;

    final hasLetters = RegExp(
      r'[а-яёa-zA-ZҒғӢӣҚқӮӯҲҳҶҷ]{3,}',
      caseSensitive: false,
    ).hasMatch(trimmed);
    if (!hasLetters) return false;

    final hasHouseNumber = RegExp(r'\d').hasMatch(trimmed);
    if (!hasHouseNumber) return false;

    // Random latin garbage like "asdfgh" without spaces.
    if (RegExp(r'^[a-zA-Z0-9]{5,}$').hasMatch(trimmed.replaceAll(' ', '')) &&
        !trimmed.contains(',') &&
        !RegExp(r'ул|куча|пр|мкр|мах|street|st\.?', caseSensitive: false)
            .hasMatch(trimmed)) {
      return false;
    }

    return true;
  }
}
