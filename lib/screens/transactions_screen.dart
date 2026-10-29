import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/advance_account_card.dart';
import '../widgets/desktop_data_grid.dart';
import '../widgets/dialogs.dart';
import '../services/receipt_share_service.dart';

enum TxType { donation, expense, advance }

class UnifiedTx {
  final String id;
  final TxType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final PaymentMode paymentMode;
  final String? eventId;
  final dynamic raw;
  final String? status;
  final ExpenseCategory? category;

  UnifiedTx({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.paymentMode,
    this.eventId,
    this.raw,
    this.status,
    this.category,
  });
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedEventId = 'all'; // 'all' or eventId
  String _paymentModeFilter = 'All'; // 'All', 'Cash', 'Online', 'Cheque'
  String _advanceFilter = 'All'; // 'All', 'Pending', 'Settled'
  String _topTxFilter = 'All'; // 'All', 'Donations', 'Expenses', 'Advances'
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final hPadding = isDesktop ? 28.0 : 16.0;

    // Filter by Event
    final List<ChandaSlip> filteredSlips = _selectedEventId == 'all'
        ? provider.slips
        : provider.slips.where((s) => s.eventId == _selectedEventId).toList();

    final List<ExpenseVoucher> filteredExpenses = _selectedEventId == 'all'
        ? provider.expenses
        : provider.expenses.where((e) => e.eventId == _selectedEventId).toList();

    final List<MemberAdvance> filteredAdvances = _selectedEventId == 'all'
        ? provider.advances
        : provider.advances.where((a) => a.eventId == _selectedEventId).toList();

    // Map to Unified Transactions
    final List<UnifiedTx> allUnified = [];

    for (final s in filteredSlips) {
      allUnified.add(UnifiedTx(
        id: s.id,
        type: TxType.donation,
        title: s.donorName,
        subtitle: 'Slip #${s.slipNumber} • Book #${s.bookNumber}${s.collectedBy.isNotEmpty ? " • by ${s.collectedBy}" : ""}',
        amount: s.amount,
        date: s.createdAt,
        paymentMode: s.paymentMode,
        eventId: s.eventId,
        raw: s,
        status: s.isFullyPaid ? 'Paid' : 'Due',
      ));
    }

    for (final e in filteredExpenses) {
      allUnified.add(UnifiedTx(
        id: e.id,
        type: TxType.expense,
        title: e.payeeName.isNotEmpty ? e.payeeName : (e.description ?? 'Expense'),
        subtitle: '${e.category.displayName} • Voucher #${e.voucherNo}${e.description != null && e.description!.isNotEmpty ? " • ${e.description}" : ""}',
        amount: e.amount,
        date: e.date,
        paymentMode: e.paymentMode,
        eventId: e.eventId,
        raw: e,
        category: e.category,
      ));
    }

    final advanceIdsWithVouchers = filteredExpenses
        .where((e) => e.advanceId != null && e.advanceId!.isNotEmpty)
        .map((e) => e.advanceId!)
        .toSet();

    for (final a in filteredAdvances) {
      if (!advanceIdsWithVouchers.contains(a.id)) {
        allUnified.add(UnifiedTx(
          id: a.id,
          type: TxType.advance,
          title: a.memberName,
          subtitle: '${a.purpose} • ${a.category.displayName}${a.hasContract ? " • Deal: ₹${a.effectiveOriginalAmount.toInt()} (Due: ₹${a.remainingDue.toInt()})" : ""}',
          amount: a.advanceAmount,
          date: a.dateGiven,
          paymentMode: a.paymentMode,
          eventId: a.eventId,
          raw: a,
          status: a.status,
          category: a.category,
        ));
      }
    }

    // Sort Chronologically descending
    allUnified.sort((a, b) => b.date.compareTo(a.date));

    // Calculate Summary Stats for active view
    final totalInflow = filteredSlips.fold<double>(0.0, (sum, s) => sum + s.amount);
    final totalOutflow = filteredExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalAdvancesPending = filteredAdvances.where((a) => a.status == 'Pending').fold<double>(0.0, (sum, a) => sum + a.advanceAmount);
    final netCash = totalInflow - totalOutflow;

