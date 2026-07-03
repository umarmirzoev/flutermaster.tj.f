import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_result.dart';
import '../data/chat_repository.dart';
import '../models/api_conversation.dart';

final conversationsProvider = FutureProvider<List<ApiConversation>>((ref) async {
  final result = await ref.read(chatRepositoryProvider).getConversations();
  if (result is ApiSuccess<List<ApiConversation>>) return result.data;
  return [];
});

final chatMessagesProvider =
    FutureProvider.family<List<ApiMessage>, String>((ref, conversationId) async {
  final result = await ref.read(chatRepositoryProvider).getMessages(conversationId);
  if (result is ApiSuccess<List<ApiMessage>>) return result.data;
  return [];
});
