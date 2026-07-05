import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import '../../data/admin_data.dart';

class AdminWorkflowStatusBadge extends StatelessWidget {
  const AdminWorkflowStatusBadge({super.key, required this.statusCode});

  final int statusCode;

  @override
  Widget build(BuildContext context) {
    final adminStatus = switch (statusCode) {
      6 => AdminOrderStatus.completed,
      7 || 8 => AdminOrderStatus.cancelled,
      3 || 4 || 5 => AdminOrderStatus.inProgress,
      _ => AdminOrderStatus.newOrder,
    };

    final (bg, fg) = switch (adminStatus) {
      AdminOrderStatus.newOrder => (const Color(0xFFDBEAFE), AdminTheme.blue),
      AdminOrderStatus.inProgress => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      AdminOrderStatus.completed => (const Color(0xFFD1FAE5), AdminTheme.green),
      AdminOrderStatus.cancelled => (const Color(0xFFFEE2E2), AdminTheme.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        workflowStatusLabel(statusCode),
        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.status});

  final AdminOrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      AdminOrderStatus.newOrder => (const Color(0xFFDBEAFE), AdminTheme.blue, orderStatusLabel(status)),
      AdminOrderStatus.inProgress => (const Color(0xFFFEF3C7), const Color(0xFFB45309), orderStatusLabel(status)),
      AdminOrderStatus.completed => (const Color(0xFFD1FAE5), AdminTheme.green, orderStatusLabel(status)),
      AdminOrderStatus.cancelled => (const Color(0xFFFEE2E2), AdminTheme.red, orderStatusLabel(status)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class AdminMasterBadge extends StatelessWidget {
  const AdminMasterBadge({super.key, required this.status});

  final AdminMasterStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      AdminMasterStatus.active || AdminMasterStatus.top => (const Color(0xFFD1FAE5), AdminTheme.green),
      AdminMasterStatus.pending => (const Color(0xFFFEF3C7), const Color(0xFFB45309)),
      AdminMasterStatus.blocked => (const Color(0xFFFEE2E2), AdminTheme.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(masterStatusLabel(status), style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class AdminCard extends StatelessWidget {
  const AdminCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

String formatMoney(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}
