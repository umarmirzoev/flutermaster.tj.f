import '../utils/phone_formatter.dart';

/// Локальные учётные данные администратора (совпадают с сидером на сервере).
class AdminCredential {
  const AdminCredential({
    required this.phoneDigits,
    required this.password,
    required this.role,
    required this.displayName,
  });

  final String phoneDigits;
  final String password;
  final String role;
  final String displayName;
}

/// Локальных учётных данных администратора в приложении нет: вход проверяется только на сервере.
const _adminCredentials = <AdminCredential>[];

AdminCredential? lookupAdminCredential({
  required String phone,
  required String password,
}) {
  final digits = localDigitsFromPhone(phone);
  final pass = password.trim();
  if (digits.isEmpty || pass.isEmpty) return null;

  for (final cred in _adminCredentials) {
    if (cred.phoneDigits == digits && cred.password == pass) {
      return cred;
    }
  }
  return null;
}

bool isKnownAdminPhone(String phone) {
  final digits = localDigitsFromPhone(phone);
  return _adminCredentials.any((c) => c.phoneDigits == digits);
}
