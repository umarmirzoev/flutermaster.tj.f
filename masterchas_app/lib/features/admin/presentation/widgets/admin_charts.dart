import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/admin_models.dart';
import '../../theme/admin_theme.dart';
import 'admin_badges.dart';

double _chartMaxY(List<AdminChartPoint> points) {
  if (points.isEmpty) return 4;
  final max = points.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);
  return max <= 0 ? 4 : max * 1.2;
}

double _gridInterval(double maxY) {
  final interval = maxY / 4;
  return interval < 1 ? 1 : interval;
}

bool _chartHasData(List<AdminChartPoint> points) {
  if (points.isEmpty) return false;
  return points.any((p) => p.value > 0 && p.label != 'Нет');
}

class AdminLineChartCard extends StatelessWidget {
  const AdminLineChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
    this.height = 180,
  });

  final String title;
  final List<AdminChartPoint> points;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!_chartHasData(points)) {
      return AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text)),
            SizedBox(
              height: height,
              child: Center(child: Text('Нет данных для графика', style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.muted))),
            ),
          ],
        ),
      );
    }

    final maxY = _chartMaxY(points);
    final interval = _gridInterval(maxY);
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text)),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AdminTheme.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        return Text(points[i].label, style: GoogleFonts.inter(fontSize: 9, color: AdminTheme.muted));
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
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminBarChartCard extends StatelessWidget {
  const AdminBarChartCard({
    super.key,
    required this.title,
    required this.points,
    this.height = 180,
  });

  final String title;
  final List<AdminChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (!_chartHasData(points)) {
      return AdminCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text)),
            SizedBox(
              height: height,
              child: Center(child: Text('Нет данных для графика', style: GoogleFonts.inter(fontSize: 12, color: AdminTheme.muted))),
            ),
          ],
        ),
      );
    }

    final maxY = _chartMaxY(points);
    final interval = _gridInterval(maxY);
    return AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AdminTheme.text)),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(color: AdminTheme.border, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) return const SizedBox.shrink();
                        return Text(points[i].label, style: GoogleFonts.inter(fontSize: 9, color: AdminTheme.muted));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < points.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: points[i].value,
                          color: AdminTheme.green,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
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
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: AdminTheme.muted)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AdminTheme.text)),
                Text(
                  change,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: positive ? AdminTheme.green : AdminTheme.red,
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
