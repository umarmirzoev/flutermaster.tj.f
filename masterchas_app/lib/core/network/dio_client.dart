import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/api_token.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';

class DioClient {
  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(_JwtInterceptor());
    dio.interceptors.add(LogInterceptor(responseBody: true));
    return dio;
  }
}

class _JwtInterceptor extends Interceptor {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isAuthRoute = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh');

    if (!isAuthRoute) {
      final token = await _storage.read(key: SecureStorageService.authTokenKey);
      if (isValidApiJwt(token)) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 — токен устарел, чистим и отправляем на логин
    if (err.response?.statusCode == 401) {
      _storage.delete(key: SecureStorageService.authTokenKey);
      _storage.delete(key: SecureStorageService.refreshTokenKey);
      // TODO: редирект на /login через GoRouter
    }
    handler.next(err);
  }
}
