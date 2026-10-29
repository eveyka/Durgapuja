import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class CircularBreakdownChart extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final Map<ExpenseCategory, double> categoryBreakdown;

  const CircularBreakdownChart({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.categoryBreakdown,
  });

  @override
  State<CircularBreakdownChart> createState() => _CircularBreakdownChartState();
}

class _CircularBreakdownChartState extends State<CircularBreakdownChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                      Icons.pie_chart_outline,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Puja Fund Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.totalIncome > 0 ? ((widget.totalExpense / widget.totalIncome) * 100).toStringAsFixed(1) : 0}% Spent',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Donut Chart with Center Text
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 65,
                    sections: _getSections(),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final remaining = widget.totalIncome - widget.totalExpense;
                    final isSafe = remaining >= 0;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withAlpha(150),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(remaining),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isSafe ? Colors.white : AppTheme.dangerRose,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isSafe ? AppTheme.successGreen : AppTheme.dangerRose).withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSafe ? 'Safe Balance' : 'Deficit / Short',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isSafe ? AppTheme.successGreenLight : AppTheme.dangerRose,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Key Highlights
          Row(
            children: [
              Expanded(
                child: _MetricPill(
                  title: 'Total Inflow',
                  amount: '₹${NumberFormat.compact().format(widget.totalIncome)}',
                  color: AppTheme.primaryBlue,
                  icon: Icons.south_west,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricPill(
                  title: 'Total Spent',
                  amount: '₹${NumberFormat.compact().format(widget.totalExpense)}',
                  color: AppTheme.dangerRose,
                  icon: Icons.north_east,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    final List<PieChartSectionData> sections = [];
    final total = widget.totalExpense;

    if (total <= 0) {
      return [
        PieChartSectionData(
          color: AppTheme.primaryBlue.withAlpha(100),
          value: 100,
          title: '',
          radius: 20,
        )
      ];
    }

    int idx = 0;
    widget.categoryBreakdown.forEach((category, amount) {
      if (amount > 0) {
        final isTouched = idx == touchedIndex;
        final radius = isTouched ? 28.0 : 20.0;
        final percentage = (amount / total) * 100;

        sections.add(
          PieChartSectionData(
            color: category.color,
            value: amount,
            title: percentage > 15 ? '${percentage.toInt()}%' : '',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
        idx++;
      }
    });

    return sections;
  }
}

class _MetricPill extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  const _MetricPill({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withAlpha(160),
                  ),
                ),
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
