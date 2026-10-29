import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_breakdown_chart.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 28 : 16,
          20,
          isDesktop ? 28 : 16,
          isDesktop ? 24 : 100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Puja Financial Analytics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time cashflow & audit metrics',
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(150)),
            ),
            const SizedBox(height: 20),

            if (isDesktop) ...[
              // Desktop: Donut meter and Payment channels side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 6,
                    child: CircularBreakdownChart(
                      totalIncome: provider.totalIncome,
                      totalExpense: provider.totalExpense,
                      categoryBreakdown: provider.expenseByCategory,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collection Payment Channels',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        _buildChannelCard(
                          title: 'Cash In Hand',
                          amount: currency.format(provider.cashInHand),
                          icon: Icons.wallet,
                          color: AppTheme.goldAccent,
                        ),
                        const SizedBox(height: 12),
                        _buildChannelCard(
                          title: 'Bank & UPI',
                          amount: currency.format(provider.bankUpiBalance),
                          icon: Icons.account_balance,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Mobile: Stacked
              CircularBreakdownChart(
                totalIncome: provider.totalIncome,
                totalExpense: provider.totalExpense,
                categoryBreakdown: provider.expenseByCategory,
              ),
              const SizedBox(height: 20),
              const Text(
                'Collection Payment Channels',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildChannelCard(
                      title: 'Cash In Hand',
                      amount: currency.format(provider.cashInHand),
                      icon: Icons.wallet,
                      color: AppTheme.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChannelCard(
                      title: 'Bank & UPI',
                      amount: currency.format(provider.bankUpiBalance),
                      icon: Icons.account_balance,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // 2. Bar Chart
            DailyBarChartWidget(cashflows: provider.dailyCashflows),
            const SizedBox(height: 24),

            // 3. Collector Leaderboard
            const Text(
              'Top Chanda Collectors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            if (provider.books.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No chanda books found for this event',
                    style: TextStyle(color: Colors.white.withAlpha(140)),
                  ),
                ),
              )
            else if (isDesktop)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: screenWidth > 1600 ? 3 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 80,
                ),
                itemCount: provider.books.length,
                itemBuilder: (context, index) => _buildCollectorTile(provider.books[index], currency),
              )
            else
              ...provider.books.map((book) => _buildCollectorTile(book, currency)),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectorTile(ChandaBook book, NumberFormat currency) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${book.bookNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(book.assignedTo, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text(
                  '${book.usedSlips} slips issued • ${(book.usedSlips / (book.totalSlips > 0 ? book.totalSlips : 1) * 100).toInt()}% completed',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
                ),
              ],
            ),
          ),
          Text(
            currency.format(book.totalCollected),
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.successGreenLight, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160))),
          const SizedBox(height: 4),
          Text(amount, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
