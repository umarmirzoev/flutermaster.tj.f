import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/storage/secure_storage_provider.dart';
import '../models/auth_session.dart';
import '../utils/phone_formatter.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final dynamic _storage;

  Map<String, dynamic>? _unwrapData(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }

  String _errorMessage(DioException e, String fallback) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает. Проверьте интернет и попробуйте снова.';
      case DioExceptionType.connectionError:
        return 'Нет связи с сервером (${AppConfig.baseUrl}). Проверьте интернет.';
      default:
        break;
    }
    return e.response?.data is Map
        ? (e.response?.data['message'] as String? ?? fallback)
        : fallback;
  }

  Future<ApiResult<AuthSession>> login(String phone, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'phone': _normalizePhone(phone),
        'password': password,
      });
      final data = _unwrapData(response.data);
      if (data == null) {
        return const ApiError('Неверный ответ сервера');
      }
      final session = AuthSession.fromJson(data);
      await _persistSession(session);
      return ApiSuccess(session);
    } on DioException catch (e) {
      return ApiError(
        _errorMessage(e, 'Неверный логин или пароль'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<AuthSession>> register({
    required String phone,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    debugPrint('REGISTER API: phone=$normalizedPhone role=$role url=${AppConfig.baseUrl}/auth/register');
    try {
      final response = await _dio.post('/auth/register', data: {
        'phone': normalizedPhone,
        'password': password,
        'role': role,
        if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
        if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
      });
      debugPrint('REGISTER API: status=${response.statusCode}');
      final data = _unwrapData(response.data);
      if (data == null) {
        return const ApiError('Неверный ответ сервера');
      }
      final session = AuthSession.fromJson(data);
      await _persistSession(session);
      return ApiSuccess(session);
    } on DioException catch (e) {
      debugPrint('REGISTER API: DioException type=${e.type} status=${e.response?.statusCode} message=${e.message}');
      return ApiError(
        _errorMessage(e, 'Не удалось зарегистрироваться'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<AuthSession>> refresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return const ApiError('Сессия истекла');
    }

    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      final data = _unwrapData(response.data);
      if (data == null) {
        return const ApiError('Неверный ответ сервера');
      }
      final session = AuthSession.fromJson(data);
      await _persistSession(session);
      return ApiSuccess(session);
    } on DioException catch (e) {
      await _storage.deleteToken();
      await _storage.deleteRefreshToken();
      return ApiError(
        _errorMessage(e, 'Сессия истекла'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.deleteRefreshToken();
    await _storage.deleteRole();
    await _storage.deletePhone();
    await _storage.deleteDisplayName();
    await _storage.deleteMasterProfile();
  }

  Future<void> _persistSession(AuthSession session) async {
    await _storage.writeToken(session.accessToken);
    await _storage.writeRefreshToken(session.refreshToken);
    await _storage.writeRole(session.role);
    if (session.phoneNumber.isNotEmpty) {
      await _storage.writePhone(session.phoneNumber);
    }
  }

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) {
      return '+992$digits';
    }
    if (digits.startsWith('992') && digits.length >= 12) {
      return '+${digits.substring(0, 12)}';
    }
    final compact = raw.trim().replaceAll(' ', '');
    return compact.startsWith('+') ? compact : '+$digits';
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  ),
);
