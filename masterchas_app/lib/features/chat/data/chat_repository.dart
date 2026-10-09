import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../models/api_conversation.dart';
import 'chat_payload.dart';

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

  Future<ApiResult<void>> sendMessage({
    required String conversationId,
    required String text,
    int messageType = ChatMessageType.text,
  }) async {
    try {
      await _dio.post(
        '/chat/conversations/$conversationId/messages',
        data: {'text': text, 'messageType': messageType},
      );
      return const ApiSuccess(null);
    } on DioException catch (e) {
      return ApiError(
        e.response?.data is Map
            ? (e.response?.data['message'] as String? ?? 'Не удалось отправить')
            : 'Ошибка сети',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Загружает фото/файл на сервер и возвращает данные вложения.
  /// «Удалить чат» у себя (на сервере чат скрывается только для текущего пользователя).
  Future<bool> hideConversation(String conversationId) async {
    try {
      await _dio.delete<dynamic>('/chat/conversations/$conversationId');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Скачивает вложение (например, голосовое) целиком.
  Future<List<int>> downloadBytes(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    return response.data ?? const <int>[];
  }

  Future<ApiResult<ChatAttachment>> uploadAttachment({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(chatMimeTypeFor(fileName)),
        ),
      });
      final response = await _dio.post(
        '/chat/attachments',
        data: form,
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
        ),
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic>) {
        return const ApiError('Неверный ответ сервера');
      }
      return ApiSuccess(ChatAttachment.fromJson(data));
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      return ApiError(
        status == 413
            ? 'Файл слишком большой'
            : (e.response?.data is Map
                ? (e.response?.data['message'] as String? ?? 'Не удалось загрузить файл')
                : 'Ошибка сети'),
        statusCode: status,
      );
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);
