import 'package:flutter/material.dart';

class ChatInboxItem {
  const ChatInboxItem({
    required this.orderId,
    required this.peerName,
    required this.subtitle,
    required this.timeLabel,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.sortTime,
    this.conversationId,
    this.avatarAsset,
    this.isLocal = false,
    this.unreadCount = 0,
    this.peerPhone,
  });

  final String orderId;
  final String? conversationId;
  final String peerName;
  final String subtitle;
  final String timeLabel;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeBgColor;
  final DateTime sortTime;
  final String? avatarAsset;
  final bool isLocal;
  final int unreadCount;
  final String? peerPhone;

  bool get canOpenChat =>
      conversationId != null && conversationId!.isNotEmpty;

  ChatInboxItem copyWith({
    String? conversationId,
    bool? isLocal,
  }) {
    return ChatInboxItem(
      orderId: orderId,
      conversationId: conversationId ?? this.conversationId,
      peerName: peerName,
      subtitle: subtitle,
      timeLabel: timeLabel,
      badgeLabel: badgeLabel,
      badgeColor: badgeColor,
      badgeBgColor: badgeBgColor,
      sortTime: sortTime,
      avatarAsset: avatarAsset,
      isLocal: isLocal ?? this.isLocal,
      unreadCount: unreadCount,
      peerPhone: peerPhone,
    );
  }
}
