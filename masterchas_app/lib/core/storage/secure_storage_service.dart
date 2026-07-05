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
}
