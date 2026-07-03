import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/master_palette.dart';
import '../../auth/models/master_profile.dart';
import '../../auth/providers/auth_provider.dart';
import 'cabinet/master_cabinet_shell.dart';
import 'master_pending_profile.dart';
import 'widgets/master_avatar.dart';

class MasterDashboard extends ConsumerWidget {
  const MasterDashboard({super.key, this.bottomPadding = 110});

  final double bottomPadding;

  Future<void> _addPortfolioPhoto(BuildContext context, WidgetRef ref) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    await ref
        .read(authProvider.notifier)
        .addPortfolioPhoto(base64Encode(bytes));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Фото добавлено в портфолио', style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider).masterProfile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator(color: masterNavy));
    }

    final ratingLabel =
        profile.rating > 0 ? profile.rating.toStringAsFixed(1) : '—';

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding),
      children: [
        _DashboardHeader(profile: profile),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.wrench,
                      value: '${profile.completedOrders}',
                      label: 'Выполнено заказов',
                      onTap: () => context.push('/master/cabinet/orders'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.wallet,
                      value: formatSomoni(profile.monthlyIncome),
                      label: 'Доход за месяц',
                      onTap: () => context.push('/master/cabinet/income'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.calendar,
                      value: '${profile.activeOrders}',
                      label: 'Активные заказы',
                      onTap: () => context.push('/master/cabinet/active-orders'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: LucideIcons.star,
                      value: ratingLabel,
                      label: 'Рейтинг',
                      onTap: () => context.push('/master/cabinet/rating'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.push('/master/cabinet/level'),
                      child: _PanelCard(
                        title: 'Уровень мастера',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.award, color: Colors.amber.shade700, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Старт',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: masterNavy,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Выполняйте заказы, чтобы повысить уровень',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PanelCard(
                      title: 'Быстрые действия',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _QuickChip(
                            icon: LucideIcons.calendar,
                            label: 'График',
                            onTap: () => context.push('/master/cabinet/schedule'),
                          ),
                          _QuickChip(
                            icon: LucideIcons.message_circle,
                            label: 'Чаты',
                            onTap: () => context.push('/master/cabinet/chats'),
                          ),
                          _QuickChip(
                            icon: LucideIcons.map_pin,
                            label: 'Зона',
                            onTap: () => context.push('/master/cabinet/zone'),
                          ),
                          _QuickChip(
                            icon: LucideIcons.folder,
                            label: 'Портфолио',
                            onTap: () => context.push('/master/cabinet/portfolio'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _PanelCard(
                title: 'Портфолио работ',
                trailing: TextButton(
                  onPressed: () => context.push('/master/cabinet/portfolio'),
                  child: Text(
                    'Смотреть все',
                    style: GoogleFonts.inter(
                      color: masterNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                child: profile.portfolioBase64.isEmpty
                    ? GestureDetector(
                        onTap: () => _addPortfolioPhoto(context, ref),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: masterPageBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE8ECF1)),
                          ),
                          child: Column(
                            children: [
                              const Icon(LucideIcons.image_plus, color: masterNavy, size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Добавьте фото выполненных работ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => context.push('/master/cabinet/portfolio'),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: profile.portfolioBase64.length.clamp(0, 6),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                Uint8List.fromList(
                                  base64Decode(profile.portfolioBase64[index]),
                                ),
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.push('/master/cabinet/rating'),
                child: _PanelCard(
                  title: 'Отзывы клиентов',
                  trailing: Text(
                    'Смотреть все',
                    style: GoogleFonts.inter(
                      color: masterNavy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        profile.reviewCount > 0
                            ? '${profile.reviewCount} отзывов'
                            : 'Пока нет отзывов',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ваши услуги (${profile.selectedServices.length})',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: masterNavy,
                ),
              ),
              const SizedBox(height: 8),
              ...profile.selectedServices.take(8).map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${key.split('::').last}',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.profile});

  final MasterProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [masterNavy, masterNavyLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Кабинет мастера',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              masterAvatar(profile: profile, size: 76),
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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Онлайн',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Мастер · ${masterPrimaryCategory(profile)}',
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
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8ECF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: masterNavy, size: 20),
                  const Spacer(),
                  Icon(LucideIcons.chevron_right, size: 16, color: masterNavy.withValues(alpha: 0.4)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: masterNavy,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: masterNavy,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: masterPageBg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: masterNavy),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: masterNavy),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
