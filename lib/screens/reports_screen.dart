import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedTab = 0; // 0: Balance Sheet, 1: Booklets Audit, 2: Expense Breakdown, 3: Member Advances, 4: In-Kind

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  final _dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');

  void _openPdfExportDialog(PujaProvider provider, {bool initialAllEvents = true}) {
    showDialog(
      context: context,
      builder: (_) => ReportExportDialog(
        initialEvent: provider.selectedEvent,
        initialAllEvents: initialAllEvents,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 16, 20, isDesktop ? 28 : 16, isDesktop ? 24 : 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Area with Direct PDF Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Financial Audit & Reports',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Executive balance sheet & PDF statements',
                        style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(150)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share PDF Button
                    IconButton(
                      tooltip: 'Share / Export PDF Statement',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x1F1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.glassBorder),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                      onPressed: () => _openPdfExportDialog(provider),
                    ),
                    const SizedBox(width: 6),
                    // Print / Save PDF Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Export PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () => _openPdfExportDialog(provider),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Executive Metrics Cards (Desktop: 1 Row of 4 cards; Mobile: 2x2 Grid)
            if (isDesktop)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Inflow (Collections)',
                      amount: _currency.format(provider.totalIncome),
                      icon: Icons.trending_up,
                      color: AppTheme.successGreenLight,
                      badge: 'A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Expenditure (Outflow)',
                      amount: _currency.format(provider.totalExpense),
                      icon: Icons.trending_down,
                      color: AppTheme.dangerRose,
                      badge: 'B',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Net Surplus (A - B)',
                      amount: _currency.format(provider.netBalance),
                      icon: Icons.savings_outlined,
                      color: AppTheme.goldAccent,
                      badge: 'Closing',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending Advances',
                      amount: _currency.format(provider.totalPendingAdvance),
                      icon: Icons.wallet_outlined,
                      color: const Color(0xFF38BDF8),
                      badge: '${provider.advances.where((a) => a.status == 'Pending').length} pending',
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Inflow (Collections)',
                      amount: _currency.format(provider.totalIncome),
                      icon: Icons.trending_up,
                      color: AppTheme.successGreenLight,
                      badge: 'A',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Total Expenditure (Outflow)',
                      amount: _currency.format(provider.totalExpense),
                      icon: Icons.trending_down,
                      color: AppTheme.dangerRose,
                      badge: 'B',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Net Surplus (A - B)',
                      amount: _currency.format(provider.netBalance),
                      icon: Icons.savings_outlined,
                      color: AppTheme.goldAccent,
                      badge: 'Closing',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Pending Advances',
                      amount: _currency.format(provider.totalPendingAdvance),
                      icon: Icons.wallet_outlined,
                      color: const Color(0xFF38BDF8),
                      badge: '${provider.advances.where((a) => a.status == 'Pending').length} pending',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // 3. Tab Switcher (Responsive Wrap on Desktop, Scroll on Mobile)
            if (isDesktop)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTabChip(0, 'Balance Sheet', Icons.account_balance),
                  _buildTabChip(1, 'Booklets Audit', Icons.menu_book),
                  _buildTabChip(2, 'Expense Breakdown', Icons.pie_chart_outline),
                  _buildTabChip(3, 'Advances & Contracts', Icons.wallet),
                  _buildTabChip(4, 'In-Kind Donations', Icons.inventory_2_outlined),
                ],
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabChip(0, 'Balance Sheet', Icons.account_balance),
                    const SizedBox(width: 8),
                    _buildTabChip(1, 'Booklets Audit', Icons.menu_book),
                    const SizedBox(width: 8),
                    _buildTabChip(2, 'Expense Breakdown', Icons.pie_chart_outline),
                    const SizedBox(width: 8),
                    _buildTabChip(3, 'Advances & Contracts', Icons.wallet),
                    const SizedBox(width: 8),
                    _buildTabChip(4, 'In-Kind Donations', Icons.inventory_2_outlined),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 4. Tab Views
            if (_selectedTab == 0) _buildBalanceSheetView(provider),
            if (_selectedTab == 1) _buildBookletsAuditView(provider, isDesktop: isDesktop, screenWidth: screenWidth),
            if (_selectedTab == 2) _buildExpenseBreakdownView(provider, isDesktop: isDesktop, screenWidth: screenWidth),
            if (_selectedTab == 3) _buildMemberAdvancesView(provider, isDesktop: isDesktop, screenWidth: screenWidth),
            if (_selectedTab == 4) _buildInKindDonationsReportView(provider, isDesktop: isDesktop, screenWidth: screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String badge,
  }) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: color.withAlpha(50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primaryBlue : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: OFFICIAL BALANCE SHEET VIEW
  // ==========================================
  Widget _buildBalanceSheetView(PujaProvider provider) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          border: Border.all(color: AppTheme.glassBorderLight, width: 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.festival, color: AppTheme.goldAccent, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      provider.pujaName.toUpperCase(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.6),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Income & Expenditure Statement for ${provider.currentYear}',
                      style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(160)),
                    ),
                    Text(
                      'Generated: ${_dateFormat.format(DateTime.now())}',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue.withAlpha(200)),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.glassBorder, height: 32),

              // Inflow Section
              _buildSectionHeader('A. TOTAL INFLOW / COLLECTIONS', AppTheme.successGreenLight),
              const SizedBox(height: 10),
              ...provider.books.map((b) => _buildRow('Chanda Book #${b.bookNumber} (${b.assignedTo})', b.totalCollected)),
              const Divider(color: AppTheme.glassBorder, height: 20),
              _buildTotalRow('TOTAL COLLECTION (A)', provider.totalIncome, AppTheme.successGreenLight),

              const SizedBox(height: 24),

              // Expenses Section
              _buildSectionHeader('B. TOTAL EXPENDITURE / EXPENSES', AppTheme.dangerRose),
              const SizedBox(height: 10),
              ...provider.expenseByCategory.entries.where((e) => e.value > 0).map(
                    (entry) => _buildRow(entry.key.displayName, entry.value),
                  ),
              const Divider(color: AppTheme.glassBorder, height: 20),
              _buildTotalRow('TOTAL EXPENDITURE (B)', provider.totalExpense, AppTheme.dangerRose),

              const SizedBox(height: 24),

              // Closing Balance
              _buildSectionHeader('C. CLOSING BALANCE IN HAND', AppTheme.primaryBlue),
              const SizedBox(height: 10),
              _buildRow('Physical Cash In Hand (With Cashier)', provider.cashInHand),
              _buildRow('Bank Account / UPI Balance', provider.bankUpiBalance),
              const Divider(color: AppTheme.glassBorder, height: 20),
              _buildTotalRow('NET SURPLUS (A - B)', provider.netBalance, AppTheme.goldAccent),

              const SizedBox(height: 32),

              // Signatures
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSignatory('President', provider.presidentName),
                  _buildSignatory('Secretary', provider.secretaryName),
                  _buildSignatory('Cashier / Treasurer', provider.cashierName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: BOOKLETS AUDIT VIEW
  // ==========================================
  Widget _buildBookletsAuditView(PujaProvider provider, {bool isDesktop = false, double screenWidth = 1200}) {
    if (provider.books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No chanda booklets registered yet.', style: TextStyle(color: Colors.white.withAlpha(140))),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1500 ? 3 : 2,
          childAspectRatio: 2.8,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: provider.books.length,
        itemBuilder: (context, index) => _buildBookletAuditCard(provider.books[index]),
      );
    }

    return Column(
      children: provider.books.map((b) => _buildBookletAuditCard(b)).toList(),
    );
  }

  Widget _buildBookletAuditCard(ChandaBook b) {
    final progress = b.totalSlips > 0 ? (b.usedSlips / b.totalSlips) : 0.0;
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      border: Border.all(color: AppTheme.glassBorder),
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
                    child: const Icon(Icons.bookmark, color: AppTheme.primaryBlue, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book #${b.bookNumber} • ${b.assignedTo}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Slips #${b.startSlip} to #${b.endSlip} (${b.totalSlips} total)',
                        style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _currency.format(b.totalCollected),
                style: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0x1F1E293B),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${b.usedSlips} of ${b.totalSlips} slips issued (${(progress * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
              ),
              Text(
                'Status: ${b.status}',
                style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: EXPENSE BREAKDOWN VIEW (Budget vs Actual)
  // ==========================================
  Widget _buildExpenseBreakdownView(PujaProvider provider, {bool isDesktop = false, double screenWidth = 1200}) {
    final activeCategories = provider.expenseByCategory.entries.where((e) => e.value > 0).toList();
    final hasAnyBudget = provider.totalBudget > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasAnyBudget)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(14),
              border: Border.all(color: AppTheme.goldAccent.withAlpha(80)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.goldAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: Set category-wise budgets in Committee Settings to view real-time Budget vs Actual analysis here.',
                      style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(180), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (isDesktop)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 1500 ? 3 : 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: activeCategories.length,
            itemBuilder: (context, index) => _buildExpenseCategoryCard(activeCategories[index], provider),
          )
        else
          ...activeCategories.map((entry) => _buildExpenseCategoryCard(entry, provider)),
      ],
    );
  }

  Widget _buildExpenseCategoryCard(MapEntry<ExpenseCategory, double> entry, PujaProvider provider) {
    final cat = entry.key;
    final amount = entry.value;
    final pct = provider.totalExpense > 0 ? (amount / provider.totalExpense) * 100 : 0.0;
    final budget = provider.budgetFor(cat);
    final hasBudget = budget > 0;
    final usage = amount / budget;
    final isOver = hasBudget && amount > budget;

    final Color barColor;
    if (!hasBudget) {
      barColor = cat.color;
    } else if (isOver) {
      barColor = AppTheme.dangerRose;
    } else if (usage >= 0.7) {
      barColor = AppTheme.goldAccent;
    } else {
      barColor = AppTheme.successGreenLight;
    }

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      border: Border.all(
        color: isOver ? AppTheme.dangerRose.withAlpha(110) : cat.color.withAlpha(60),
        width: isOver ? 1.4 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.displayName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            hasBudget
                                ? 'Budget ${_currency.format(budget)} • ${pct.toStringAsFixed(1)}% of total'
                                : '${pct.toStringAsFixed(1)}% of total expenses',
                            style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency.format(amount),
                    style: TextStyle(
                      color: isOver ? AppTheme.dangerRose : cat.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (isOver)
                    Text(
                      'Over by ${_currency.format(amount - budget)}',
                      style: const TextStyle(color: AppTheme.dangerRose, fontSize: 10, fontWeight: FontWeight.w600),
                    )
                  else if (hasBudget)
                    Text(
                      '${_currency.format(budget - amount)} left',
                      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hasBudget ? usage.clamp(0.0, 1.0) : pct / 100,
              minHeight: 6,
              backgroundColor: const Color(0x1F1E293B),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          if (hasBudget) ...[
            const SizedBox(height: 6),
            Text(
              '${usage <= 1 ? (usage * 100).toStringAsFixed(0) : '>100'}% of allocated budget used${isOver ? ' ⚠️' : ''}',
              style: TextStyle(
                color: isOver ? AppTheme.dangerRose : Colors.white.withAlpha(150),
                fontSize: 10.5,
                fontWeight: isOver ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: MEMBER ADVANCES & SETTLEMENTS VIEW
  // ==========================================
  Widget _buildMemberAdvancesView(PujaProvider provider, {bool isDesktop = false, double screenWidth = 1200}) {
    if (provider.advances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No advance records found.', style: TextStyle(color: Colors.white.withAlpha(140))),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: screenWidth > 1500 ? 3 : 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: provider.advances.length,
        itemBuilder: (context, index) => _buildAdvanceReportCard(provider.advances[index]),
      );
    }

    return Column(
      children: provider.advances.map((adv) => _buildAdvanceReportCard(adv)).toList(),
    );
  }

  Widget _buildAdvanceReportCard(MemberAdvance adv) {
    final isPending = adv.status == 'Pending';
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AdvanceActionDialog(advance: adv),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        border: Border.all(color: isPending ? AppTheme.goldAccent.withAlpha(80) : AppTheme.glassBorder),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  adv.memberName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPending ? AppTheme.goldAccent.withAlpha(25) : AppTheme.successGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    adv.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPending ? AppTheme.goldAccent : AppTheme.successGreenLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Purpose: ${adv.purpose}',
              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Advance: ${_currency.format(adv.advanceAmount)}',
                  style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (adv.actualSpent != null)
                  Text(
                    'Spent: ${_currency.format(adv.actualSpent!)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                if ((adv.returnAmount ?? 0) > 0)
                  Text(
                    'Refund: +${_currency.format(adv.returnAmount!)}',
                    style: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
              ],
            ),
            if (adv.hasContract) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Deal: ${_currency.format(adv.effectiveOriginalAmount)}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
                    ),
                    Text(
                      adv.remainingDue > 0
                          ? 'Due: ${_currency.format(adv.remainingDue)}'
                          : 'Fully Paid (100%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: adv.remainingDue > 0 ? const Color(0xFFFF7B92) : AppTheme.successGreenLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: IN-KIND / SAMAGRI DONATIONS REPORT
  // ==========================================
  Widget _buildInKindDonationsReportView(PujaProvider provider, {bool isDesktop = false, double screenWidth = 0}) {
    if (provider.inKindDonations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'No in-kind donations recorded yet.',
                style: TextStyle(color: Colors.white.withAlpha(140)),
              ),
            ],
          ),
        ),
      );
    }

    final inKindGridCols = screenWidth > 1400 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Glass Card
        GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL IN-KIND CONTRIBUTIONS',
                    style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.inKindDonations.length} Items Donated',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              if (provider.totalEstimatedInKindValue > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ESTIMATED VALUE',
                      style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currency.format(provider.totalEstimatedInKindValue),
                      style: const TextStyle(color: AppTheme.goldAccent, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('MATERIAL & IN-KIND REGISTER', const Color(0xFF10B981)),
        const SizedBox(height: 10),

        if (isDesktop)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: inKindGridCols,
              crossAxisSpacing: 14,
              mainAxisSpacing: 12,
              mainAxisExtent: 115,
            ),
            itemCount: provider.inKindDonations.length,
            itemBuilder: (context, index) => _buildInKindCard(provider.inKindDonations[index]),
          )
        else
          ...provider.inKindDonations.map((item) => _buildInKindCard(item)),
      ],
    );
  }

  Widget _buildInKindCard(InKindDonation item) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => InKindActionDialog(item: item),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        border: Border.all(color: item.category.color.withAlpha(60)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.category.color.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.category.icon, color: item.category.color, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.itemName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Donor: ${item.donorName}',
                              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11.5),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.category.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.quantity,
                    style: TextStyle(color: item.category.color, fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Received by: ${item.receivedBy} • ${DateFormat('dd MMM yyyy').format(item.date)}',
                  style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11),
                ),
                if (item.estimatedValue != null && item.estimatedValue! > 0)
                  Text(
                    _currency.format(item.estimatedValue!),
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
              ],
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${item.notes}',
                style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 11, fontStyle: FontStyle.italic),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
    );
  }

  Widget _buildRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.white.withAlpha(200)),
            ),
          ),
          Text(
            _currency.format(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          _currency.format(amount),
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
        ),
      ],
    );
  }

  Widget _buildSignatory(String title, String name) {
    return Column(
      children: [
        Container(width: 80, height: 1, color: Colors.white30),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(title, style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140))),
      ],
    );
  }
}
