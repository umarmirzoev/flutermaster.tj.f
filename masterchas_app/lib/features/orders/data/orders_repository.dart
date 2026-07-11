import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../models/api_order.dart';

class ResolvedService {
  const ResolvedService({required this.id, required this.title});

  final String id;
  final String title;
}

class OrdersRepository {
  OrdersRepository(this._dio);

  final Dio _dio;

  List<Map<String, dynamic>>? _servicesCache;

  Map<String, dynamic>? _unwrapData(dynamic body) {
    if (body is! Map<String, dynamic>) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return body;
  }

  List<dynamic>? _unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
    }
    return null;
  }

  Future<ApiResult<List<ApiOrder>>> getMyOrders() async {
    try {
      final response = await _dio.get('/orders/my');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiError('Неверный ответ сервера');
      return ApiSuccess(
        list
            .map((e) => ApiOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiError(
        e.response?.data is Map
            ? (e.response?.data['message'] as String? ?? 'Ошибка загрузки заказов')
            : 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<ApiOrder>>> getAssignedOrders() async {
    try {
      final response = await _dio.get('/orders/assigned');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiError('Неверный ответ сервера');
      return ApiSuccess(
        list
            .map((e) => ApiOrder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiError(
        e.response?.data is Map
            ? (e.response?.data['message'] as String? ?? 'Ошибка загрузки заказов')
            : 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }

  String _formatBody(dynamic body) {
    if (body == null) return '(null)';
    if (body is String) return body;
    try {
      return const JsonEncoder.withIndent('  ').convert(body);
    } catch (_) {
      return body.toString();
    }
  }

  String _dioErrorMessage(DioException e) {
    final responseData = e.response?.data;
    if (responseData != null) {
      return _formatBody(responseData);
    }
    return '${e.type.name}: ${e.message ?? 'no message'}';
  }

  void _logCreateOrderFailure({
    required String url,
    required dynamic requestBody,
    required DioException error,
    required StackTrace stackTrace,
  }) {
    debugPrint('CREATE ORDER URL: $url');
    debugPrint('CREATE ORDER REQUEST: ${_formatBody(requestBody)}');
    debugPrint('CREATE ORDER STATUS: ${error.response?.statusCode}');
    debugPrint('CREATE ORDER RESPONSE: ${_formatBody(error.response?.data)}');
    debugPrint('CREATE ORDER STACK: $stackTrace');
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is! Map) return fallback;

    final errors = body['errors'];
    if (errors is Map) {
      final messages = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List) {
          messages.addAll(value.map((m) => m.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    return body['message'] as String? ?? fallback;
  }

  Future<ApiResult<ApiOrder>> createOrder({
    required String serviceId,
    required String title,
    required String description,
    required double price,
    required String address,
    String? masterPhone,
    DateTime? scheduledDate,
    String? scheduledTime,
  }) async {
    final payload = <String, dynamic>{
      'serviceId': serviceId,
      'title': title,
      'description': description,
      'price': price,
      'address': address,
      if (masterPhone != null && masterPhone.trim().isNotEmpty)
        'masterPhone': _normalizePhone(masterPhone),
      if (scheduledDate != null)
        'scheduledDate': scheduledDate.toIso8601String().split('T').first,
      if (scheduledTime != null) 'scheduledTime': scheduledTime,
    };

    final url = '${_dio.options.baseUrl}/orders';
    debugPrint('CREATE ORDER URL: $url');
    debugPrint('CREATE ORDER REQUEST: ${_formatBody(payload)}');

    try {
      final response = await _dio.post('/orders', data: payload);
      debugPrint('CREATE ORDER STATUS: ${response.statusCode}');
      debugPrint('CREATE ORDER RESPONSE: ${_formatBody(response.data)}');

      final data = _unwrapData(response.data);
      if (data == null) {
        return ApiError(
          _formatBody(response.data),
          statusCode: response.statusCode,
        );
      }
      return ApiSuccess(ApiOrder.fromJson(data));
    } on DioException catch (e, st) {
      _logCreateOrderFailure(
        url: e.requestOptions.uri.toString(),
        requestBody: e.requestOptions.data ?? payload,
        error: e,
        stackTrace: st,
      );
      return ApiError(
        _dioErrorMessage(e),
        statusCode: e.response?.statusCode,
      );
    } catch (e, st) {
      debugPrint('CREATE ORDER URL: $url');
      debugPrint('CREATE ORDER REQUEST: ${_formatBody(payload)}');
      debugPrint('CREATE ORDER ERROR: $e');
      debugPrint('CREATE ORDER STACK: $st');
      return ApiError(e.toString());
    }
  }

  Future<String?> resolveServiceIdByName(String title) async {
    final resolved = await resolveServiceByTitle(title);
    return resolved?.id;
  }

  Future<ResolvedService?> resolveServiceByTitle(String title) async {
    _servicesCache ??= await _loadServices();
    if (_servicesCache!.isEmpty) return null;

    final normalized = _normalizeTitle(title);
    if (normalized.isEmpty) return _fallbackService();

    final direct = _findByApiName(normalized, title);
    if (direct != null) return direct;

    // Category key from local catalog → representative API service.
    for (final cat in _categoryServiceNames.keys) {
      if (normalized.contains(_normalizeTitle(cat)) ||
          _normalizeTitle(cat).contains(normalized)) {
        final hit = _findByApiName(_normalizeTitle(_categoryServiceNames[cat]!), _categoryServiceNames[cat]!);
        if (hit != null) return hit;
      }
    }

    // Master profession labels (Сантехник → Сантехника services).
    for (final entry in _professionToService.entries) {
      if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
        final hit = _findByApiName(_normalizeTitle(entry.value), entry.value);
        if (hit != null) return hit;
      }
    }

    return _fallbackService();
  }

  ResolvedService? _findByApiName(String normalized, String fallbackTitle) {
    for (final item in _servicesCache!) {
      final name = _normalizeTitle(item['name'] as String? ?? '');
      if (name == normalized || name.contains(normalized) || normalized.contains(name)) {
        return ResolvedService(
          id: item['id']?.toString() ?? '',
          title: item['name'] as String? ?? fallbackTitle,
        );
      }
    }
    return null;
  }

  String _normalizeTitle(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  ResolvedService? _fallbackService() {
    const fallbacks = [
      'Аварийный выезд мастера',
      'Другие услуги',
    ];
    for (final name in fallbacks) {
      final normalized = _normalizeTitle(name);
      for (final item in _servicesCache!) {
        final apiName = _normalizeTitle(item['name'] as String? ?? '');
        if (apiName == normalized || apiName.contains(normalized)) {
          return ResolvedService(
            id: item['id']?.toString() ?? '',
            title: item['name'] as String? ?? name,
          );
        }
      }
    }
    final first = _servicesCache!.first;
    return ResolvedService(
      id: first['id']?.toString() ?? '',
      title: first['name'] as String? ?? 'Услуга',
    );
  }

  static const _categoryServiceNames = <String, String>{
    'Электрика': 'Диагностика электрики',
    'Сантехника': 'Замена смесителя',
    'Отделка': 'Шпаклевка стен',
    'Отопление': 'Установка бойлера',
    'Кондиционеры': 'Установка кондиционера',
    'Уборка': 'Генеральная уборка',
    'Мебель и двери': 'Вскрытие замков',
    'Видеонаблюдение': 'Установка камеры',
    'Умный дом': 'Установка розетки',
    'Сварочные работы': 'Аварийный выезд мастера',
    'Другие услуги': 'Аварийный выезд мастера',
    'Аварийные 24/7': 'Аварийный выезд мастера',
    'Плитка': 'Укладка плитки',
    'Малярные работы': 'Покраска стен',
  };

  static const _professionToService = <String, String>{
    'сантехник': 'Замена смесителя',
    'электрик': 'Диагностика электрики',
    'плиточник': 'Укладка плитки',
    'отделочник': 'Шпаклевка стен',
    'сварщик': 'Аварийный выезд мастера',
  };

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 9) return '+992$digits';
    if (digits.startsWith('992') && digits.length >= 12) {
      return '+${digits.substring(0, 12)}';
    }
    final compact = raw.trim().replaceAll(' ', '');
    return compact.startsWith('+') ? compact : '+$digits';
  }

  Future<List<Map<String, dynamic>>> _loadServices() async {
    try {
      final response = await _dio.get('/services');
      final list = _unwrapList(response.data);
      if (list == null) return [];
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(dioProvider)),
);
