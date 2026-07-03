import 'package:flutter/material.dart';

import '../../../core/models/platform_models.dart';

enum AdminOrderStatus { newOrder, inProgress, completed, cancelled }

enum AdminMasterStatus { active, pending, blocked, top }

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.client,
    required this.master,
    required this.service,
    required this.status,
    required this.date,
    required this.amount,
    this.clientUserId,
    this.masterUserId,
  });

  final String id;
  final String client;
  final String master;
  final String service;
  final AdminOrderStatus status;
  final String date;
  final int amount;
  final String? clientUserId;
  final String? masterUserId;
}

class AdminMaster {
  const AdminMaster({
    required this.id,
    required this.name,
    required this.avatar,
    required this.specialization,
    required this.orders,
    required this.rating,
    required this.income,
    required this.status,
    required this.phone,
  });

  final String id;
  final String name;
  final String avatar;
  final String specialization;
  final int orders;
  final double rating;
  final int income;
  final AdminMasterStatus status;
  final String phone;
}

class AdminClient {
  const AdminClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.orders,
    required this.spent,
    required this.joined,
    required this.isVip,
  });

  final String id;
  final String name;
  final String phone;
  final int orders;
  final int spent;
  final String joined;
  final bool isVip;
}

class AdminChat {
  const AdminChat({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.messages = const [],
  });

  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final List<AdminChatMessage> messages;
}

class AdminChatMessage {
  const AdminChatMessage({required this.text, required this.isAdmin, required this.time});

  final String text;
  final bool isAdmin;
  final String time;
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.author,
    required this.master,
    required this.rating,
    required this.text,
    required this.date,
    required this.flagged,
  });

  final String id;
  final String author;
  final String master;
  final int rating;
  final String text;
  final String date;
  final bool flagged;
}

class AdminTransaction {
  const AdminTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.party,
    required this.date,
    required this.status,
  });

  final String id;
  final String type;
  final int amount;
  final String party;
  final String date;
  final String status;
}

class AdminMenuItem {
  const AdminMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.children = const [],
    this.badge,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
  final List<AdminMenuChild> children;
  final int? badge;
}

class AdminMenuChild {
  const AdminMenuChild({required this.label, required this.route});

  final String label;
  final String route;
}

class AdminDataState {
  const AdminDataState({
    required this.orders,
    required this.masters,
    required this.clients,
    required this.chats,
    required this.reviews,
    required this.transactions,
    required this.settings,
    required this.supportTickets,
    required this.categories,
    required this.coupons,
    required this.marketingLogs,
  });

  final List<AdminOrder> orders;
  final List<AdminMaster> masters;
  final List<AdminClient> clients;
  final List<AdminChat> chats;
  final List<AdminReview> reviews;
  final List<AdminTransaction> transactions;
  final SaPlatformSettings settings;
  final List<SaSupportTicket> supportTickets;
  final List<SaCategory> categories;
  final List<SaCoupon> coupons;
  final List<SaMarketingLog> marketingLogs;

  factory AdminDataState.empty() => const AdminDataState(
        orders: [],
        masters: [],
        clients: [],
        chats: [],
        reviews: [],
        transactions: [],
        settings: SaPlatformSettings(),
        supportTickets: [],
        categories: [],
        coupons: [],
        marketingLogs: [],
      );
}

class AdminChartPoint {
  const AdminChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}
