import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/superadmin_models.dart';
import '../../theme/superadmin_theme.dart';

class SaCard extends StatelessWidget {
  const SaCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: SuperAdminTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SuperAdminTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class SaKpiCard extends StatelessWidget {
  const SaKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.change,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.positive = true,
  });

  final String label;
  final String value;
  final String change;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    return SaCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: SuperAdminTheme.text)),
                ),
                Text(change, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: positive ? SuperAdminTheme.green : SuperAdminTheme.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SaStatusPill extends StatelessWidget {
  const SaStatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class SaLineChartCard extends StatelessWidget {
  const SaLineChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
    this.period,
    this.onPeriod,
    this.periodOptions = const ['7 дней', '30 дней', '90 дней'],
  });

  final String title;
  final List<SaChartPoint> points;
  final Color color;
  final String? period;
  final ValueChanged<String>? onPeriod;
  final List<String> periodOptions;

  @override
  Widget build(BuildContext context) {
    final maxY = _saChartMaxY(points);
    final hasData = points.any((p) => p.value > 0 && p.label != 'Нет');
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chartHeader(title, period, onPeriod, periodOptions),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _saGridInterval(maxY),
                        getDrawingHorizontalLine: (_) => const FlLine(color: SuperAdminTheme.border),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= points.length) return const SizedBox.shrink();
                              return Text(points[i].label, style: GoogleFonts.inter(fontSize: 9, color: SuperAdminTheme.muted));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value)],
                          isCurved: true,
                          color: color,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                        ),
                      ],
                    ),
                  )
                : Center(child: Text('Нет данных', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted))),
          ),
        ],
      ),
    );
  }
}

double _saChartMaxY(List<SaChartPoint> points) {
  if (points.isEmpty) return 4;
  final max = points.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
  return max <= 0 ? 4 : max * 1.25;
}

double _saGridInterval(double maxY) {
  final interval = maxY / 4;
  return interval < 1 ? 1 : interval;
}

class SaBarChartCard extends StatelessWidget {
  const SaBarChartCard({super.key, required this.title, required this.points});

  final String title;
  final List<SaChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final maxY = _saChartMaxY(points);
    final hasData = points.any((p) => p.value > 0 && p.label != 'Нет');
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: SuperAdminTheme.text)),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: hasData
                ? BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _saGridInterval(maxY),
                        getDrawingHorizontalLine: (_) => const FlLine(color: SuperAdminTheme.border),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= points.length) return const SizedBox.shrink();
                              return Text(points[i].label, style: GoogleFonts.inter(fontSize: 9, color: SuperAdminTheme.muted));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < points.length; i++)
                          BarChartGroupData(x: i, barRods: [BarChartRodData(toY: points[i].value, color: SuperAdminTheme.green, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))]),
                      ],
                    ),
                  )
                : Center(child: Text('Нет данных', style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.muted))),
          ),
        ],
      ),
    );
  }
}

class SaPieChartCard extends StatelessWidget {
  const SaPieChartCard({super.key, required this.title, required this.slices, required this.total});

  final String title;
  final List<SaPieSlice> slices;
  final String total;

  @override
  Widget build(BuildContext context) {
    return SaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: SuperAdminTheme.text)),
          const SizedBox(height: 8),
          SizedBox(
            height: 170,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 42,
                        sections: [
                          for (final s in slices)
                            PieChartSectionData(value: s.value, color: s.color, radius: 28, showTitle: false),
                        ],
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(total, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: SuperAdminTheme.text)),
                          Text('всего', style: GoogleFonts.inter(fontSize: 10, color: SuperAdminTheme.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final s in slices)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text('${s.label} ${s.percent}%', style: GoogleFonts.inter(fontSize: 10.5, color: SuperAdminTheme.muted)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _chartHeader(String title, String? period, ValueChanged<String>? onPeriod, List<String> options) {
  final safePeriod = period != null && options.contains(period) ? period : options.first;
  return Row(
    children: [
      Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: SuperAdminTheme.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
      if (period != null && onPeriod != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(border: Border.all(color: SuperAdminTheme.border), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safePeriod,
              isDense: true,
              iconSize: 16,
              style: GoogleFonts.inter(fontSize: 11, color: SuperAdminTheme.text),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.inter(fontSize: 11)))).toList(),
              onChanged: (v) { if (v != null) onPeriod(v); },
            ),
          ),
        ),
    ],
  );
}

class SaSectionTitle extends StatelessWidget {
  const SaSectionTitle({super.key, required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: SuperAdminTheme.text)),
        const Spacer(),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!, style: GoogleFonts.inter(fontSize: 12, color: SuperAdminTheme.green, fontWeight: FontWeight.w600))),
      ],
    );
  }
}
