import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/master_palette.dart';
import '../../auth/models/master_application_status.dart';
import '../../auth/models/master_profile.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/master_avatar.dart';

String masterPrimaryCategory(MasterProfile profile) {
  if (profile.selectedServices.isEmpty) return 'Мастер';
  return profile.selectedServices.first.split('::').first;
}

class MasterPendingProfile extends ConsumerWidget {
  const MasterPendingProfile({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final profile = auth.masterProfile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator(color: masterNavy));
    }

    final isPending =
        profile.applicationStatus == MasterApplicationStatus.pending;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _Header(profile: profile),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDBA74)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.clock,
                      color: Color(0xFFEA580C),
                      size: 36,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPending
                          ? 'Ваша заявка на рассмотрении'
                          : 'Заявка одобрена',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: masterNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPending
                          ? 'Мы проверяем ваши данные и выбранные услуги. '
                              'После одобрения откроется полный кабинет мастера.'
                          : 'Обновите профиль — кабинет уже доступен.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF6B7280),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _InfoTile(
                icon: LucideIcons.user,
                title: profile.fullName,
                subtitle: masterPrimaryCategory(profile),
              ),
              const SizedBox(height: 10),
              _InfoTile(
                icon: LucideIcons.briefcase,
                title: 'Выбрано услуг: ${profile.selectedServices.length}',
                subtitle: 'Специализации сохранены',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isPending
                              ? 'Статус: на рассмотрении'
                              : 'Статус: одобрено',
                          style: GoogleFonts.inter(),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: masterNavy,
                    side: const BorderSide(color: masterNavy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Проверить статус',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (kDebugMode && isPending) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(authProvider.notifier)
                        .approveMasterApplication();
                  },
                  child: Text(
                    'Демо: одобрить заявку',
                    style: GoogleFonts.inter(
                      color: masterNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final MasterProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 18, 16, 22),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [masterNavy, masterNavyLight],
        ),
      ),
      child: Row(
        children: [
          masterAvatar(profile: profile, size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.shortName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  masterPrimaryCategory(profile),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: masterNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: masterNavy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: masterNavy,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
