import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class DailyBarChartWidget extends StatelessWidget {
  final List<DailyCashflow> cashflows;

  const DailyBarChartWidget({
    super.key,
    required this.cashflows,
  });

  @override
  Widget build(BuildContext context) {
    final maxFlow = cashflows.fold<double>(
      10.0,
      (prev, item) {
        final m = (item.income > item.expense ? item.income : item.expense) / 1000.0;
        return m > prev ? m : prev;
      },
    );
    final computedMaxY = ((maxFlow * 1.3) / 10).ceil() * 10.0;
    final step = (computedMaxY / 3).roundToDouble().clamp(5.0, 1000.0);

    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bar_chart,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Puja Days Cashflow',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _LegendDot(color: AppTheme.primaryBlue, label: 'Inflow'),
                  const SizedBox(width: 10),
                  _LegendDot(color: const Color(0xFF64748B), label: 'Outflow'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: computedMaxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = cashflows[groupIndex].dayName;
                      final type = rodIndex == 0 ? 'Inflow' : 'Outflow';
                      final val = rod.toY * 1000;
                      return BarTooltipItem(
                        '$day\n$type: ₹${NumberFormat.compact().format(val)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < cashflows.length) {
                          final day = cashflows[index].dayName;
                          final display = day.length >= 3 ? day.substring(0, 3) : day;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              display.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || (value - step).abs() < 1.0 || (value - (step * 2)).abs() < 1.0) {
                          return Text(
                            '₹${value.toInt()}k',
                            style: TextStyle(
                              color: Colors.white.withAlpha(120),
                              fontSize: 10,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: step,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withAlpha(20),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: cashflows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: item.income / 1000,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF0284C7),
                            Color(0xFF38BDF8),
                          ],
                        ),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                      BarChartRodData(
                        toY: item.expense / 1000,
                        color: const Color(0xFF475569),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(170),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
