import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../models/api_conversation.dart';

class ChatRepository {
  ChatRepository(this._dio);

  final Dio _dio;

  List<dynamic>? _unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
    }
    return null;
  }

  Future<ApiResult<List<ApiConversation>>> getConversations() async {
    try {
      final response = await _dio.get('/chat/conversations');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiError('Неверный ответ сервера');
      return ApiSuccess(
        list
            .map((e) => ApiConversation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiError(
        e.response?.data is Map
            ? (e.response?.data['message'] as String? ?? 'Ошибка загрузки чатов')
            : 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<ApiMessage>>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get('/chat/conversations/$conversationId/messages');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiError('Неверный ответ сервера');
      return ApiSuccess(
        list
            .map((e) => ApiMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      return ApiError(
        e.response?.data is Map
            ? (e.response?.data['message'] as String? ?? 'Ошибка загрузки сообщений')
            : 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);
