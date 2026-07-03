import 'dart:typed_data';

import 'package:flutter/material.dart';

enum SaOrderStatus { newOrder, inProgress, completed, cancelled }

class SaOrder {
  const SaOrder({
    required this.id,
    required this.client,
    required this.master,
    required this.service,
    required this.date,
    required this.status,
    required this.amount,
  });

  final String id;
  final String client;
  final String master;
  final String service;
  final String date;
  final SaOrderStatus status;
  final int amount;
}

class SaProduct {
  const SaProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.image,
    required this.sold,
    required this.inStock,
    this.description = '',
    this.imageBytes,
    this.brand = '',
  });

  final String id;
  final String name;
  final String category;
  final int price;
  final String image;
  final int sold;
  final bool inStock;
  final String description;
  final Uint8List? imageBytes;
  final String brand;
}

class SaMaster {
  const SaMaster({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.orders,
    required this.phone,
    required this.specialization,
    this.imageBytes,
  });

  final String id;
  final String name;
  final String avatar;
  final double rating;
  final int orders;
  final String phone;
  final String specialization;
  final Uint8List? imageBytes;
}

class SaClient {
  const SaClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.date,
    this.isNew = false,
    this.orders = 0,
    this.spent = 0,
    this.isVip = false,
  });

  final String id;
  final String name;
  final String phone;
  final String avatar;
  final String date;
  final bool isNew;
  final int orders;
  final int spent;
  final bool isVip;
}

class SaCategory {
  const SaCategory({required this.id, required this.name, required this.productCount, this.active = true});

  final String id;
  final String name;
  final int productCount;
  final bool active;
}

class SaBrand {
  const SaBrand({required this.id, required this.name, required this.productCount, this.active = true});

  final String id;
  final String name;
  final int productCount;
  final bool active;
}

class SaCoupon {
  const SaCoupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercent,
    this.active = true,
    this.uses = 0,
  });

  final String id;
  final String code;
  final String description;
  final int discountPercent;
  final bool active;
  final int uses;
}

class SaChatMessage {
  const SaChatMessage({required this.text, required this.isAdmin, required this.time});

  final String text;
  final bool isAdmin;
  final String time;
}

class SaChatThread {
  const SaChatThread({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.messages,
  });

  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final int unread;
  final List<SaChatMessage> messages;
}

class SaReview {
  const SaReview({
    required this.id,
    required this.author,
    required this.avatar,
    required this.text,
    required this.rating,
    required this.master,
    required this.date,
    this.hidden = false,
    this.flagged = false,
  });

  final String id;
  final String author;
  final String avatar;
  final String text;
  final int rating;
  final String master;
  final String date;
  final bool hidden;
  final bool flagged;
}

class SaNotification {
  const SaNotification({
    required this.id,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
    this.read = false,
  });

  final String id;
  final String title;
  final String time;
  final IconData icon;
  final Color color;
  final bool read;
}

class SaPayout {
  const SaPayout({
    required this.id,
    required this.master,
    required this.amount,
    required this.method,
    required this.date,
    required this.paid,
  });

  final String id;
  final String master;
  final int amount;
  final String method;
  final String date;
  final bool paid;
}

class SaSupportTicket {
  const SaSupportTicket({required this.id, required this.title, required this.status, required this.date, this.description = ''});

  final String id;
  final String title;
  final String status;
  final String date;
  final String description;
}

class SaCmsPage {
  const SaCmsPage({required this.id, required this.title, required this.status});

  final String id;
  final String title;
  final String status;
}

class SaMarketingLog {
  const SaMarketingLog({required this.id, required this.text, required this.sentAt, required this.recipients});

  final String id;
  final String text;
  final String sentAt;
  final int recipients;
}

/// Заявка на ремонт в детском центре / доме престарелых из благотворительного фонда.
class SaCharityCase {
  const SaCharityCase({
    required this.id,
    required this.organizationType,
    required this.organizationName,
    required this.problem,
    required this.estimatedCost,
    required this.date,
    this.status = 'Ожидает',
  });

  final String id;
  final String organizationType;
  final String organizationName;
  final String problem;
  final int estimatedCost;
  final String date;
  final String status;
}

const charityFundPercent = 10;

const charityOrganizationTypes = ['Детский центр', 'Дом престарелых'];

class SaPlatformSettings {
  const SaPlatformSettings({
    this.maintenance = false,
    this.registrations = true,
    this.commissionPercent = 12,
    this.pushNotifications = true,
    this.autoApproveMasters = false,
  });

  final bool maintenance;
  final bool registrations;
  final int commissionPercent;
  final bool pushNotifications;
  final bool autoApproveMasters;
}

class SaSystemService {
  const SaSystemService({required this.name, required this.status, required this.detail});

  final String name;
  final String status;
  final String detail;
}

class SaChartPoint {
  const SaChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class SaPieSlice {
  const SaPieSlice({required this.label, required this.value, required this.color, required this.percent});

  final String label;
  final double value;
  final Color color;
  final int percent;
}

class SaMenuItem {
  const SaMenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.badge,
    this.badgeColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final String route;
  final String? badge;
  final Color? badgeColor;
}
