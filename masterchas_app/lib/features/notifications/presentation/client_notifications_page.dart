import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/l10n/home_strings.dart';
import '../../../core/providers/locale_provider.dart';
import '../../home/presentation/home_palette.dart';
import '../../profile/presentation/profile_subpages.dart';

class ClientNotificationsPage extends ConsumerWidget {
  const ClientNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = HomeStrings.of(ref.watch(localeProvider));
    final p = HomePalette.of(context);

    final items = [
      _NotifItem(
        icon: LucideIcons.circle_check,
        color: brandGreen,
        title: s.notif1Title,
        body: s.notif1Body,
        time: s.notif1Time,
        unread: true,
      ),
      _NotifItem(
        icon: LucideIcons.truck,
        color: const Color(0xFF3B82F6),
        title: s.notif2Title,
        body: s.notif2Body,
        time: s.notif2Time,
        unread: true,
      ),
      _NotifItem(
        icon: LucideIcons.tag,
        color: const Color(0xFFF59E0B),
        title: s.notif3Title,
        body: s.notif3Body,
        time: s.notif3Time,
        unread: false,
      ),
    ];

    return Scaffold(
      backgroundColor: p.pageBg,
      appBar: AppBar(
        backgroundColor: p.cardBg,
        foregroundColor: p.text,
        elevation: 0,
        title: Text(
          s.notificationsTitle,
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: s.notifSettings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
            ),
            icon: Icon(LucideIcons.settings, color: p.muted, size: 20),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bell_off, size: 48, color: p.muted),
                  const SizedBox(height: 12),
                  Text(
                    s.notifEmpty,
                    style: GoogleFonts.inter(fontSize: 14, color: p.muted),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _NotifTile(item: items[i], p: p),
            ),
    );
  }
}

class _NotifItem {
  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String time;
  final bool unread;
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item, required this.p});

  final _NotifItem item;
  final HomePalette p;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: p.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.unread ? brandGreen.withValues(alpha: 0.35) : p.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: p.text,
                            ),
                          ),
                        ),
                        Text(
                          item.time,
                          style: GoogleFonts.inter(fontSize: 11, color: p.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: GoogleFonts.inter(fontSize: 12.5, color: p.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (item.unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
