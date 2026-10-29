import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/puja_provider.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_breakdown_chart.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/hero_balance_card.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/update_dialog.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);

    return ResponsiveLayout(
      mobile: _buildMobileDashboard(context, provider),
      desktop: _buildDesktopDashboard(context, provider),
    );
  }

  Widget _buildMobileDashboard(BuildContext context, PujaProvider provider) {
    final activeEvent = provider.selectedEvent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Info
          _buildAppHeader(context, provider),
          const SizedBox(height: 16),

          // Over-budget Alert Banner
          if (provider.overBudgetCategories.isNotEmpty) ...[
            _buildOverBudgetBanner(context, provider),
            const SizedBox(height: 16),
          ],

          // 1. Hero Balance Card (Matching Reference UI top card)
          HeroBalanceCard(
            netBalance: provider.netBalance,
            todaysCollection: provider.todaysCollection,
            totalIncome: provider.totalIncome,
            totalExpense: provider.totalExpense,
            eventName: activeEvent != null ? '${activeEvent.name} ${activeEvent.year}' : 'All Festivals',
            onAddChanda: () => showDialog(
              context: context,
              builder: (_) => AddCollectionAccountDialog(initialEventId: activeEvent?.id),
            ),
            onAddExpense: () => showDialog(
              context: context,
              builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent?.id),
            ),
            onGiveAdvance: () => showDialog(
              context: context,
              builder: (_) => GiveAdvanceDialog(initialEventId: activeEvent?.id),
            ),
            onViewReport: () => onNavigateTab?.call(4),
          ),
          const SizedBox(height: 18),

          // 2. Donut Breakdown Chart
          CircularBreakdownChart(
            totalIncome: provider.totalIncome,
            totalExpense: provider.totalExpense,
            categoryBreakdown: provider.expenseByCategory,
          ),
          const SizedBox(height: 18),

          // 3. Cash vs Bank Quick Indicator
          _buildCashAndBankRow(provider),
          const SizedBox(height: 18),

          // 4. Daily Bar Chart
          DailyBarChartWidget(cashflows: provider.dailyCashflows),
          const SizedBox(height: 22),

          // 5. Recent Activity List
          _buildRecentActivitySection(context, provider),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard(BuildContext context, PujaProvider provider) {
    final activeEvent = provider.selectedEvent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(context, provider, isDesktop: true),
          const SizedBox(height: 24),

          // Over-budget Alert Banner
          if (provider.overBudgetCategories.isNotEmpty) ...[
            _buildOverBudgetBanner(context, provider),
            const SizedBox(height: 20),
          ],

          // Desktop Top 2-Column Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Hero Card + Daily Bar Chart)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    HeroBalanceCard(
                      netBalance: provider.netBalance,
                      todaysCollection: provider.todaysCollection,
                      totalIncome: provider.totalIncome,
                      totalExpense: provider.totalExpense,
                      eventName: activeEvent != null ? '${activeEvent.name} ${activeEvent.year}' : 'All Festivals',
                      onAddChanda: () => showDialog(
                        context: context,
                        builder: (_) => AddCollectionAccountDialog(initialEventId: activeEvent?.id),
                      ),
                      onAddExpense: () => showDialog(
                        context: context,
                        builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent?.id),
                      ),
                      onGiveAdvance: () => showDialog(
                        context: context,
                        builder: (_) => GiveAdvanceDialog(initialEventId: activeEvent?.id),
                      ),
                      onViewReport: () => onNavigateTab?.call(4),
                    ),
                    const SizedBox(height: 20),
                    DailyBarChartWidget(cashflows: provider.dailyCashflows),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right Column (Donut Chart + Cash/Bank Pill + Quick Actions)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    CircularBreakdownChart(
                      totalIncome: provider.totalIncome,
                      totalExpense: provider.totalExpense,
                      categoryBreakdown: provider.expenseByCategory,
                    ),
                    const SizedBox(height: 20),
                    _buildCashAndBankRow(provider),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Bottom Wide Activity Feed
          _buildRecentActivitySection(context, provider, isDesktop: true),
        ],
      ),
    );
  }

  Widget _buildOverBudgetBanner(BuildContext context, PujaProvider provider) {
    final overCats = provider.overBudgetCategories;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final overAmount = overCats.fold<double>(
      0.0,
      (sum, cat) => sum + ((provider.expenseByCategory[cat] ?? 0) - provider.budgetFor(cat)),
    );

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: AppTheme.dangerRose.withAlpha(120), width: 1.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => onNavigateTab?.call(4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.dangerRose.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRose, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Budget Limit Exceeded!',
                    style: TextStyle(
                      color: AppTheme.dangerRose,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${overCats.map((c) => c.displayName).join(', ')} — ${currency.format(overAmount)} over budget',
                    style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.dangerRose),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context, PujaProvider provider, {bool isDesktop = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Custom App Logo with fallback
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldAccent.withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF14274E),
                      alignment: Alignment.center,
                      child: const Icon(Icons.festival_rounded, color: AppTheme.goldAccent, size: 24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.pujaName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: isDesktop ? 22 : 17,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Cashier Desk • ${provider.cashierName}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (auth.isAuthenticated) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const EditCommitteeSettingsDialog(initialTab: 1),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: auth.isGoogleUser ? const Color(0x664285F4) : AppTheme.glassBorder,
                          width: 1.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: auth.isGoogleUser ? const Color(0x2E4285F4) : AppTheme.primaryBlue,
                        backgroundImage: auth.photoUrl != null && auth.photoUrl!.isNotEmpty
                            ? NetworkImage(auth.photoUrl!)
                            : null,
                        child: auth.photoUrl == null || auth.photoUrl!.isEmpty
                            ? Text(
                                auth.displayName.isNotEmpty ? auth.displayName[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  color: auth.isGoogleUser ? const Color(0xFF8AB4F8) : const Color(0xFF070D1E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Consumer<UpdateProvider>(
                  builder: (context, updateProv, _) {
                    final hasUpdate = updateProv.hasUpdateAvailable;
                    return IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: hasUpdate ? 'Update Available!' : 'Check for Updates',
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: hasUpdate ? AppTheme.goldAccent.withAlpha(30) : const Color(0x1F1E293B),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasUpdate ? AppTheme.goldAccent.withAlpha(120) : AppTheme.glassBorder,
                            width: hasUpdate ? 1.4 : 1.0,
                          ),
                        ),
                        child: Icon(
                          hasUpdate ? Icons.new_releases_rounded : Icons.system_update_rounded,
                          color: hasUpdate ? AppTheme.goldAccent : AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      onPressed: () => AppUpdateDialog.show(context),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Committee Settings',
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: const Icon(Icons.settings_outlined, color: AppTheme.primaryBlue, size: 20),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const EditCommitteeSettingsDialog(initialTab: 0),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCashAndBankRow(PujaProvider provider) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wallet, color: AppTheme.goldAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cash in Hand',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(provider.cashInHand),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance, color: AppTheme.primaryBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bank / UPI QR',
                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currency.format(provider.bankUpiBalance),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, PujaProvider provider, {bool isDesktop = false}) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final count = isDesktop ? 8 : 5;
    final activityLogs = provider.activityLogs.take(count).toList();
    final recentSlips = provider.recentSlips.take(count).toList(growable: false);
    final recentExpenses = provider.recentExpenses.take(count).toList(growable: false);

    final hasData = activityLogs.isNotEmpty || recentSlips.isNotEmpty || recentExpenses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: AppTheme.goldAccent),
                SizedBox(width: 8),
                Text(
                  'Recent Activity & Audit Trail',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasData)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppTheme.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Live Feed',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.successGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onNavigateTab?.call(3), // Navigate to History Screen (Tab 3)
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Full History',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppTheme.primaryBlue),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (!hasData) ...[
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.white.withAlpha(80)),
                const SizedBox(height: 10),
                const Text(
                  'No recent activity recorded yet.',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'All modifications to Collections, Dues, Advances, and Accounts are automatically tracked here.',
                  style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ] else if (activityLogs.isNotEmpty) ...[
          // Show Systematic Audit Activity Cards
          ...activityLogs.map((log) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xF50A1128),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: log.color.withAlpha(50), width: 1.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: log.color.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: log.color.withAlpha(80)),
                    ),
                    child: Icon(log.icon, color: log.color, size: 18),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                log.title,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: log.actionType.color.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: log.actionType.color.withAlpha(80), width: 0.8),
                              ),
                              child: Text(
                                log.actionType.displayName.toUpperCase(),
                                style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: log.actionType.color),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              log.timeAgo,
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          log.description,
                          style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(180), height: 1.3),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Amount (if applicable)
                  if (log.amount != null && log.amount! > 0) ...[
                    const SizedBox(width: 10),
                    Text(
                      currency.format(log.amount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: log.actionType == ActivityActionType.delete || log.module == ActivityModule.expense
                            ? AppTheme.dangerRose
                            : AppTheme.successGreen,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ] else ...[
          // Fallback if logs are not yet generated
          ...recentSlips.map((slip) {
            final collector = slip.collectedBy.trim().isNotEmpty ? slip.collectedBy : 'Cashier';
            return TransactionTile(
              title: slip.donorName,
              subtitle: 'Book #${slip.bookNumber} • $collector',
              amount: slip.amount,
              isIncome: true,
              paymentMode: slip.paymentMode,
              date: slip.createdAt,
              tag: slip.dayLabel ?? 'Collection',
              onTap: () => showDialog(
                context: context,
                builder: (_) => SlipReceiptActionDialog(slip: slip),
              ),
            );
          }),
          ...recentExpenses.map((exp) {
            return TransactionTile(
              title: exp.payeeName,
              subtitle: '${exp.category.displayName} • Voucher #${exp.voucherNo}',
              amount: exp.amount,
              isIncome: false,
              paymentMode: exp.paymentMode,
              date: exp.date,
              tag: 'Expense',
              onTap: () => showDialog(
                context: context,
                builder: (_) => AddExpenseDialog(existing: exp),
              ),
            );
          }),
        ],
      ],
    );
  }
}
