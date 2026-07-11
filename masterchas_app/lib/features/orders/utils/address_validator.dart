/// Client-side address validation (mirrors server rules, slightly stricter).
class AddressValidator {
  static const invalidMessage =
      'Укажите реальный адрес: улица и номер дома, например: ул. Рудаки 45, Душанбе';

  static bool isValid(String address) {
    final trimmed = address.trim();
    if (trimmed.length < 10) return false;

    final hasLetters = RegExp(
      r'[а-яёa-zA-ZҒғӢӣҚқӮӯҲҳҶҷ]{3,}',
      caseSensitive: false,
    ).hasMatch(trimmed);
    if (!hasLetters) return false;

    final hasHouseNumber = RegExp(r'\d').hasMatch(trimmed);
    if (!hasHouseNumber) return false;

    final looksLikeStreet = RegExp(
      r'ул\.?|куча|пр\.?|просп|мкр|махалла|мах\.?|street|st\.?|душанбе|худжанд|бохтар|куляб',
      caseSensitive: false,
    ).hasMatch(trimmed);
    final hasCommaAddress = trimmed.contains(',') && trimmed.length >= 12;
    if (!looksLikeStreet && !hasCommaAddress) return false;

    // Random keyboard mash without spaces (latin or cyrillic).
    if (!trimmed.contains(' ') &&
        !looksLikeStreet &&
        RegExp(r'^[a-zA-Zа-яё0-9]{6,}$', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }

    // Too many consonants in a row — likely gibberish.
    if (RegExp(r'[бвгджзклмнпрстфхцчшщ]{6,}', caseSensitive: false).hasMatch(trimmed)) {
      return false;
    }

    return true;
  }
}