    // Filter unified list by Search & Payment Mode
    final searchedUnified = allUnified.where((tx) {
      final matchesSearch = _searchQuery.isEmpty ||
          tx.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.subtitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tx.amount.toString().contains(_searchQuery);

      final matchesPayment = _paymentModeFilter == 'All' ||
          (_paymentModeFilter == 'Cash' && tx.paymentMode == PaymentMode.cash) ||
          (_paymentModeFilter == 'UPI' && tx.paymentMode == PaymentMode.upi) ||
          (_paymentModeFilter == 'Bank' && tx.paymentMode == PaymentMode.bankTransfer) ||
          (_paymentModeFilter == 'In-Kind' && tx.raw is ChandaSlip && (tx.raw as ChandaSlip).isInKind);

      return matchesSearch && matchesPayment;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 1. Screen Title & View Mode Toggle (Full Width)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transactions & Ledger',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'All cash inflows, vouchers, donations & advances in real time',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withAlpha(150),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (isDesktop)
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _isTableView = true),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isTableView ? AppTheme.primaryBlue.withAlpha(35) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _isTableView ? AppTheme.primaryBlue : Colors.transparent),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_chart_rounded, size: 14, color: _isTableView ? AppTheme.primaryBlue : Colors.white60),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Table Mode (PC)',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _isTableView ? Colors.white : Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => setState(() => _isTableView = false),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !_isTableView ? AppTheme.primaryBlue.withAlpha(35) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: !_isTableView ? AppTheme.primaryBlue : Colors.transparent),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.view_stream_rounded, size: 14, color: !_isTableView ? AppTheme.primaryBlue : Colors.white60),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Card Stream',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: !_isTableView ? Colors.white : Colors.white60),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 2. Quick Action Buttons (Directly Below Header)
              SliverToBoxAdapter(
                child: _buildActionDock(context, provider, isDesktop, hPadding),
              ),

              // 2. Financial Summary KPI Cards (Inflow, Outflow, Advance, Net)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - (isDesktop ? 36 : 18)) / (isDesktop ? 4 : 2);
                      return Wrap(
                        spacing: isDesktop ? 12 : 6,
                        runSpacing: 8,
                        children: [
                          _buildKpiCard(
                            title: 'Total Inflow',
                            amount: currency.format(totalInflow),
                            subtitle: '${filteredSlips.length} Donations',
                            icon: Icons.arrow_downward_rounded,
                            color: AppTheme.successGreen,
                            width: cardWidth,
                          ),
                          _buildKpiCard(
                            title: 'Total Outflow',
                            amount: currency.format(totalOutflow),
                            subtitle: '${filteredExpenses.length} Vouchers',
                            icon: Icons.arrow_upward_rounded,
                            color: AppTheme.dangerRose,
                            width: cardWidth,
                          ),
                          _buildKpiCard(
                            title: 'Pending Advances',
                            amount: currency.format(totalAdvancesPending),
                            subtitle: '${filteredAdvances.where((a) => a.status == "Pending").length} Members',
                            icon: Icons.wallet_rounded,
                            color: const Color(0xFFF59E0B),
                            width: cardWidth,
                          ),
                          _buildKpiCard(
                            title: 'Net Cash Flow',
                            amount: currency.format(netCash),
                            subtitle: netCash >= 0 ? 'Surplus Reserve' : 'Deficit',
                            icon: Icons.account_balance_wallet_rounded,
                            color: netCash >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose,
                            width: cardWidth,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // 3. Event / Festival Switcher Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 4, hPadding, 4),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildEventChip('all', '🌟 All Festivals & Events', null),
                        ...provider.events.map((e) => _buildEventChip(e.id, '${e.name} (${e.year})', e.status)),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Search Bar & Payment Mode Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 6),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: TextField(
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: InputDecoration(
                              hintText: 'Search donor, payee, member, purpose...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.white.withAlpha(120)),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primaryBlue),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16, color: Colors.white60),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Payment Mode Filter Popup
                      PopupMenuButton<String>(
                        initialValue: _paymentModeFilter,
                        tooltip: 'Filter Payment Mode',
                        onSelected: (val) => setState(() => _paymentModeFilter = val),
                        color: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppTheme.glassBorder),
                        ),
                        itemBuilder: (_) => [
                          _buildPopupItem('All', 'All Modes', Icons.payment_rounded),
                          _buildPopupItem('Cash', 'Cash Only', Icons.money_rounded),
                          _buildPopupItem('UPI', 'UPI / QR', Icons.qr_code_rounded),
                          _buildPopupItem('Bank', 'Bank Transfer', Icons.account_balance_rounded),
                          _buildPopupItem('In-Kind', 'In-Kind Samagri', Icons.inventory_2_rounded),
                        ],
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: _paymentModeFilter == 'All' ? const Color(0x1F1E293B) : AppTheme.primaryBlue.withAlpha(40),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _paymentModeFilter == 'All' ? AppTheme.glassBorder : AppTheme.primaryBlue,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.filter_alt_outlined,
                                size: 16,
                                color: _paymentModeFilter == 'All' ? Colors.white70 : AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _paymentModeFilter == 'All' ? 'Mode' : _paymentModeFilter,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _paymentModeFilter == 'All' ? Colors.white70 : AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Sticky Tabs Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.primaryBlue,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                    tabs: [
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 16),
                            const SizedBox(width: 6),
                            Text('All Activity (${searchedUnified.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.volunteer_activism_rounded, size: 16, color: AppTheme.successGreen),
                            const SizedBox(width: 6),
                            Text('Donations (${filteredSlips.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.military_tech_rounded, size: 16, color: AppTheme.goldAccent),
                            const SizedBox(width: 6),
                            const Text('Top Transactions'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.dangerRose),
                            const SizedBox(width: 6),
                            Text('Expenses (${filteredExpenses.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.wallet_rounded, size: 16, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 6),
                            Text('Advances (${filteredAdvances.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  horizontalPadding: hPadding,
                ),
              ),
            ];
          },
          body: isDesktop && _isTableView
              ? DesktopDataGrid(eventId: _selectedEventId == 'all' ? null : _selectedEventId)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 0: All / Recent Transactions
                    _buildAllActivityTab(context, provider, searchedUnified),

                    // Tab 1: Donations / Chanda Only
                    _buildDonationsTab(context, provider, filteredSlips),

                    // Tab 2: Top Transactions (Highest Amounts)
                    _buildTopTransactionsTab(context, provider, allUnified),

                    // Tab 3: Expenses / Vouchers Only
                    _buildExpensesTab(context, provider, filteredExpenses),

                    // Tab 4: Member Advances Only
                    _buildAdvancesTab(context, provider, filteredAdvances),
                  ],
                ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: ALL RECENT ACTIVITY (Live unified stream)
  // ==========================================
  Widget _buildAllActivityTab(BuildContext context, PujaProvider provider, List<UnifiedTx> txList) {
    if (txList.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions found',
        subtitle: _searchQuery.isNotEmpty ? 'No match for "$_searchQuery". Try clear search.' : 'Transactions will appear here as you add donations or record expenses.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: txList.length,
      itemBuilder: (context, index) {
        final tx = txList[index];
        return _buildUnifiedTxCard(context, provider, tx);
      },
    );
  }

  // ==========================================
  // TAB 1: DONATIONS (Chanda Collection Slips)
  // ==========================================
  Widget _buildDonationsTab(BuildContext context, PujaProvider provider, List<ChandaSlip> rawSlips) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final slips = rawSlips.where((s) {
      final matchesSearch = _searchQuery.isEmpty ||
          s.donorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.amount.toString().contains(_searchQuery) ||
          (s.slipNumber.toString().contains(_searchQuery)) ||
          (s.collectedBy.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesPayment = _paymentModeFilter == 'All' ||
          (_paymentModeFilter == 'Cash' && s.isCash && s.paymentMode == PaymentMode.cash) ||
          (_paymentModeFilter == 'UPI' && s.isCash && s.paymentMode == PaymentMode.upi) ||
          (_paymentModeFilter == 'Bank' && s.isCash && s.paymentMode == PaymentMode.bankTransfer) ||
          (_paymentModeFilter == 'In-Kind' && s.isInKind);

      return matchesSearch && matchesPayment;
    }).toList();

    slips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (slips.isEmpty) {
      return _buildEmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'No donation records',
        subtitle: 'Add donation slips using the + Chanda button above.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: slips.length,
      itemBuilder: (context, index) {
        final slip = slips[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.successGreen.withAlpha(80)),
                ),
                child: const Icon(Icons.currency_rupee_rounded, color: AppTheme.successGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slip.donorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currency.format(slip.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppTheme.successGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Slip #${slip.slipNumber} • Book #${slip.bookNumber}',
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0x22FFFFFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            slip.paymentMode.name.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('dd MMM yyyy, hh:mm a').format(slip.createdAt)}${slip.collectedBy.isNotEmpty ? " • Collected by ${slip.collectedBy}" : ""}',
                      style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (slip.slipPhotoUrl != null && slip.slipPhotoUrl!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined, size: 20, color: Color(0xFF10B981)),
                  tooltip: 'Slip Photo',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => BillImagePreviewDialog(
                      imageUrl: slip.slipPhotoUrl!,
                      title: slip.donorName,
                      subtitle: 'Slip #${slip.slipNumber} • Book #${slip.bookNumber}',
                      onDelete: () => provider.updateSlipReceiptPhoto(slipId: slip.id, photoUrl: null),
                      onReplace: () => showAttachSlipModal(
                        context,
                        onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: slip.id, photoUrl: url),
                        existingUrl: slip.slipPhotoUrl,
                      ),
                    ),
                  ),
                ),
              // Receipt Action Dialog Button
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, size: 20, color: AppTheme.primaryBlue),
                tooltip: 'Receipt & Actions',
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => SlipReceiptActionDialog(slip: slip),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: TOP TRANSACTIONS (Ranked by Amount)
  // ==========================================
  Widget _buildTopTransactionsTab(BuildContext context, PujaProvider provider, List<UnifiedTx> allTx) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    // Filter by Top Filter
    List<UnifiedTx> ranked = List.of(allTx);
    if (_topTxFilter == 'Donations') {
      ranked = ranked.where((t) => t.type == TxType.donation).toList();
    } else if (_topTxFilter == 'Expenses') {
      ranked = ranked.where((t) => t.type == TxType.expense).toList();
    } else if (_topTxFilter == 'Advances') {
      ranked = ranked.where((t) => t.type == TxType.advance).toList();
    }

    // Sort descending by amount
    ranked.sort((a, b) => b.amount.compareTo(a.amount));

    return Column(
      children: [
        // Sub-filter chips for Top Transactions
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTopFilterChip('All', '🏆 Top Overall'),
              _buildTopFilterChip('Donations', '🪙 Top Donations'),
              _buildTopFilterChip('Expenses', '💸 Major Expenses'),
              _buildTopFilterChip('Advances', '👛 Top Advances'),
            ],
          ),
        ),

        Expanded(
          child: ranked.isEmpty
              ? _buildEmptyState(
                  icon: Icons.military_tech_outlined,
                  title: 'No transactions recorded',
                  subtitle: 'Highest value transactions will be ranked here.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: ranked.length,
                  itemBuilder: (context, index) {
                    final tx = ranked[index];
                    final rank = index + 1;

                    String medal = '#$rank';
                    Color medalColor = Colors.white60;
                    if (rank == 1) {
                      medal = '🥇 #1';
                      medalColor = const Color(0xFFFFD700);
                    } else if (rank == 2) {
                      medal = '🥈 #2';
                      medalColor = const Color(0xFFC0C0C0);
                    } else if (rank == 3) {
                      medal = '🥉 #3';
                      medalColor = const Color(0xFFCD7F32);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: rank <= 3 ? medalColor.withAlpha(15) : const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: rank <= 3 ? medalColor.withAlpha(90) : AppTheme.glassBorder,
                          width: rank <= 3 ? 1.4 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Medal / Rank Badge
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: medalColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: medalColor.withAlpha(90)),
                            ),
                            child: Text(
                              medal,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: medalColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tx.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${tx.type == TxType.donation ? "+" : "-"} ${currency.format(tx.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: tx.type == TxType.donation ? AppTheme.successGreen : AppTheme.dangerRose,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: tx.type == TxType.donation
                                            ? AppTheme.successGreen.withAlpha(30)
                                            : tx.type == TxType.expense
                                                ? AppTheme.dangerRose.withAlpha(30)
                                                : const Color(0xFFD97706).withAlpha(30),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.type == TxType.donation
                                            ? 'DONATION'
                                            : tx.type == TxType.expense
                                                ? 'EXPENSE'
                                                : 'ADVANCE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: tx.type == TxType.donation
                                              ? AppTheme.successGreen
                                              : tx.type == TxType.expense
                                                  ? AppTheme.dangerRose
                                                  : const Color(0xFFFBBF24),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tx.subtitle,
                                        style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat('dd MMM yyyy').format(tx.date),
                                  style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(110)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 3: EXPENSES (Vouchers & Payees)
  // ==========================================
  Widget _buildExpensesTab(BuildContext context, PujaProvider provider, List<ExpenseVoucher> rawExpenses) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final expenses = rawExpenses.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.payeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (e.description != null && e.description!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          e.category.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.amount.toString().contains(_searchQuery) ||
          e.voucherNo.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesPayment = _paymentModeFilter == 'All' ||
          (_paymentModeFilter == 'Cash' && e.paymentMode == PaymentMode.cash) ||
          (_paymentModeFilter == 'UPI' && e.paymentMode == PaymentMode.upi) ||
          (_paymentModeFilter == 'Bank' && e.paymentMode == PaymentMode.bankTransfer);

      return matchesSearch && matchesPayment;
    }).toList();

    expenses.sort((a, b) => b.date.compareTo(a.date));

    if (expenses.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No expense records',
        subtitle: 'Record festival expenses using the + Expense button above.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        final isAdvance = exp.isAdvance;
        final themeColor = isAdvance ? const Color(0xFFF59E0B) : AppTheme.dangerRose;

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => showDialog(
            context: context,
            builder: (_) => ExpenseVoucherActionDialog(voucher: exp),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1F1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: themeColor.withAlpha(55),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Icon Avatar, Payee Name, Category & Voucher #, Type Badge, 3-Line Menu
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor.withAlpha(70)),
                      ),
                      child: Center(
                        child: Icon(
                          isAdvance ? Icons.wallet_rounded : exp.category.icon,
                          size: 19,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.payeeName.isNotEmpty ? exp.payeeName : 'Expense Voucher',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exp.category.displayName} • #${exp.voucherNo}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(140),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: themeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: themeColor.withAlpha(90)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAdvance ? Icons.wallet_rounded : Icons.payments_rounded,
                            size: 11,
                            color: themeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isAdvance ? 'ADVANCE' : 'EXPENSE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => BillImagePreviewDialog(
                            imageUrl: exp.receiptPhotoUrl!,
                            title: exp.payeeName,
                            subtitle: 'Voucher #${exp.voucherNo}',
                            onDelete: () {
                              provider.updateExpenseReceiptPhoto(expenseId: exp.id, photoUrl: null);
                              Navigator.pop(context);
                            },
                            onReplace: () => showAttachBillModal(
                              context,
                              onUploaded: (url) {
                                provider.updateExpenseReceiptPhoto(expenseId: exp.id, photoUrl: url);
                              },
                              existingUrl: exp.receiptPhotoUrl,
                            ),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 11),
                              SizedBox(width: 3),
                              Text(
                                'BILL',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // 3-Line Menu Button
                    _buildThreeLineMenuButton(
                      context: context,
                      hasBill: exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty,
                      onBillAction: () {
                        if (exp.receiptPhotoUrl != null && exp.receiptPhotoUrl!.isNotEmpty) {
                          showDialog(
                            context: context,
                            builder: (_) => BillImagePreviewDialog(
                              imageUrl: exp.receiptPhotoUrl!,
                              title: exp.payeeName,
                              subtitle: 'Voucher #${exp.voucherNo}',
                              onDelete: () {
                                provider.updateExpenseReceiptPhoto(expenseId: exp.id, photoUrl: null);
                                Navigator.pop(context);
                              },
                              onReplace: () => showAttachBillModal(
                                context,
                                onUploaded: (url) {
                                  provider.updateExpenseReceiptPhoto(expenseId: exp.id, photoUrl: url);
                                },
                                existingUrl: exp.receiptPhotoUrl,
                              ),
                            ),
                          );
                        } else {
                          showAttachBillModal(
                            context,
                            onUploaded: (url) {
                              provider.updateExpenseReceiptPhoto(expenseId: exp.id, photoUrl: url);
                            },
                          );
                        }
                      },
                      onViewSlip: () => showDialog(
                        context: context,
                        builder: (_) => ExpenseVoucherActionDialog(voucher: exp),
                      ),
                      onShare: () => ReceiptShareService.sendExpenseVoucherOnWhatsApp(
                        voucher: exp,
                        pujaName: provider.pujaName,
                        currentYear: provider.currentYear,
                        cashierName: provider.cashierName,
                      ),
                      onEdit: () => showDialog(
                        context: context,
                        builder: (_) => AddExpenseDialog(initialEventId: exp.eventId, existing: exp),
                      ),
                      onDelete: () => _confirmDeleteExpense(context, provider, exp),
                    ),
                  ],
                ),

                // Row 2: Structured Amount & Mode Box
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0x1F0F172A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: themeColor.withAlpha(40),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.format(exp.amount),
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: themeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAdvance ? Icons.account_balance_wallet_outlined : Icons.check_circle_rounded,
                                  size: 11,
                                  color: isAdvance ? const Color(0xFFFBBF24) : AppTheme.dangerRose,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  isAdvance ? 'Advance disbursement' : 'Disbursed expense',
                                  style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Payment Mode & Paid By
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: const Color(0x221E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.glassBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  exp.paymentMode == PaymentMode.upi
                                      ? Icons.qr_code_rounded
                                      : exp.paymentMode == PaymentMode.bankTransfer
                                          ? Icons.account_balance_rounded
                                          : Icons.payments_rounded,
                                  size: 11,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  exp.paymentMode.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: themeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (exp.paidBy.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              'By: ${exp.paidBy}',
                              style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Row 3: Description Note (if present)
                if (exp.description != null && exp.description!.trim().isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x141E293B),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes_rounded, size: 13, color: Colors.white60),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            exp.description!.trim(),
                            style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(190), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Row 4: Bottom Date & Metadata Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white60),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('dd MMM yyyy').format(exp.date),
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (exp.installmentId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF59E0B).withAlpha(50)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 10, color: Color(0xFFFBBF24)),
                            SizedBox(width: 3),
                            Text(
                              'Installment Linked',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFFFBBF24)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThreeLineMenuButton({
    required BuildContext context,
    required VoidCallback onShare,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    VoidCallback? onViewSlip,
    VoidCallback? onBillAction,
    bool hasBill = false,
  }) {
    return PopupMenuButton<String>(
      tooltip: 'Options',
      color: const Color(0xFF0F172A),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.glassBorder, width: 1.2),
      ),
      onSelected: (val) {
        if (val == 'view' && onViewSlip != null) {
          onViewSlip();
        } else if (val == 'bill' && onBillAction != null) {
          onBillAction();
        } else if (val == 'share') {
          onShare();
        } else if (val == 'edit') {
          onEdit();
        } else if (val == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (ctx) => [
        if (onViewSlip != null) ...[
          PopupMenuItem<String>(
            value: 'view',
            height: 44,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRose.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.dangerRose),
                ),
                const SizedBox(width: 12),
                const Text(
                  'View Voucher / Details',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        if (onBillAction != null) ...[
          PopupMenuItem<String>(
            value: 'bill',
            height: 44,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasBill ? const Color(0xFF10B981).withAlpha(25) : AppTheme.primaryBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasBill ? Icons.receipt_rounded : Icons.add_a_photo_outlined,
                    size: 16,
                    color: hasBill ? const Color(0xFF10B981) : AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  hasBill ? 'View Attached Bill' : 'Attach Bill Image',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        PopupMenuItem<String>(
          value: 'share',
          height: 44,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF25D366)),
              ),
              const SizedBox(width: 12),
              const Text(
                'Share on WhatsApp',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'edit',
          height: 44,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.goldAccent),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Details',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'delete',
          height: 44,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
              ),
              const SizedBox(width: 12),
              const Text(
                'Delete Entry',
                style: TextStyle(color: AppTheme.dangerRose, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0x221E293B),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3.5),
            Container(
              width: 11,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 3.5),
            Container(
              width: 6,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(220),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, PujaProvider provider, ExpenseVoucher expense) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 32),
              const SizedBox(height: 12),
              const Text(
                'Delete Expense Voucher?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to delete ${expense.voucherNo} (${expense.payeeName})?',
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.deleteExpense(expense.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${expense.voucherNo} deleted successfully.'),
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                        );
                      },
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 4: MEMBER ADVANCES (Cash Advances & Settlement)
  // ==========================================
  Widget _buildAdvancesTab(BuildContext context, PujaProvider provider, List<MemberAdvance> rawAdvances) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final advances = rawAdvances.where((a) {
      final matchesStatus = _advanceFilter == 'All' ||
          (_advanceFilter == 'Pending' && a.status == 'Pending') ||
          (_advanceFilter == 'Settled' && a.status != 'Pending');

      final matchesSearch = _searchQuery.isEmpty ||
          a.memberName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.purpose.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          a.advanceAmount.toString().contains(_searchQuery);

      return matchesStatus && matchesSearch;
    }).toList();

    advances.sort((a, b) => b.dateGiven.compareTo(a.dateGiven));

    return Column(
      children: [
        // Status Filter Chips
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildStatusChip('All', 'All Advances (${rawAdvances.length})'),
              const SizedBox(width: 8),
              _buildStatusChip('Pending', '⏳ Pending (${rawAdvances.where((a) => a.status == "Pending").length})'),
              const SizedBox(width: 8),
              _buildStatusChip('Settled', '✅ Settled (${rawAdvances.where((a) => a.status != "Pending").length})'),
            ],
          ),
        ),

        Expanded(
          child: advances.isEmpty
              ? _buildEmptyState(
                  icon: Icons.wallet_outlined,
                  title: 'No advances found',
                  subtitle: 'Disburse member cash advances using the + Advance button above.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: advances.length,
                  itemBuilder: (context, index) {
                    final adv = advances[index];
                    return AdvanceAccountCard(
                      advance: adv,
                      currency: currency,
                      provider: provider,
                      activeEvent: provider.selectedEvent,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // UNIFIED TX CARD (For All Activity Feed)
  // ==========================================
  Widget _buildUnifiedTxCard(BuildContext context, PujaProvider provider, UnifiedTx tx) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    Color typeColor;
    IconData typeIcon;
    String prefix;

    switch (tx.type) {
      case TxType.donation:
        typeColor = AppTheme.successGreen;
        typeIcon = Icons.arrow_downward_rounded;
        prefix = '+';
        break;
      case TxType.expense:
        typeColor = AppTheme.dangerRose;
        typeIcon = Icons.arrow_upward_rounded;
        prefix = '-';
        break;
      case TxType.advance:
        typeColor = const Color(0xFFF59E0B);
        typeIcon = Icons.wallet_rounded;
        prefix = '👛';
        break;
    }

    String? receiptPhotoUrl;
    ExpenseVoucher? expenseVoucher;
    MemberAdvance? memberAdvance;
    ChandaSlip? chandaSlip;

    if (tx.type == TxType.expense && tx.raw is ExpenseVoucher) {
      expenseVoucher = tx.raw as ExpenseVoucher;
      receiptPhotoUrl = expenseVoucher.receiptPhotoUrl;
    } else if (tx.type == TxType.advance && tx.raw is MemberAdvance) {
      memberAdvance = tx.raw as MemberAdvance;
      receiptPhotoUrl = memberAdvance.receiptPhotoUrl;
    } else if (tx.type == TxType.donation && tx.raw is ChandaSlip) {
      chandaSlip = tx.raw as ChandaSlip;
      receiptPhotoUrl = chandaSlip.slipPhotoUrl;
    }

    final hasBill = receiptPhotoUrl != null && receiptPhotoUrl.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (expenseVoucher != null) {
            showDialog(
              context: context,
              builder: (_) => ExpenseVoucherActionDialog(voucher: expenseVoucher!),
            );
          } else if (chandaSlip != null) {
            showDialog(
              context: context,
              builder: (_) => SlipReceiptActionDialog(slip: chandaSlip!),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: typeColor.withAlpha(80)),
                ),
                child: Icon(typeIcon, color: typeColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$prefix ${currency.format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: (tx.type == TxType.expense && tx.raw is ExpenseVoucher && (tx.raw as ExpenseVoucher).isAdvance)
                                ? const Color(0xFFF59E0B).withAlpha(30)
                                : typeColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tx.type == TxType.donation
                                ? 'DONATION'
                                : tx.type == TxType.expense
                                    ? ((tx.raw is ExpenseVoucher && (tx.raw as ExpenseVoucher).isAdvance)
                                        ? 'ADVANCE'
                                        : 'EXPENSE')
                                    : 'ADVANCE',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: (tx.type == TxType.expense && tx.raw is ExpenseVoucher && (tx.raw as ExpenseVoucher).isAdvance)
                                  ? const Color(0xFFFBBF24)
                                  : typeColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Bill / Slip Badge / Button
                        if (hasBill) ...[
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => BillImagePreviewDialog(
                                imageUrl: receiptPhotoUrl!,
                                title: tx.title,
                                subtitle: tx.subtitle,
                                onDelete: () {
                                  if (expenseVoucher != null) {
                                    provider.updateExpenseReceiptPhoto(expenseId: expenseVoucher.id, photoUrl: null);
                                  } else if (memberAdvance != null) {
                                    provider.updateAdvanceReceiptPhoto(advanceId: memberAdvance.id, photoUrl: null);
                                  } else if (chandaSlip != null) {
                                    provider.updateSlipReceiptPhoto(slipId: chandaSlip.id, photoUrl: null);
                                  }
                                  Navigator.pop(context);
                                },
                                onReplace: () => chandaSlip != null
                                    ? showAttachSlipModal(
                                        context,
                                        onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: chandaSlip!.id, photoUrl: url),
                                        existingUrl: receiptPhotoUrl,
                                      )
                                    : showAttachBillModal(
                                        context,
                                        onUploaded: (url) {
                                          if (expenseVoucher != null) {
                                            provider.updateExpenseReceiptPhoto(expenseId: expenseVoucher.id, photoUrl: url);
                                          } else if (memberAdvance != null) {
                                            provider.updateAdvanceReceiptPhoto(advanceId: memberAdvance.id, photoUrl: url);
                                          }
                                        },
                                        existingUrl: receiptPhotoUrl,
                                      ),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(25),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 10),
                                  const SizedBox(width: 2),
                                  Text(
                                    chandaSlip != null ? 'Slip Attached' : 'Bill Attached',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ] else if (tx.type == TxType.expense || tx.type == TxType.advance || tx.type == TxType.donation) ...[
                          GestureDetector(
                            onTap: () => chandaSlip != null
                                ? showAttachSlipModal(
                                    context,
                                    onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: chandaSlip!.id, photoUrl: url),
                                  )
                                : showAttachBillModal(
                                    context,
                                    onUploaded: (url) {
                                      if (expenseVoucher != null) {
                                        provider.updateExpenseReceiptPhoto(expenseId: expenseVoucher.id, photoUrl: url);
                                      } else if (memberAdvance != null) {
                                        provider.updateAdvanceReceiptPhoto(advanceId: memberAdvance.id, photoUrl: url);
                                      }
                                    },
                                  ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryBlue, size: 9),
                                  const SizedBox(width: 2),
                                  Text(
                                    chandaSlip != null ? '+ Slip' : '+ Bill',
                                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],

                        Expanded(
                          child: Text(
                            tx.subtitle,
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${DateFormat("dd MMM yyyy, hh:mm a").format(tx.date)} • Mode: ${tx.paymentMode.name.toUpperCase()}',
                      style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(110)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildKpiCard({
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w600),
              ),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(120)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(BuildContext context, PujaProvider provider, bool isDesktop, double hPadding) {
    final activeEventId = _selectedEventId != 'all' ? _selectedEventId : provider.selectedEvent?.id;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPadding, 6, hPadding, 4),
      child: Row(
        children: [
          // 1. + Donation (Chanda)
          Expanded(
            child: _buildActionCard(
              label: isDesktop ? '+ Collection A/C' : '+ Collection A/C',
              sublabel: 'Area Book',
              icon: Icons.account_balance_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFF047857), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: const Color(0xFF6EE7B7).withAlpha(140),
              shadowColor: const Color(0xFF059669).withAlpha(70),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AddCollectionAccountDialog(initialEventId: activeEventId),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. + Expenditure A/C
          Expanded(
            child: _buildActionCard(
              label: isDesktop ? '+ Expenditure A/C' : '+ Exp A/C',
              sublabel: 'Department',
              icon: Icons.account_balance_wallet_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: const Color(0xFFFDA4AF).withAlpha(140),
              shadowColor: const Color(0xFFE11D48).withAlpha(70),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEventId),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. + Advance
          Expanded(
            child: _buildActionCard(
              label: isDesktop ? '+ Give Advance' : '+ Advance',
              sublabel: 'Member',
              icon: Icons.wallet_rounded,
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderColor: const Color(0xFFFCD34D).withAlpha(140),
              shadowColor: const Color(0xFFD97706).withAlpha(70),
              onTap: () => showDialog(
                context: context,
                builder: (_) => GiveAdvanceDialog(initialEventId: activeEventId),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String label,
    required String sublabel,
    required IconData icon,
    required LinearGradient gradient,
    required Color borderColor,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: borderColor, width: 1.1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withAlpha(70)),
                ),
                child: Icon(icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(210),
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
      ),
    );
  }

  Widget _buildEventChip(String eventId, String label, String? status) {
    final isSelected = _selectedEventId == eventId;

    return GestureDetector(
      onTap: () => setState(() => _selectedEventId = eventId),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : AppTheme.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF070D1E) : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildTopFilterChip(String filterKey, String label) {
    final isSelected = _topTxFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _topTxFilter = filterKey),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.goldAccent.withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.goldAccent : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.goldAccent : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String filterKey, String label) {
    final isSelected = _advanceFilter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _advanceFilter = filterKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706).withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFBBF24) : AppTheme.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFFBBF24) : Colors.white70,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final double horizontalPadding;

  _SliverTabBarDelegate(this.tabBar, {this.horizontalPadding = 0});

  @override
  double get minExtent => tabBar.preferredSize.height + 8;

  @override
  double get maxExtent => tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFA070D1E),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 4),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return oldDelegate.horizontalPadding != horizontalPadding;
  }
}
