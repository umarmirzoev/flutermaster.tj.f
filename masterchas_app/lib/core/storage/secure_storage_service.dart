import 'dart:convert';

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
  static const orderWorkflowKey = 'order_workflow';
  static const masterFavoritesKey = 'master_favorites';
  static const masterReviewsKey = 'master_reviews';
  static const clientPasswordsKey = 'client_passwords';
  static const shopFavoritesKey = 'shop_favorites';
  static const rentalFavoritesKey = 'rental_favorites';
  static const shopAdminOrdersKey = 'shop_admin_orders';
  static const shopOrdersKey = 'shop_client_orders';
  static const shopAddressesKey = 'shop_addresses';

  final FlutterSecureStorage _storage;

  // Настройки устройства (тема, язык) и имена по номеру — не удаляются при выходе из аккаунта.
  static const themeModeKey = 'app_theme_mode';
  static const localeKey = 'app_locale';
  static const namesByPhoneKey = 'display_names_by_phone';

  Future<String?> readSetting(String key) => _storage.read(key: key);

  Future<void> writeSetting(String key, String value) => _storage.write(key: key, value: value);

  Future<Map<String, String>> readNamesByPhone() async {
    try {
      final raw = await _storage.read(key: namesByPhoneKey);
      if (raw == null || raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> writeNameForPhone(String phone, String name) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty || name.trim().isEmpty) return;
    final map = await readNamesByPhone();
    map[digits] = name.trim();
    await _storage.write(key: namesByPhoneKey, value: jsonEncode(map));
  }

  Future<String?> readNameForPhone(String? phone) async {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return (await readNamesByPhone())[digits];
  }

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

  Future<String?> readOrderWorkflowJson() =>
      _storage.read(key: orderWorkflowKey);

  Future<void> writeOrderWorkflowJson(String json) =>
      _storage.write(key: orderWorkflowKey, value: json);

  Future<void> deleteOrderWorkflow() =>
      _storage.delete(key: orderWorkflowKey);

  Future<String?> readMasterFavoritesJson() =>
      _storage.read(key: masterFavoritesKey);

  Future<void> writeMasterFavoritesJson(String json) =>
      _storage.write(key: masterFavoritesKey, value: json);

  Future<String?> readMasterReviewsJson() =>
      _storage.read(key: masterReviewsKey);

  Future<void> writeMasterReviewsJson(String json) =>
      _storage.write(key: masterReviewsKey, value: json);

  Future<String?> readClientPasswordsJson() =>
      _storage.read(key: clientPasswordsKey);

  Future<void> writeClientPasswordsJson(String json) =>
      _storage.write(key: clientPasswordsKey, value: json);

  Future<String?> readShopFavoritesJson() =>
      _storage.read(key: shopFavoritesKey);

  Future<void> writeShopFavoritesJson(String json) =>
      _storage.write(key: shopFavoritesKey, value: json);

  Future<String?> readRentalFavoritesJson() =>
      _storage.read(key: rentalFavoritesKey);

  Future<void> writeRentalFavoritesJson(String json) =>
      _storage.write(key: rentalFavoritesKey, value: json);

  Future<String?> readShopAdminOrdersJson() =>
      _storage.read(key: shopAdminOrdersKey);

  Future<void> writeShopAdminOrdersJson(String json) =>
      _storage.write(key: shopAdminOrdersKey, value: json);

  Future<String?> readShopOrdersJson() => _storage.read(key: shopOrdersKey);

  Future<void> writeShopOrdersJson(String json) =>
      _storage.write(key: shopOrdersKey, value: json);

  Future<String?> readShopAddressesJson() =>
      _storage.read(key: shopAddressesKey);

  Future<void> writeShopAddressesJson(String json) =>
      _storage.write(key: shopAddressesKey, value: json);
}
