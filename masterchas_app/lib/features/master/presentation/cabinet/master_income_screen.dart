import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/master_palette.dart';
import '../../../auth/providers/auth_provider.dart';
import 'master_cabinet_shell.dart';
import 'widgets/income_chart.dart';

class MasterIncomeScreen extends ConsumerStatefulWidget {
  const MasterIncomeScreen({super.key});

  @override
  ConsumerState<MasterIncomeScreen> createState() => _MasterIncomeScreenState();
}

class _MasterIncomeScreenState extends ConsumerState<MasterIncomeScreen> {
  IncomePeriod _period = IncomePeriod.month;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).masterProfile;
    if (profile == null) {
      return const MasterCabinetShell(
        title: 'Доход',
        child: Center(child: CircularProgressIndicator(color: masterNavy)),
      );
    }

    final earnings = profile.earnings
        .map((e) => (date: e.date, amount: e.amountSomoni))
        .toList();
    final points = buildIncomePoints(period: _period, earnings: earnings);
    final periodTotal = points.fold<int>(0, (s, p) => s + p.amount);
    final best = points.isEmpty
        ? 0
        : points.map((p) => p.amount).reduce((a, b) => a > b ? a : b);

    return MasterCabinetShell(
      title: 'Доход',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          IncomePeriodTabs(
            selected: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  icon: LucideIcons.wallet,
                  label: _periodLabel(_period),
                  value: formatSomoni(periodTotal),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  icon: LucideIcons.trending_up,
                  label: 'Лучший период',
                  value: formatSomoni(best),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IncomeBarChart(points: points),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8ECF1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'За месяц',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatSomoni(profile.monthlyIncome),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: masterNavy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  earnings.isEmpty
                      ? 'Доход появится после выполнения заказов'
                      : 'Всего записей: ${earnings.length}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

  String _periodLabel(IncomePeriod p) => switch (p) {
        IncomePeriod.day => 'Сегодня',
        IncomePeriod.week => 'За неделю',
        IncomePeriod.month => 'За месяц',
        IncomePeriod.year => 'За год',
      };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: masterNavy, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
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
    );
  }
}
