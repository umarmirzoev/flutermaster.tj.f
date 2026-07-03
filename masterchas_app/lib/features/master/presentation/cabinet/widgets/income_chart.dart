import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/master_palette.dart';

enum IncomePeriod { day, week, month, year }

class IncomeChartPoint {
  const IncomeChartPoint({required this.label, required this.amount});

  final String label;
  final int amount;
}

List<IncomeChartPoint> buildIncomePoints({
  required IncomePeriod period,
  required List<({DateTime date, int amount})> earnings,
  DateTime? now,
}) {
  final today = now ?? DateTime.now();

  switch (period) {
    case IncomePeriod.day:
      return List.generate(24, (h) {
        final total = earnings
            .where((e) =>
                e.date.year == today.year &&
                e.date.month == today.month &&
                e.date.day == today.day &&
                e.date.hour == h)
            .fold<int>(0, (s, e) => s + e.amount);
        return IncomeChartPoint(label: h.toString().padLeft(2, '0'), amount: total);
      });
    case IncomePeriod.week:
      final start = today.subtract(Duration(days: today.weekday - 1));
      const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return List.generate(7, (i) {
        final day = start.add(Duration(days: i));
        final total = earnings
            .where((e) =>
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day)
            .fold<int>(0, (s, e) => s + e.amount);
        return IncomeChartPoint(label: labels[i], amount: total);
      });
    case IncomePeriod.month:
      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      final step = daysInMonth > 20 ? 5 : 1;
      final points = <IncomeChartPoint>[];
      for (var d = 1; d <= daysInMonth; d += step) {
        final total = earnings
            .where((e) =>
                e.date.year == today.year &&
                e.date.month == today.month &&
                e.date.day >= d &&
                e.date.day < d + step)
            .fold<int>(0, (s, e) => s + e.amount);
        points.add(IncomeChartPoint(label: '$d', amount: total));
      }
      return points;
    case IncomePeriod.year:
      const labels = [
        'Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн',
        'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек',
      ];
      return List.generate(12, (m) {
        final total = earnings
            .where((e) => e.date.year == today.year && e.date.month == m + 1)
            .fold<int>(0, (s, e) => s + e.amount);
        return IncomeChartPoint(label: labels[m], amount: total);
      });
  }
}

class IncomeBarChart extends StatelessWidget {
  const IncomeBarChart({super.key, required this.points});

  final List<IncomeChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxAmount = points.map((p) => p.amount).fold<int>(0, (a, b) => a > b ? a : b);
    final chartMax = maxAmount == 0 ? 1 : maxAmount;

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (point.amount > 0)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${point.amount}',
                                style: GoogleFonts.inter(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  color: masterNavy,
                                ),
                              ),
                            ),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: point.amount / chartMax,
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      masterNavy,
                                      masterNavy.withValues(alpha: 0.55),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final point in points)
                Expanded(
                  child: Text(
                    point.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: points.length > 12 ? 8 : 10,
                      color: const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class IncomePeriodTabs extends StatelessWidget {
  const IncomePeriodTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final IncomePeriod selected;
  final ValueChanged<IncomePeriod> onChanged;

  static const _labels = {
    IncomePeriod.day: 'День',
    IncomePeriod.week: 'Неделя',
    IncomePeriod.month: 'Месяц',
    IncomePeriod.year: 'Год',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      child: Row(
        children: IncomePeriod.values.map((p) {
          final isActive = p == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? masterNavy : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _labels[p]!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
