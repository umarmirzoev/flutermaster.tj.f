/// Formats 9 local digits as `+992 90 123 45 67`.
String formatTjPhone(String rawDigits) {
  final digits = rawDigits.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '+992';

  final local = digits.length > 9 ? digits.substring(digits.length - 9) : digits;
  if (local.length < 9) {
    return '+992 $local';
  }

  return '+992 ${local.substring(0, 2)} '
      '${local.substring(2, 5)} '
      '${local.substring(5, 7)} '
      '${local.substring(7, 9)}';
}

/// Extracts up to 9 local digits from a stored/display phone value.
String localDigitsFromPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '';

  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('992')) {
    digits = digits.substring(3);
  }
  if (digits.length > 9) {
    digits = digits.substring(digits.length - 9);
  }
  return digits;
}
