import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const authTokenKey = 'auth_token';
  static const refreshTokenKey = 'refresh_token';
  static const userRoleKey = 'user_role';
  static const userPhoneKey = 'user_phone';
  static const userDisplayNameKey = 'user_display_name';
  static const masterProfileKey = 'master_profile';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: authTokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: authTokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: authTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: refreshTokenKey, value: token);

  Future<void> deleteRefreshToken() => _storage.delete(key: refreshTokenKey);

  Future<String?> readRole() => _storage.read(key: userRoleKey);

  Future<void> writeRole(String role) =>
      _storage.write(key: userRoleKey, value: role);

  Future<void> deleteRole() => _storage.delete(key: userRoleKey);

  Future<String?> readPhone() => _storage.read(key: userPhoneKey);

  Future<void> writePhone(String phone) =>
      _storage.write(key: userPhoneKey, value: phone);

  Future<void> deletePhone() => _storage.delete(key: userPhoneKey);

  Future<String?> readDisplayName() => _storage.read(key: userDisplayNameKey);

  Future<void> writeDisplayName(String name) =>
      _storage.write(key: userDisplayNameKey, value: name);

  Future<void> deleteDisplayName() =>
      _storage.delete(key: userDisplayNameKey);

  Future<String?> readMasterProfileJson() =>
      _storage.read(key: masterProfileKey);

  Future<void> writeMasterProfileJson(String json) =>
      _storage.write(key: masterProfileKey, value: json);

  Future<void> deleteMasterProfile() =>
      _storage.delete(key: masterProfileKey);
}
