import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/advance_account_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/transaction_tile.dart';

class _DateExpenseGroup {
  final String dateKey;
  final DateTime date;
  final List<ExpenseVoucher> vouchers;
  final double totalAmount;

  _DateExpenseGroup({
    required this.dateKey,
    required this.date,
    required this.vouchers,
    required this.totalAmount,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  int _selectedTab = 0; // 0: Vouchers, 1: Member Advances
  ExpenseCategory? _selectedCategory;
  String _searchQuery = '';
  String _sortOption = 'newest'; // 'newest', 'oldest', 'highest', 'lowest', 'payee'
  PaymentMode? _paymentModeFilter; // null for all, or cash, upi, bankTransfer
  bool _isGroupedByDate = true;
  String _advanceStatusFilter = 'All'; // 'All', 'Pending', 'Settled'

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'oldest':
        return 'Oldest';
      case 'highest':
        return 'Highest';
      case 'lowest':
        return 'Lowest';
      case 'payee':
        return 'Payee A-Z';
      case 'newest':
      default:
        return 'Newest';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final activeEvent = provider.selectedEvent;
    final events = provider.events;

    final activeExpenses = provider.activeEventExpenses;
    final activeAdvances = provider.activeEventAdvances;

    // Financial KPI Totals for Active Event
    final totalCashSpent = activeExpenses
        .where((e) => e.paymentMode == PaymentMode.cash)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalOnlineSpent = activeExpenses
        .where((e) => e.paymentMode == PaymentMode.upi || e.paymentMode == PaymentMode.bankTransfer)
        .fold(0.0, (sum, e) => sum + e.amount);
    final totalPendingAdvance = activeAdvances
        .where((a) => a.status == 'Pending')
        .fold(0.0, (sum, a) => sum + a.advanceAmount);
    final pendingCount = activeAdvances.where((a) => a.status == 'Pending').length;
    final settledCount = activeAdvances.where((a) => a.status != 'Pending').length;
    final totalSettledAdvance = activeAdvances
        .where((a) => a.status != 'Pending')
        .fold(0.0, (sum, a) => sum + (a.actualSpent ?? a.advanceAmount));

    // Filter & Sort Expenses
    final filteredExpenses = activeExpenses.where((e) {
      final matchesCategory = _selectedCategory == null || e.category == _selectedCategory;
      final matchesPaymentMode = _paymentModeFilter == null ||
          (_paymentModeFilter == PaymentMode.upi
              ? (e.paymentMode == PaymentMode.upi || e.paymentMode == PaymentMode.bankTransfer)
              : e.paymentMode == _paymentModeFilter);
      final matchesSearch = _searchQuery.isEmpty ||
          e.payeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.voucherNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return matchesCategory && matchesPaymentMode && matchesSearch;
    }).toList();

    switch (_sortOption) {
      case 'oldest':
        filteredExpenses.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'highest':
        filteredExpenses.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'lowest':
        filteredExpenses.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      case 'payee':
        filteredExpenses.sort((a, b) => a.payeeName.toLowerCase().compareTo(b.payeeName.toLowerCase()));
        break;
      case 'newest':
      default:
        filteredExpenses.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    // Date grouping for vouchers
    final Map<String, List<ExpenseVoucher>> groupedMap = {};
    final dateKeyFormat = DateFormat('yyyy-MM-dd');
    for (final exp in filteredExpenses) {
      final key = dateKeyFormat.format(exp.date);
      groupedMap.putIfAbsent(key, () => []).add(exp);
    }

    final List<_DateExpenseGroup> dateGroups = groupedMap.entries.map((entry) {
      final vouchers = entry.value;
      final total = vouchers.fold(0.0, (sum, e) => sum + e.amount);
      return _DateExpenseGroup(
        dateKey: entry.key,
        date: vouchers.first.date,
        vouchers: vouchers,
        totalAmount: total,
      );
    }).toList();

    // Filter Advances
    final filteredAdvances = activeAdvances.where((a) {
      final matchesStatus = _advanceStatusFilter == 'All' ||
          (_advanceStatusFilter == 'Pending' && a.status == 'Pending') ||
          (_advanceStatusFilter == 'Settled' && a.status != 'Pending');
      final matchesSearch = _searchQuery.isEmpty ||
          a.memberName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.purpose.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    filteredAdvances.sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // Header Area
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Expenses & Advances',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          activeEvent != null
                              ? '${activeEvent.name} (${activeEvent.year}) • Spent: ${currency.format(provider.eventTotalExpense)}'
                              : 'Spent: ${currency.format(provider.totalExpense)} • Advances: ${currency.format(provider.totalPendingAdvance)}',
                          style: const TextStyle(fontSize: 12.5, color: AppTheme.dangerRose, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD97706), // Amber 600
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.wallet_rounded, size: 15, color: Colors.white),
                      label: const Text(
                        'Give Advance',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => GiveAdvanceDialog(initialEventId: activeEvent?.id),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Event Switcher Horizontal Bar
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: events.length + 1,
                itemBuilder: (context, index) {
                  if (index == events.length) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
                      child: ActionChip(
                        avatar: const Icon(Icons.add, size: 14, color: AppTheme.dangerRose),
                        label: const Text('Add Event',
                            style: TextStyle(fontSize: 11, color: AppTheme.dangerRose, fontWeight: FontWeight.bold)),
                        backgroundColor: const Color(0x1F1E293B),
                        side: const BorderSide(color: AppTheme.glassBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const CreateEditEventDialog(),
                        ),
                      ),
                    );
                  }

                  final evt = events[index];
                  final isSelected = activeEvent?.id == evt.id;

                  return Container(
                    margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
                    child: GestureDetector(
                      onTap: () => provider.selectEvent(evt.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [Color(0xFF881337), Color(0xFFE11D48)],
                                )
                              : null,
                          color: isSelected ? null : const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.dangerRose : AppTheme.glassBorder,
                            width: isSelected ? 1.4 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.dangerRose.withAlpha(50),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.festival_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : AppTheme.dangerRose,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${evt.name} (${evt.year})',
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Active Event Overview Glass Card
          if (activeEvent != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                child: GlassContainer(
                  borderRadius: 22,
                  padding: const EdgeInsets.all(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x3D1E293B),
                      Color(0x1F334155),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.dangerRose.withAlpha(70),
                    width: 1.2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Event Name & Net Balance Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRose.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.festival_rounded, color: AppTheme.dangerRose, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${activeEvent.name} (${activeEvent.year})',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Total Spent: ${currency.format(provider.eventTotalExpense)}',
                                        style: const TextStyle(fontSize: 11, color: AppTheme.dangerRose, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: provider.eventNetBalance >= 0
                                  ? AppTheme.successGreen.withAlpha(30)
                                  : AppTheme.dangerRose.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: provider.eventNetBalance >= 0
                                    ? AppTheme.successGreen.withAlpha(90)
                                    : AppTheme.dangerRose.withAlpha(90),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.eventNetBalance >= 0 ? Icons.trending_up : Icons.trending_down,
                                  size: 13,
                                  color: provider.eventNetBalance >= 0 ? AppTheme.successGreenLight : AppTheme.dangerRose,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Net ${currency.format(provider.eventNetBalance)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: provider.eventNetBalance >= 0 ? AppTheme.successGreenLight : AppTheme.dangerRose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Budget Utilization Bar if targetBudget set
                      if (activeEvent.targetBudget != null && activeEvent.targetBudget! > 0) ...[
                        const SizedBox(height: 12),
                        Builder(builder: (_) {
                          final budget = activeEvent.targetBudget!;
                          final spent = provider.eventTotalExpense;
                          final progress = (spent / budget).clamp(0.0, 1.0);
                          final isOver = spent > budget;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Budget Utilization (${(progress * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.white.withAlpha(180)),
                                  ),
                                  Text(
                                    '${currency.format(spent)} / ${currency.format(budget)}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: isOver ? AppTheme.dangerRose : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 6,
                                  backgroundColor: const Color(0x331E293B),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOver ? AppTheme.dangerRose : (progress > 0.85 ? Colors.amber : const Color(0xFF10B981)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Action Buttons under Event Section (+ Add Voucher, + Give Advance)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text(
                        '+ Add Voucher',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddExpenseDialog(
                          initialEventId: activeEvent?.id ?? provider.selectedEvent?.id,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0x1F1E293B),
                        foregroundColor: AppTheme.goldAccent,
                        side: const BorderSide(color: AppTheme.goldAccent, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.wallet_rounded, size: 18, color: AppTheme.goldAccent),
                      label: const Text(
                        '+ Give Advance',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => GiveAdvanceDialog(
                          initialEventId: activeEvent?.id ?? provider.selectedEvent?.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Financial KPI Metric Row (Cash Spent, Online/UPI, Pending Advances)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
              child: isDesktop
                  ? Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'Cash Outflow',
                            amount: currency.format(totalCashSpent),
                            subtitle: 'Physical Cash',
                            icon: Icons.payments_rounded,
                            color: AppTheme.goldAccent,
                            isSelected: _paymentModeFilter == PaymentMode.cash,
                            onTap: () {
                              setState(() {
                                _paymentModeFilter = _paymentModeFilter == PaymentMode.cash ? null : PaymentMode.cash;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'UPI & Bank Transfer',
                            amount: currency.format(totalOnlineSpent),
                            subtitle: 'Digital Account',
                            icon: Icons.account_balance_rounded,
                            color: AppTheme.primaryBlue,
                            isSelected: _paymentModeFilter == PaymentMode.upi,
                            onTap: () {
                              setState(() {
                                _paymentModeFilter = (_paymentModeFilter == PaymentMode.upi || _paymentModeFilter == PaymentMode.bankTransfer)
                                    ? null
                                    : PaymentMode.upi;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'Pending Advances',
                            amount: currency.format(totalPendingAdvance),
                            subtitle: '$pendingCount members baki',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFFB7185),
                            isSelected: _selectedTab == 1 && _advanceStatusFilter == 'Pending',
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                                _advanceStatusFilter = 'Pending';
                              });
                            },
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'Cash Out',
                            amount: currency.format(totalCashSpent),
                            subtitle: 'Box',
                            icon: Icons.payments_rounded,
                            color: AppTheme.goldAccent,
                            isSelected: _paymentModeFilter == PaymentMode.cash,
                            onTap: () {
                              setState(() {
                                _paymentModeFilter = _paymentModeFilter == PaymentMode.cash ? null : PaymentMode.cash;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'Online/UPI',
                            amount: currency.format(totalOnlineSpent),
                            subtitle: 'Bank',
                            icon: Icons.account_balance_rounded,
                            color: AppTheme.primaryBlue,
                            isSelected: _paymentModeFilter == PaymentMode.upi,
                            onTap: () {
                              setState(() {
                                _paymentModeFilter = (_paymentModeFilter == PaymentMode.upi || _paymentModeFilter == PaymentMode.bankTransfer)
                                    ? null
                                    : PaymentMode.upi;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildKpiCard(
                            context: context,
                            title: 'Advances',
                            amount: currency.format(totalPendingAdvance),
                            subtitle: '$pendingCount Unsettled',
                            icon: Icons.hourglass_top_rounded,
                            color: const Color(0xFFFB7185),
                            isSelected: _selectedTab == 1 && _advanceStatusFilter == 'Pending',
                            onTap: () {
                              setState(() {
                                _selectedTab = 1;
                                _advanceStatusFilter = 'Pending';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          // Tab Switcher (Direct Vouchers vs Member Advances)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? AppTheme.dangerRose.withAlpha(40) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedTab == 0 ? AppTheme.dangerRose : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Expense Vouchers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0 ? AppTheme.dangerRose : Colors.white.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${activeExpenses.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? AppTheme.goldAccent.withAlpha(40) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedTab == 1 ? AppTheme.goldAccent : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Advances & Contracts',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (pendingCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Color(0xFF070D1E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Chips Bar with Live Spent Amounts (Only in Vouchers Tab)
          if (_selectedTab == 0) ...[
            SliverToBoxAdapter(
              child: isDesktop
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryChip(
                            null,
                            'All Categories',
                            Icons.apps,
                            amount: activeExpenses.fold(0.0, (s, e) => s + e.amount),
                          ),
                          ...ExpenseCategory.values.map(
                            (cat) {
                              final catList = activeExpenses.where((e) => e.category == cat);
                              final catTotal = catList.fold(0.0, (s, e) => s + e.amount);
                              return _buildCategoryChip(
                                cat,
                                cat.displayName,
                                cat.icon,
                                color: cat.color,
                                amount: catTotal,
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 46,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildCategoryChip(
                            null,
                            'All Categories',
                            Icons.apps,
                            amount: activeExpenses.fold(0.0, (s, e) => s + e.amount),
                          ),
                          ...ExpenseCategory.values.map(
                            (cat) {
                              final catList = activeExpenses.where((e) => e.category == cat);
                              final catTotal = catList.fold(0.0, (s, e) => s + e.amount);
                              return _buildCategoryChip(
                                cat,
                                cat.displayName,
                                cat.icon,
                                color: cat.color,
                                amount: catTotal,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ],

          // Search & Filter Toolbar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: _selectedTab == 0
                          ? 'Search vendor, voucher #, purpose...'
                          : 'Search member name or advance purpose...',
                      hintStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 13),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _selectedTab == 0 ? AppTheme.dangerRose : AppTheme.goldAccent,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.white70),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xD9081022),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _selectedTab == 0 ? AppTheme.dangerRose : AppTheme.goldAccent,
                        ),
                      ),
                    ),
                  ),

                  // Tab 0 Toolbar: Payment Mode Filter Chips + Sort Menu + Grouping Toggle
                  if (_selectedTab == 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildMiniFilterChip(
                                  label: 'All Modes',
                                  isSelected: _paymentModeFilter == null,
                                  onTap: () => setState(() => _paymentModeFilter = null),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniFilterChip(
                                  label: '💵 Cash Only',
                                  isSelected: _paymentModeFilter == PaymentMode.cash,
                                  onTap: () => setState(() => _paymentModeFilter =
                                      _paymentModeFilter == PaymentMode.cash ? null : PaymentMode.cash),
                                ),
                                const SizedBox(width: 6),
                                _buildMiniFilterChip(
                                  label: '📱 Online / UPI',
                                  isSelected: _paymentModeFilter == PaymentMode.upi ||
                                      _paymentModeFilter == PaymentMode.bankTransfer,
                                  onTap: () => setState(() => _paymentModeFilter =
                                      (_paymentModeFilter == PaymentMode.upi ||
                                              _paymentModeFilter == PaymentMode.bankTransfer)
                                          ? null
                                          : PaymentMode.upi),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Sort Menu Dropdown
                        PopupMenuButton<String>(
                          initialValue: _sortOption,
                          tooltip: 'Sort Vouchers',
                          onSelected: (val) => setState(() => _sortOption = val),
                          color: const Color(0xFF1E293B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppTheme.glassBorder),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'newest',
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Newest First', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'oldest',
                              child: Row(
                                children: [
                                  Icon(Icons.history, size: 16, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Oldest First', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'highest',
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_downward, size: 16, color: AppTheme.goldAccent),
                                  SizedBox(width: 8),
                                  Text('Highest Amount', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'lowest',
                              child: Row(
                                children: [
                                  Icon(Icons.arrow_upward, size: 16, color: AppTheme.successGreenLight),
                                  SizedBox(width: 8),
                                  Text('Lowest Amount', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'payee',
                              child: Row(
                                children: [
                                  Icon(Icons.sort_by_alpha, size: 16, color: Colors.white70),
                                  SizedBox(width: 8),
                                  Text('Payee A-Z', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sortOption == 'highest' || _sortOption == 'lowest'
                                      ? Icons.swap_vert_rounded
                                      : Icons.sort_rounded,
                                  size: 15,
                                  color: AppTheme.goldAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getSortLabel(_sortOption),
                                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Date Grouping Toggle Button
                        GestureDetector(
                          onTap: () => setState(() => _isGroupedByDate = !_isGroupedByDate),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isGroupedByDate ? AppTheme.dangerRose.withAlpha(35) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isGroupedByDate ? AppTheme.dangerRose : AppTheme.glassBorder,
                              ),
                            ),
                            child: Tooltip(
                              message: _isGroupedByDate ? 'Switch to Flat List' : 'Group by Date',
                              child: Icon(
                                _isGroupedByDate ? Icons.view_agenda_rounded : Icons.view_list_rounded,
                                size: 15,
                                color: _isGroupedByDate ? Colors.white : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tab 1 Toolbar: Status Filters for Advances
                  if (_selectedTab == 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniFilterChip(
                          label: 'All (${activeAdvances.length})',
                          isSelected: _advanceStatusFilter == 'All',
                          onTap: () => setState(() => _advanceStatusFilter = 'All'),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniFilterChip(
                          label: '⏳ Pending ($pendingCount)',
                          isSelected: _advanceStatusFilter == 'Pending',
                          activeColor: AppTheme.goldAccent,
                          onTap: () => setState(() => _advanceStatusFilter = 'Pending'),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniFilterChip(
                          label: '✅ Settled ($settledCount)',
                          isSelected: _advanceStatusFilter == 'Settled',
                          activeColor: AppTheme.successGreenLight,
                          onTap: () => setState(() => _advanceStatusFilter = 'Settled'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tab 1: Advance Summary Metrics Banner
          if (_selectedTab == 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: Border.all(color: AppTheme.goldAccent.withAlpha(50)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAdvanceSummaryCol(
                        'Total Given',
                        currency.format(activeAdvances.fold(0.0, (s, a) => s + a.advanceAmount)),
                        Colors.white,
                      ),
                      Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                      _buildAdvanceSummaryCol(
                        'Settled Bills',
                        currency.format(totalSettledAdvance),
                        AppTheme.successGreenLight,
                      ),
                      Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                      _buildAdvanceSummaryCol(
                        'Pending Clearance',
                        currency.format(totalPendingAdvance),
                        AppTheme.goldAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // TAB 0: Vouchers List (Grouped by Date or Flat Grid)
          if (_selectedTab == 0) ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, isDesktop ? 24 : 100),
              sliver: filteredExpenses.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            activeEvent != null
                                ? 'No expense vouchers found for ${activeEvent.name} (${activeEvent.year}).'
                                : 'No expense vouchers found.',
                            style: TextStyle(color: Colors.white.withAlpha(140)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : (_isGroupedByDate
                      ? SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final group = dateGroups[index];
                              return _buildDateGroupSection(
                                context: context,
                                group: group,
                                currency: currency,
                                isDesktop: isDesktop,
                                screenWidth: screenWidth,
                              );
                            },
                            childCount: dateGroups.length,
                          ),
                        )
                      : (isDesktop
                          ? SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth > 1500 ? 3 : 2,
                                childAspectRatio: 3.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final exp = filteredExpenses[index];
                                  return TransactionTile(
                                    title: exp.payeeName,
                                    subtitle: '${exp.category.displayName} • ${exp.voucherNo} • Paid by ${exp.paidBy}',
                                    amount: exp.amount,
                                    isIncome: false,
                                    paymentMode: exp.paymentMode,
                                    date: exp.date,
                                    tag: exp.description,
                                    hasReceipt: exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty,
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => VoucherActionDialog(expense: exp),
                                    ),
                                  );
                                },
                                childCount: filteredExpenses.length,
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final exp = filteredExpenses[index];
                                  return TransactionTile(
                                    title: exp.payeeName,
                                    subtitle: '${exp.category.displayName} • ${exp.voucherNo} • Paid by ${exp.paidBy}',
                                    amount: exp.amount,
                                    isIncome: false,
                                    paymentMode: exp.paymentMode,
                                    date: exp.date,
                                    tag: exp.description,
                                    hasReceipt: exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty,
                                    onTap: () => showDialog(
                                      context: context,
                                      builder: (_) => VoucherActionDialog(expense: exp),
                                    ),
                                  );
                                },
                                childCount: filteredExpenses.length,
                              ),
                            ))),
            ),
          ]

          // TAB 1: Member Advances List
          else ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 2, 20, isDesktop ? 24 : 100),
              sliver: filteredAdvances.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text(
                            activeEvent != null
                                ? 'No member advance records found for ${activeEvent.name} (${activeEvent.year}).'
                                : 'No member advance records found.',
                            style: TextStyle(color: Colors.white.withAlpha(140)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final adv = filteredAdvances[index];
                          return _buildAdvanceCard(context, adv, currency);
                        },
                        childCount: filteredAdvances.length,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateGroupSection({
    required BuildContext context,
    required _DateExpenseGroup group,
    required NumberFormat currency,
    required bool isDesktop,
    required double screenWidth,
  }) {
    final now = DateTime.now();
    final d = group.date;
    final isToday = now.year == d.year && now.month == d.month && now.day == d.day;
    final isYesterday = now.year == d.year && now.month == d.month && (now.day - 1) == d.day;

    String dateTitle;
    if (isToday) {
      dateTitle = 'Today, ${DateFormat('dd MMMM yyyy').format(d)}';
    } else if (isYesterday) {
      dateTitle = 'Yesterday, ${DateFormat('dd MMMM yyyy').format(d)}';
    } else {
      dateTitle = DateFormat('EEEE, dd MMMM yyyy').format(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Section Header
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRose.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.event_note_rounded, size: 13, color: AppTheme.dangerRose),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Text(
                  '${group.vouchers.length} ${group.vouchers.length == 1 ? 'voucher' : 'vouchers'} • ${currency.format(group.totalAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withAlpha(190),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Group Vouchers (Desktop multi-column or Mobile column)
        if (isDesktop)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.vouchers.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: screenWidth > 1500 ? 3 : 2,
              childAspectRatio: 3.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, idx) {
              final exp = group.vouchers[idx];
              return TransactionTile(
                title: exp.payeeName,
                subtitle: '${exp.category.displayName} • ${exp.voucherNo} • Paid by ${exp.paidBy}',
                amount: exp.amount,
                isIncome: false,
                paymentMode: exp.paymentMode,
                date: exp.date,
                tag: exp.description,
                hasReceipt: exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => VoucherActionDialog(expense: exp),
                ),
              );
            },
          )
        else
          Column(
            children: group.vouchers.map((exp) {
              return TransactionTile(
                title: exp.payeeName,
                subtitle: '${exp.category.displayName} • ${exp.voucherNo} • Paid by ${exp.paidBy}',
                amount: exp.amount,
                isIncome: false,
                paymentMode: exp.paymentMode,
                date: exp.date,
                tag: exp.description,
                hasReceipt: exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => VoucherActionDialog(expense: exp),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSelected
              ? [color.withAlpha(50), const Color(0x3D1E293B)]
              : [color.withAlpha(20), const Color(0x1F1E293B)],
        ),
        border: Border.all(
          color: isSelected ? color : color.withAlpha(70),
          width: isSelected ? 1.5 : 1.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withAlpha(160),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? activeColor,
  }) {
    final color = activeColor ?? AppTheme.dangerRose;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(35) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppTheme.glassBorder,
            width: isSelected ? 1.3 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvanceSummaryCol(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(150)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildAdvanceCard(BuildContext context, MemberAdvance adv, NumberFormat currency) {
    final provider = Provider.of<PujaProvider>(context, listen: false);
    return AdvanceAccountCard(
      advance: adv,
      currency: currency,
      provider: provider,
      activeEvent: provider.selectedEvent,
    );
  }

  Widget _buildCategoryChip(
    ExpenseCategory? category,
    String label,
    IconData icon, {
    Color? color,
    required double amount,
  }) {
    final isSelected = _selectedCategory == category;
    final compactFormat = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppTheme.primaryBlue).withAlpha(40)
              : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? (color ?? AppTheme.primaryBlue) : AppTheme.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (color ?? AppTheme.primaryBlue).withAlpha(40),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? (color ?? AppTheme.primaryBlue) : Colors.white60),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (amount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (color ?? AppTheme.primaryBlue).withAlpha(60)
                      : Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  compactFormat.format(amount),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withAlpha(200),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
