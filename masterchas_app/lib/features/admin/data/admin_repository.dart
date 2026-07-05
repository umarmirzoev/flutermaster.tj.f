import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/platform_models.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/dio_provider.dart';
import '../../masters/data/masters_data.dart';
import '../models/admin_models.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  List<dynamic>? _unwrapList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data;
    }
    return null;
  }

  String _errorMessage(DioException e, String fallback) {
    return e.response?.data is Map
        ? (e.response?.data['message'] as String? ?? fallback)
        : fallback;
  }

  Future<ApiResult<AdminDataState>> fetchDashboardData() async {
    try {
      final usersResult = await _fetchAllUsers();
      if (usersResult is ApiError<List<_AdminUserRow>>) {
        return ApiError(usersResult.message, statusCode: usersResult.statusCode);
      }
      final users = (usersResult as ApiSuccess<List<_AdminUserRow>>).data;
      final nameById = {for (final u in users) u.id.toLowerCase(): u.displayName};

      final ordersResult = await _fetchOrders(nameById);
      if (ordersResult is ApiError<List<AdminOrder>>) {
        return ApiError(ordersResult.message, statusCode: ordersResult.statusCode);
      }
      final orders = (ordersResult as ApiSuccess<List<AdminOrder>>).data;

      final masters = _mapMasters(users, orders);
      final clients = _mapClients(users, orders);

      final chatsResult = await _fetchChats(nameById);
      final chats = chatsResult is ApiSuccess<List<AdminChat>>
          ? chatsResult.data
          : const <AdminChat>[];

      final transactions = _buildTransactions(orders);

      return ApiSuccess(
        AdminDataState(
          orders: orders,
          masters: masters,
          clients: clients,
          chats: chats,
          reviews: const [],
          transactions: transactions,
          settings: const SaPlatformSettings(),
          supportTickets: const [],
          categories: const [],
          coupons: const [],
          marketingLogs: const [],
        ),
      );
    } on DioException catch (e) {
      return ApiError(_errorMessage(e, 'Ошибка загрузки данных админки'));
    }
  }

  Future<ApiResult<List<AdminOrder>>> _fetchOrders(
    Map<String, String> nameById,
  ) async {
    try {
      final response = await _dio.get('/admin/orders');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiError('Неверный ответ сервера (orders)');

      final orders = list.map((raw) {
        final json = raw as Map<String, dynamic>;
        final id = json['id']?.toString() ?? '';
        final clientId = json['clientUserId']?.toString() ?? '';
        final masterId = json['masterUserId']?.toString();
        final statusCode = _readInt(json['status']);
        final amount = _readAmount(json['payableAmount'] ?? json['price']);
        final scheduled = json['scheduledDate']?.toString();
        final acceptedAt = json['acceptedAt']?.toString();

        final masterName = masterId != null
              ? (nameById[masterId.toLowerCase()] ?? _shortId(masterId))
              : '—';

        return AdminOrder(
          id: id.length > 8 ? '${id.substring(0, 8)}…' : id,
          fullId: id,
          client: nameById[clientId.toLowerCase()] ?? _shortId(clientId),
          master: masterName,
          service: json['title'] as String? ?? json['description'] as String? ?? 'Услуга',
          status: _mapOrderStatus(statusCode),
          date: _formatDate(scheduled ?? acceptedAt),
          amount: amount,
          clientUserId: clientId.isNotEmpty ? clientId : null,
          masterUserId: masterId,
          masterPhone: json['masterPhone']?.toString() ?? _masterPhoneForLabel(masterName),
          address: json['address']?.toString(),
        );
      }).toList();

      return ApiSuccess(orders);
    } on DioException catch (e) {
      return ApiError(
        _errorMessage(e, 'Ошибка загрузки заказов'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<_AdminUserRow>>> _fetchAllUsers() async {
    try {
      final mastersResult = await _fetchUsersPage(role: 'Master');
      if (mastersResult is ApiError<List<_AdminUserRow>>) {
        return mastersResult;
      }
      final clientsResult = await _fetchUsersPage(role: 'Client');
      if (clientsResult is ApiError<List<_AdminUserRow>>) {
        return clientsResult;
      }

      final otherResult = await _fetchUsersPage();
      if (otherResult is ApiError<List<_AdminUserRow>>) {
        return otherResult;
      }

      final merged = <String, _AdminUserRow>{};
      for (final batch in [
        (mastersResult as ApiSuccess<List<_AdminUserRow>>).data,
        (clientsResult as ApiSuccess<List<_AdminUserRow>>).data,
        (otherResult as ApiSuccess<List<_AdminUserRow>>).data,
      ]) {
        for (final user in batch) {
          merged[user.id] = user;
        }
      }

      return ApiSuccess(merged.values.toList());
    } on DioException catch (e) {
      return ApiError(
        _errorMessage(e, 'Ошибка загрузки пользователей'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<_AdminUserRow>>> _fetchUsersPage({
    String? role,
    int pageSize = 100,
  }) async {
    try {
      final allUsers = <_AdminUserRow>[];
      var page = 1;

      while (page <= 20) {
        final response = await _dio.get(
          '/admin/users',
          queryParameters: {
            if (role != null) 'role': role,
            'page': page,
            'pageSize': pageSize,
          },
        );

        final list = _unwrapList(response.data);
        if (list == null || list.isEmpty) break;

        for (final raw in list) {
          final json = raw as Map<String, dynamic>;
          final roles = (json['roles'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
          final first = json['firstName'] as String? ?? '';
          final last = json['lastName'] as String? ?? '';
          final phone = json['phoneNumber'] as String? ?? '';

          allUsers.add(
            _AdminUserRow(
              id: json['id']?.toString() ?? '',
              displayName: _formatUserName(first, last, phone),
              phone: phone,
              roles: roles,
              status: _readInt(json['status']),
            ),
          );
        }

        if (list.length < pageSize) break;
        page++;
      }

      return ApiSuccess(allUsers);
    } on DioException catch (e) {
      return ApiError(
        _errorMessage(e, 'Ошибка загрузки пользователей'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<AdminChat>>> _fetchChats(Map<String, String> nameById) async {
    try {
      final response = await _dio.get('/chat/conversations');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiSuccess(<AdminChat>[]);

      final chats = <AdminChat>[];
      for (final raw in list) {
        final json = raw as Map<String, dynamic>;
        final id = json['id']?.toString() ?? '';
        final title = json['title'] as String? ?? 'Чат';
        final participants = (json['participantUserIds'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];

        final otherId = participants.isNotEmpty ? participants.first : '';
        final name = nameById[otherId] ?? title;
        final avatar = name.isNotEmpty ? name[0].toUpperCase() : '?';

        final messagesResult = await _fetchChatMessages(id);
        final messages = messagesResult is ApiSuccess<List<AdminChatMessage>>
            ? messagesResult.data
            : const <AdminChatMessage>[];

        chats.add(
          AdminChat(
            id: id,
            name: name,
            avatar: avatar,
            lastMessage: messages.isNotEmpty ? messages.last.text : 'Нет сообщений',
            time: messages.isNotEmpty ? messages.last.time : '—',
            unread: 0,
            messages: messages,
          ),
        );
      }

      return ApiSuccess(chats);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 401) {
        return const ApiSuccess(<AdminChat>[]);
      }
      return ApiError(
        _errorMessage(e, 'Ошибка загрузки чатов'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ApiResult<List<AdminChatMessage>>> _fetchChatMessages(String chatId) async {
    try {
      final response = await _dio.get('/chat/conversations/$chatId/messages');
      final list = _unwrapList(response.data);
      if (list == null) return const ApiSuccess(<AdminChatMessage>[]);

      final messages = list.map((raw) {
        final json = raw as Map<String, dynamic>;
        final createdAt = json['createdAt']?.toString();
        return AdminChatMessage(
          text: json['text'] as String? ?? '',
          isAdmin: false,
          time: _formatTime(createdAt),
        );
      }).toList();

      return ApiSuccess(messages);
    } on DioException {
      return const ApiSuccess(<AdminChatMessage>[]);
    }
  }

  List<AdminMaster> _mapMasters(List<_AdminUserRow> users, List<AdminOrder> orders) {
    final masters = users.where((u) => u.roles.any((r) => r.toLowerCase() == 'master'));
    return masters.map((m) {
      final masterOrders = orders.where((o) => o.masterUserId == m.id).length;
      final income = masterOrders * 350;
      final status = switch (m.status) {
        3 => AdminMasterStatus.blocked,
        _ when masterOrders > 50 => AdminMasterStatus.top,
        _ => AdminMasterStatus.active,
      };

      return AdminMaster(
        id: m.id,
        name: m.displayName,
          avatar: m.displayName.isNotEmpty ? m.displayName[0].toUpperCase() : '?',
        specialization: 'Мастер',
        orders: masterOrders,
        rating: 4.8,
        income: income,
        status: status,
        phone: m.phone,
      );
    }).toList();
  }

  List<AdminClient> _mapClients(List<_AdminUserRow> users, List<AdminOrder> orders) {
    final clients = users.where((u) => u.roles.any((r) => r.toLowerCase() == 'client'));
    return clients.map((c) {
      final clientOrders = orders.where((o) => o.clientUserId == c.id).toList();
      final spent = clientOrders.fold<int>(0, (sum, o) => sum + o.amount);

      return AdminClient(
        id: c.id,
        name: c.displayName,
        phone: c.phone,
        orders: clientOrders.length,
        spent: spent,
        joined: '—',
        isVip: spent >= 5000,
      );
    }).toList();
  }

  List<AdminTransaction> _buildTransactions(List<AdminOrder> orders) {
    const commissionPercent = 12;
    return orders
        .where((o) => o.status == AdminOrderStatus.completed)
        .map((o) {
          final comm = (o.amount * commissionPercent / 100).round();
          return AdminTransaction(
            id: 'cm-${o.id}',
            type: 'Комиссия',
            amount: comm,
            party: 'Заказ ${o.id}',
            date: o.date,
            status: 'Завершено',
          );
        })
        .where((t) => t.amount > 0)
        .toList();
  }

  AdminOrderStatus _mapOrderStatus(int? code) => switch (code) {
        6 => AdminOrderStatus.completed,
        7 || 8 => AdminOrderStatus.cancelled,
        3 || 4 || 5 => AdminOrderStatus.inProgress,
        _ => AdminOrderStatus.newOrder,
      };

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _readAmount(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    final parsed = double.tryParse(value?.toString() ?? '');
    return parsed?.round() ?? 0;
  }

  String _formatUserName(String first, String last, String phone) {
    final name = '$first $last'.trim();
    if (name.isNotEmpty && name != 'Пользователь') return name;
    if (phone.isNotEmpty) return phone;
    return 'Клиент';
  }

  String? _masterPhoneForLabel(String label) {
    if (label.isEmpty || label == '—') return null;
    final needle = label.split(' ').first.toLowerCase();
    for (final master in masters) {
      if (master.fullName.toLowerCase().contains(needle)) {
        return master.phone;
      }
    }
    return null;
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.split('T').first;
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AdminUserRow {
  const _AdminUserRow({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.roles,
    required this.status,
  });

  final String id;
  final String displayName;
  final String phone;
  final List<String> roles;
  final int status;
}

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(dioProvider)),
);
