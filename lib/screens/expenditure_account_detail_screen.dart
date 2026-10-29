import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/dialogs.dart';
import '../widgets/responsive_layout.dart';
import '../services/pdf_report_service.dart';
import '../widgets/pdf_progress_dialog.dart';

class ExpenditureAccountDetailScreen extends StatefulWidget {
  final String accountId;

  const ExpenditureAccountDetailScreen({
    super.key,
    required this.accountId,
  });

  @override
  State<ExpenditureAccountDetailScreen> createState() => _ExpenditureAccountDetailScreenState();
}

class _ExpenditureAccountDetailScreenState extends State<ExpenditureAccountDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  PaymentMode? _filterMode;
  bool _isTableView = false; // Toggle between Grid and Table on Desktop

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleGeneratePdf(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    ExpenditureAccountPdfFilter filter,
  ) async {
    // Show Action Bottom Sheet with Print/Save and Share
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Color(0x3338BDF8)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerRose.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.dangerRose, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${account.accountName} • PDF Export',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          filter == ExpenditureAccountPdfFilter.all
                              ? 'Complete Expense Vouchers Ledger'
                              : (filter == ExpenditureAccountPdfFilter.cashOnly
                                  ? 'Cash Expense Vouchers'
                                  : (filter == ExpenditureAccountPdfFilter.upiOnly
                                      ? 'UPI & Online Vouchers'
                                      : 'Bank Transfer Vouchers')),
                          style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.print_rounded, color: Color(0xFF38BDF8)),
                ),
                title: const Text('Print / Save PDF Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Preview pages & save directly as PDF file', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFF1E293B),
                onTap: () => Navigator.pop(ctx, 'print'),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share_rounded, color: Color(0xFF22C55E)),
                ),
                title: const Text('Share PDF File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Send PDF via WhatsApp, Email, or Drive', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFF1E293B),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    try {
      await PdfProgressDialog.runWithProgress(
        context,
        title: choice == 'share' ? 'Preparing PDF to Share' : 'Generating PDF Statement',
        message: 'Formatting expense vouchers and ledger...\nPlease wait, large reports may take a moment.',
        task: () async {
          if (choice == 'share') {
            await PdfReportService.shareExpenditureAccountReport(
              provider: provider,
              account: account,
              filter: filter,
            );
          } else {
            await PdfReportService.printExpenditureAccountReport(
              provider: provider,
              account: account,
              filter: filter,
            );
          }
        },
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.dangerRose,
            content: Text('Error generating PDF: $e'),
          ),
        );
      }
    }
  }

  Widget _buildPdfDropdownButton(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    List<ExpenseVoucher> vouchers,
    NumberFormat currency,
  ) {
    final cashVouchers = vouchers.where((v) => v.paymentMode == PaymentMode.cash).toList();
    final upiVouchers = vouchers.where((v) => v.paymentMode == PaymentMode.upi).toList();
    final bankVouchers = vouchers.where((v) => v.paymentMode == PaymentMode.bankTransfer).toList();

    final cashTotal = cashVouchers.fold<double>(0.0, (s, v) => s + v.amount);
    final upiTotal = upiVouchers.fold<double>(0.0, (s, v) => s + v.amount);
    final bankTotal = bankVouchers.fold<double>(0.0, (s, v) => s + v.amount);
    final allTotal = vouchers.fold<double>(0.0, (s, v) => s + v.amount);

    return PopupMenuButton<ExpenditureAccountPdfFilter>(
      tooltip: 'Generate PDF Report',
      color: const Color(0xFF0F172A),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      offset: const Offset(0, 48),
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: ExpenditureAccountPdfFilter.all,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, size: 16, color: AppTheme.dangerRose),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All Expense Vouchers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('All (${vouchers.length}) • ${currency.format(allTotal)}', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: ExpenditureAccountPdfFilter.cashOnly,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payments_rounded, size: 16, color: Color(0xFF34D399)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cash Payments Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Cash (${cashVouchers.length}) • ${currency.format(cashTotal)}', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ExpenditureAccountPdfFilter.upiOnly,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF818CF8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('UPI / Online Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('UPI (${upiVouchers.length}) • ${currency.format(upiTotal)}', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: ExpenditureAccountPdfFilter.bankOnly,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Bank Transfer Only', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Bank (${bankVouchers.length}) • ${currency.format(bankTotal)}', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (filter) => _handleGeneratePdf(context, provider, account, filter),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFBE123C).withAlpha(25),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFFBE123C).withAlpha(110)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFFB7185)),
            SizedBox(width: 8),
            Text(
              'Generate PDF',
              style: TextStyle(
                color: Color(0xFFFB7185),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFFFB7185)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOptionsMenu(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
  ) {
    return Container(
      height: 42,
      width: 42,
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Account Options',
        icon: const Icon(Icons.sort_rounded, size: 20, color: Colors.white70),
        color: const Color(0xFF0F172A),
        elevation: 12,
        offset: const Offset(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        itemBuilder: (ctx) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: AppTheme.goldAccent),
                SizedBox(width: 10),
                Text('Edit Account', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                SizedBox(width: 10),
                Text('Delete Account', style: TextStyle(color: AppTheme.dangerRose, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        onSelected: (val) {
          if (val == 'edit') {
            showDialog(
              context: context,
              builder: (_) => AddExpenditureAccountDialog(existing: account),
            );
          } else if (val == 'delete') {
            _confirmDeleteExpenditureAccount(context, provider, account);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final provider = Provider.of<PujaProvider>(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Find current account
    ExpenditureAccount? foundAccount;
    try {
      foundAccount = provider.expenditureAccounts.firstWhere((a) => a.id == widget.accountId);
    } catch (_) {
      foundAccount = null;
    }

    if (foundAccount == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldDark,
        appBar: AppBar(
          title: const Text('Account Not Found'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text(
            'This expenditure account may have been deleted.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final account = foundAccount;

    // Account aggregates
    final vouchers = provider.getAccountExpenses(account.id);
    final totalSpent = provider.getAccountTotalSpent(account.id);
    final budget = account.allocatedBudget;
    final remaining = provider.getAccountRemainingBudget(account);

    // Filtered vouchers
    final query = _searchController.text.trim().toLowerCase();
    final filteredVouchers = vouchers.where((v) {
      if (query.isNotEmpty) {
        final matchesPayee = v.payeeName.toLowerCase().contains(query);
        final matchesVoucherNo = v.voucherNo.toLowerCase().contains(query);
        final matchesDesc = (v.description ?? '').toLowerCase().contains(query);
        if (!matchesPayee && !matchesVoucherNo && !matchesDesc) return false;
      }
      if (_filterMode != null && v.paymentMode != _filterMode) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(
                context,
                provider,
                account,
                vouchers,
                filteredVouchers,
                totalSpent,
                budget,
                remaining,
                currency,
              )
            : _buildMobileLayout(
                context,
                provider,
                account,
                vouchers,
                filteredVouchers,
                totalSpent,
                budget,
                remaining,
                currency,
              ),
      ),
    );
  }

  // ===========================================================================
  // DESKTOP (PC) LAYOUT
  // ===========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    List<ExpenseVoucher> vouchers,
    List<ExpenseVoucher> filteredVouchers,
    double totalSpent,
    double? budget,
    double remaining,
    NumberFormat currency,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    const hPadding = 28.0;

    return CustomScrollView(
      slivers: [
        // 1. Desktop Header Toolbar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 14),
            child: Row(
              children: [
                // Back button
                SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0x1F1E293B),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    label: const Text('Back to Accounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 16),

                // Account Name & Details
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.accountName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryBlue.withAlpha(70)),
                        ),
                        child: Text(
                          account.category.displayName,
                          style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),

                      // In-Charge Tag
                      if (account.inChargeName != null && account.inChargeName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                'In-Charge: ${account.inChargeName}',
                                style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Right Actions
                _buildPdfDropdownButton(context, provider, account, vouchers, currency),
                const SizedBox(width: 10),

                _buildAccountOptionsMenu(context, provider, account),
                const SizedBox(width: 12),

                // Primary Desktop Button: + Record Expense Voucher
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerRose,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: AppTheme.dangerRose.withAlpha(90),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AddExpenseDialog(
                        initialAccountId: account.id,
                        initialAccountName: account.accountName,
                        initialEventId: account.eventId,
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 17),
                  label: const Text(
                    '+ Record Voucher',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Desktop 4-KPI Row
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 14),
            child: _buildDesktopKpis(totalSpent, budget, remaining, vouchers.length, currency),
          ),
        ),

        // 3. Desktop Unified Toolbar
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 12),
            child: _buildDesktopToolbar(vouchers.length, filteredVouchers.length, filteredVouchers.fold<double>(0.0, (sum, v) => sum + v.amount), currency),
          ),
        ),

        // 4. Desktop Main Content: Multi-Column Grid or Table
        if (filteredVouchers.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 40),
              child: _buildEmptyState(account, vouchers.isEmpty),
            ),
          )
        else if (_isTableView)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 30),
            sliver: _buildDesktopDataTable(context, provider, account, filteredVouchers, currency),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 30),
            sliver: _buildDesktopCardGrid(context, provider, filteredVouchers, currency, screenWidth),
          ),
      ],
    );
  }

  Widget _buildDesktopKpis(
    double totalSpent,
    double? budget,
    double remaining,
    int voucherCount,
    NumberFormat currency,
  ) {
    final hasBudget = budget != null && budget > 0;
    final percentConsumed = hasBudget ? ((totalSpent / budget) * 100).clamp(0.0, 999.0) : 0.0;
    final isOver = remaining < 0;

    return Row(
      children: [
        // 1. Total Spent
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: AppTheme.dangerRose.withAlpha(50), width: 1.2),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E0D17), Color(0xFF1B070E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, size: 12, color: AppTheme.dangerRose),
                    SizedBox(width: 4),
                    Text('TOTAL SPENT', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  currency.format(totalSpent),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.dangerRose),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('$voucherCount Vouchers Recorded', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Budget Allocated
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: AppTheme.primaryBlue.withAlpha(50), width: 1.2),
            gradient: const LinearGradient(
              colors: [Color(0xFF0C2340), Color(0xFF091428)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, size: 12, color: AppTheme.primaryBlue),
                    SizedBox(width: 4),
                    Text('BUDGET ALLOCATED', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasBudget ? currency.format(budget) : 'Not Set',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: hasBudget ? AppTheme.primaryBlue : Colors.white54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(hasBudget ? 'Account Spending Limit' : 'Configure in Edit Account', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 3. Remaining / Over Budget
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: (isOver ? AppTheme.dangerRose : AppTheme.accentEmerald).withAlpha(50), width: 1.2),
            gradient: LinearGradient(
              colors: isOver ? [const Color(0xFF350A14), const Color(0xFF1F060B)] : [const Color(0xFF062A1F), const Color(0xFF061B16)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isOver ? Icons.warning_amber_rounded : Icons.savings_outlined, size: 12, color: isOver ? AppTheme.dangerRose : AppTheme.accentEmerald),
                    const SizedBox(width: 4),
                    Text(isOver ? 'OVER BUDGET' : 'REMAINING BUDGET', style: TextStyle(fontSize: 10, color: isOver ? AppTheme.dangerRose : AppTheme.accentEmerald, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasBudget ? currency.format(remaining.abs()) : '—',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isOver ? AppTheme.dangerRose : AppTheme.accentEmerald),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(isOver ? 'Exceeds budget limit' : 'Available balance', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 4. Budget Consumption Meter
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: Colors.white.withAlpha(20), width: 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BUDGET CONSUMED', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text(
                      hasBudget ? '${percentConsumed.toStringAsFixed(1)}%' : '0%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isOver ? AppTheme.dangerRose : AppTheme.accentEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasBudget ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOver ? AppTheme.dangerRose : AppTheme.accentEmerald,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasBudget ? '${((100 - percentConsumed)).clamp(0, 100).toStringAsFixed(0)}% budget remains' : 'No limit specified',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopToolbar(int allCount, int filteredCount, double filteredSum, NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD90A1128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Search Input
          SizedBox(
            width: 290,
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Search payee, voucher no, note...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.dangerRose, size: 17),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16, color: Colors.white38),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0x1F1E293B),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.dangerRose)),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Payment mode filter chips
          _buildFilterModeChip(null, 'All ($allCount)'),
          const SizedBox(width: 6),
          _buildFilterModeChip(PaymentMode.cash, 'Cash'),
          const SizedBox(width: 6),
          _buildFilterModeChip(PaymentMode.upi, 'UPI'),
          const SizedBox(width: 6),
          _buildFilterModeChip(PaymentMode.bankTransfer, 'Bank'),

          const Spacer(),

          // Filtered Sum Label
          Text(
            'Showing $filteredCount vouchers • Total: ${currency.format(filteredSum)}',
            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 14),

          // View Switcher
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0x1F1E293B),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewModeButton(
                  icon: Icons.grid_view_rounded,
                  isSelected: !_isTableView,
                  tooltip: 'Grid View',
                  onTap: () => setState(() => _isTableView = false),
                ),
                Container(width: 1, height: 18, color: Colors.white12),
                _buildViewModeButton(
                  icon: Icons.table_rows_rounded,
                  isSelected: _isTableView,
                  tooltip: 'Table View',
                  onTap: () => setState(() => _isTableView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterModeChip(PaymentMode? mode, String label) {
    final isSelected = _filterMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _filterMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.dangerRose.withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.dangerRose : AppTheme.glassBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: isSelected ? AppTheme.dangerRose.withAlpha(35) : Colors.transparent,
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? AppTheme.dangerRose : Colors.white60,
          ),
        ),
      ),
    );
  }

  // Desktop Responsive Card Grid
  Widget _buildDesktopCardGrid(
    BuildContext context,
    PujaProvider provider,
    List<ExpenseVoucher> vouchers,
    NumberFormat currency,
    double screenWidth,
  ) {
    final crossAxisCount = screenWidth > 1560 ? 4 : (screenWidth > 1180 ? 3 : 2);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 198, // Ample breathing space: 0px overflow guaranteed
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildVoucherCard(context, vouchers[index], currency, provider, isGrid: true),
        childCount: vouchers.length,
      ),
    );
  }

  // Desktop Data Table View
  Widget _buildDesktopDataTable(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    List<ExpenseVoucher> vouchers,
    NumberFormat currency,
  ) {
    return SliverToBoxAdapter(
      child: GlassContainer(
        borderRadius: 16,
        padding: EdgeInsets.zero,
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(50)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF0F172A),
                child: const Row(
                  children: [
                    SizedBox(width: 80, child: Text('VOUCHER #', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text('PAYEE / VENDOR', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 3, child: Text('DESCRIPTION', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 1, child: Text('MODE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 2, child: Text('AMOUNT', style: TextStyle(color: AppTheme.dangerRose, fontSize: 11, fontWeight: FontWeight.w700))),
                    SizedBox(width: 140, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),

              // Rows
              ...List.generate(vouchers.length, (index) {
                final voucher = vouchers[index];
                final isEven = index % 2 == 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.transparent : Colors.white.withAlpha(4),
                    border: Border(top: BorderSide(color: Colors.white.withAlpha(12))),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(voucher.voucherNo, style: const TextStyle(color: AppTheme.dangerRose, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(voucher.payeeName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          voucher.description != null && voucher.description!.isNotEmpty ? voucher.description! : '—',
                          style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(DateFormat('dd MMM yyyy').format(voucher.date), style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11.5)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(voucher.paymentMode.name.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(currency.format(voucher.amount), style: const TextStyle(color: AppTheme.dangerRose, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(
                        width: 140,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (voucher.receiptPhotoUrl != null && voucher.receiptPhotoUrl!.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.receipt_outlined, size: 16, color: AppTheme.primaryBlue),
                                tooltip: 'View Bill Receipt',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => BillImagePreviewDialog(
                                      imageUrl: voucher.receiptPhotoUrl!,
                                      title: voucher.payeeName,
                                      subtitle: 'Voucher ${voucher.voucherNo}',
                                    ),
                                  );
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white70),
                              tooltip: 'Edit Voucher',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AddExpenseDialog(
                                    existing: voucher,
                                    initialAccountId: widget.accountId,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                              tooltip: 'Delete Voucher',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => provider.deleteExpense(voucher.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE (PHONE) LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    List<ExpenseVoucher> vouchers,
    List<ExpenseVoucher> filteredVouchers,
    double totalSpent,
    double? budget,
    double remaining,
    NumberFormat currency,
  ) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.cardSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<ExpenditureAccountPdfFilter>(
              tooltip: 'Generate PDF Statement',
              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFB7185)),
              color: const Color(0xFF0F172A),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.glassBorder),
              ),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: ExpenditureAccountPdfFilter.all,
                  child: Row(
                    children: [
                      Icon(Icons.description_rounded, size: 16, color: Color(0xFFFB7185)),
                      SizedBox(width: 8),
                      Text('All Vouchers', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ExpenditureAccountPdfFilter.cashOnly,
                  child: Row(
                    children: [
                      Icon(Icons.payments_rounded, size: 16, color: Color(0xFF34D399)),
                      SizedBox(width: 8),
                      Text('Cash Only', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ExpenditureAccountPdfFilter.upiOnly,
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFF818CF8)),
                      SizedBox(width: 8),
                      Text('UPI Only', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: ExpenditureAccountPdfFilter.bankOnly,
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF38BDF8)),
                      SizedBox(width: 8),
                      Text('Bank Only', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onSelected: (filter) => _handleGeneratePdf(context, provider, account, filter),
            ),
            PopupMenuButton<String>(
              tooltip: 'Account Options',
              icon: const Icon(Icons.sort_rounded, color: Colors.white70),
              color: const Color(0xFF0F172A),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppTheme.glassBorder),
              ),
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: AppTheme.goldAccent),
                      SizedBox(width: 8),
                      Text('Edit Account', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                      SizedBox(width: 8),
                      Text('Delete Account', style: TextStyle(color: AppTheme.dangerRose, fontSize: 13)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'edit') {
                  showDialog(
                    context: context,
                    builder: (_) => AddExpenditureAccountDialog(existing: account),
                  );
                } else if (val == 'delete') {
                  _confirmDeleteExpenditureAccount(context, provider, account);
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2A1B28), Color(0xFF161B2E), AppTheme.scaffoldDark],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.only(left: 20, right: 20, top: 75, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerRose.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.dangerRose, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.accountName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    account.category.displayName,
                                    style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (account.inChargeName != null && account.inChargeName!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.person_outline, color: Colors.white60, size: 13),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      'In-Charge: ${account.inChargeName}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Body Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards Row
                Row(
                  children: [
                    // Total Spent
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRose.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.dangerRose, size: 14),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Total Spent',
                                  style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              currency.format(totalSpent),
                              style: const TextStyle(
                                color: AppTheme.dangerRose,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${vouchers.length} vouchers recorded',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Budget & Balance
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (remaining < 0 ? AppTheme.dangerRose : AppTheme.accentEmerald).withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    remaining < 0 ? Icons.warning_amber_rounded : Icons.savings_outlined,
                                    color: remaining < 0 ? AppTheme.dangerRose : AppTheme.accentEmerald,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  budget != null && budget > 0 ? (remaining < 0 ? 'Over Budget' : 'Remaining') : 'Budget',
                                  style: TextStyle(
                                    color: remaining < 0 ? AppTheme.dangerRose : Colors.white60,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              budget != null && budget > 0
                                  ? (remaining < 0 ? currency.format(remaining.abs()) : currency.format(remaining))
                                  : 'Not Set',
                              style: TextStyle(
                                color: budget != null && budget > 0
                                    ? (remaining < 0 ? AppTheme.dangerRose : AppTheme.accentEmerald)
                                    : Colors.white54,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              budget != null && budget > 0 ? 'Limit: ${currency.format(budget)}' : 'Set in Edit Account',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Budget progress bar if budget set
                if (budget != null && budget > 0) ...[
                  const SizedBox(height: 12),
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    borderRadius: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Budget Consumption', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text(
                              '${((totalSpent / budget) * 100).clamp(0, 999).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: totalSpent > budget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (totalSpent / budget).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalSpent > budget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // Mobile Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRose,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddExpenseDialog(
                          initialAccountId: account.id,
                          initialAccountName: account.accountName,
                          initialEventId: account.eventId,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    label: const Text(
                      '+ Record Expense Voucher',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by payee name, voucher no...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withAlpha(10),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withAlpha(20)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.dangerRose),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Header with Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'VOUCHERS (${filteredVouchers.length})',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (filteredVouchers.isNotEmpty)
                      Text(
                        'Sum: ${currency.format(filteredVouchers.fold<double>(0.0, (sum, v) => sum + v.amount))}',
                        style: const TextStyle(color: AppTheme.dangerRose, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Mobile Vouchers List
        if (filteredVouchers.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildEmptyState(account, vouchers.isEmpty),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final voucher = filteredVouchers[index];
                  return _buildVoucherCard(context, voucher, currency, provider);
                },
                childCount: filteredVouchers.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 60)),
      ],
    );
  }

  // ===========================================================================
  // SHARED HELPERS
  // ===========================================================================
  Widget _buildEmptyState(ExpenditureAccount account, bool isCompletelyEmpty) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.dangerRose.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long_outlined, color: AppTheme.dangerRose, size: 40),
        ),
        const SizedBox(height: 16),
        const Text(
          'No Expense Vouchers Found',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          !isCompletelyEmpty
              ? 'Try clearing your search query or filter.'
              : 'Record your first expense voucher under ${account.accountName}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  void _confirmDeleteExpenditureAccount(BuildContext context, PujaProvider provider, ExpenditureAccount account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardSurface,
        title: const Text('Delete Expenditure Account?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${account.accountName}"? All expense vouchers recorded under this account will also be permanently deleted.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRose),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      provider.deleteExpenditureAccount(account.id);
      Navigator.pop(context);
    }
  }

  Widget _buildVoucherCard(
    BuildContext context,
    ExpenseVoucher voucher,
    NumberFormat currency,
    PujaProvider provider, {
    bool isGrid = false,
  }) {
    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row: Voucher No & Date & Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerRose.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher.voucherNo,
                    style: const TextStyle(color: AppTheme.dangerRose, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(voucher.date),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    voucher.paymentMode.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                  color: AppTheme.cardSurface,
                  padding: EdgeInsets.zero,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Voucher', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Voucher', style: TextStyle(color: AppTheme.dangerRose))),
                  ],
                  onSelected: (val) {
                    if (val == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) => AddExpenseDialog(
                          existing: voucher,
                          initialAccountId: widget.accountId,
                        ),
                      );
                    } else if (val == 'delete') {
                      provider.deleteExpense(voucher.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: AppTheme.dangerRose,
                          content: Text('Voucher deleted successfully'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Payee and Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.payeeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (voucher.description != null && voucher.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          voucher.description!,
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  currency.format(voucher.amount),
                  style: const TextStyle(
                    color: AppTheme.dangerRose,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Bill preview if attached
            if (voucher.receiptPhotoUrl != null && voucher.receiptPhotoUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => BillImagePreviewDialog(
                      imageUrl: voucher.receiptPhotoUrl!,
                      title: voucher.payeeName,
                      subtitle: 'Voucher ${voucher.voucherNo}',
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withAlpha(40)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_outlined, color: AppTheme.primaryBlue, size: 13),
                      SizedBox(width: 5),
                      Text(
                        'View Attached Bill Receipt',
                        style: TextStyle(color: AppTheme.primaryBlue, fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
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
