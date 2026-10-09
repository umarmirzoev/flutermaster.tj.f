import 'dart:convert';

/// Достаёт id пользователя (claim NameIdentifier) из JWT access-токена сервера.
String? userIdFromJwt(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return null;
    for (final key in const [
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'nameid',
      'sub',
      'userId',
    ]) {
      final value = payload[key];
      if (value is String && value.isNotEmpty) return value.toLowerCase();
    }
  } catch (_) {}
  return null;
}
