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

  bool get canOpenChat =>
      conversationId != null && conversationId!.isNotEmpty;
}
