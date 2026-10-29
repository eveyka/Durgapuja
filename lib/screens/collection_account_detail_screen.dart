import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/collection_account_dialogs.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';
import '../services/pdf_report_service.dart';
import '../widgets/pdf_progress_dialog.dart';

enum ContributorSortOption {
  numberAsc(
    title: 'Slip Number (Low → High)',
    hindiSubtitle: 'Ascending: #1, #2, #3...',
    shortLabel: 'Slip # (1→9) ↑',
    icon: Icons.tag_rounded,
  ),
  numberDesc(
    title: 'Slip Number (High → Low)',
    hindiSubtitle: 'Descending: #300, #299, #298...',
    shortLabel: 'Slip # (9→1) ↓',
    icon: Icons.tag_rounded,
  ),
  nameAsc(
    title: 'Name (A → Z)',
    hindiSubtitle: 'Alphabetical: A se Z tak',
    shortLabel: 'Name (A→Z) ↑',
    icon: Icons.sort_by_alpha_rounded,
  ),
  nameDesc(
    title: 'Name (Z → A)',
    hindiSubtitle: 'Reverse: Z se A tak',
    shortLabel: 'Name (Z→A) ↓',
    icon: Icons.sort_by_alpha_rounded,
  ),
  amountDesc(
    title: 'Amount (High → Low)',
    hindiSubtitle: 'Sabse bada chanda pehle',
    shortLabel: 'Amount (₹ High) ↓',
    icon: Icons.arrow_downward_rounded,
  ),
  amountAsc(
    title: 'Amount (Low → High)',
    hindiSubtitle: 'Sabse chhota chanda pehle',
    shortLabel: 'Amount (₹ Low) ↑',
    icon: Icons.arrow_upward_rounded,
  ),
  dueDesc(
    title: 'Due Balance (High → Low)',
    hindiSubtitle: 'Sabse zyada baki pehle',
    shortLabel: 'Due (High) ↓',
    icon: Icons.hourglass_top_rounded,
  ),
  dateDesc(
    title: 'Date Added (Newest First)',
    hindiSubtitle: 'Haal hi me add kiya gaya',
    shortLabel: 'Date (New) ↓',
    icon: Icons.calendar_today_rounded,
  ),
  dateAsc(
    title: 'Date Added (Oldest First)',
    hindiSubtitle: 'Shuruat me add kiya gaya',
    shortLabel: 'Date (Old) ↑',
    icon: Icons.history_rounded,
  );

  final String title;
  final String hindiSubtitle;
  final String shortLabel;
  final IconData icon;

  const ContributorSortOption({
    required this.title,
    required this.hindiSubtitle,
    required this.shortLabel,
    required this.icon,
  });
}

class CollectionAccountDetailScreen extends StatefulWidget {
  final String accountId;

  const CollectionAccountDetailScreen({super.key, required this.accountId});

  @override
  State<CollectionAccountDetailScreen> createState() => _CollectionAccountDetailScreenState();
}

class _CollectionAccountDetailScreenState extends State<CollectionAccountDetailScreen> {
  String _searchQuery = '';
  DonationStatus? _statusFilter; // null = all, paid, unpaid, partial
  bool _isTableView = false; // Toggle between Cards and Table view on PC
  ContributorSortOption _currentSort = ContributorSortOption.numberDesc;

  bool get _isSortSlipNumber =>
      _currentSort == ContributorSortOption.numberAsc || _currentSort == ContributorSortOption.numberDesc;
  bool get _isSortName =>
      _currentSort == ContributorSortOption.nameAsc || _currentSort == ContributorSortOption.nameDesc;
  bool get _isSortAmount =>
      _currentSort == ContributorSortOption.amountDesc || _currentSort == ContributorSortOption.amountAsc;
  bool get _isSortDate =>
      _currentSort == ContributorSortOption.dateDesc || _currentSort == ContributorSortOption.dateAsc;

  void _confirmDeleteAccount(BuildContext context, PujaProvider provider, CollectionAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 36),
              const SizedBox(height: 12),
              const Text(
                'Delete Collection Account?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${account.accountName}"? All collection slips recorded under this account will also be permanently deleted.',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(160)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        provider.deleteCollectionAccount(account.id);
                        Navigator.pop(ctx);
                        Navigator.pop(context);
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

  Future<void> _handleGeneratePdf(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    CollectionAccountPdfFilter filter,
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
                      color: const Color(0xFF10B981).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF34D399), size: 22),
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
                          filter == CollectionAccountPdfFilter.all
                              ? 'All Contributors Register'
                              : (filter == CollectionAccountPdfFilter.onlyUnpaid
                                  ? 'Outstanding Dues Register'
                                  : 'Fully Paid Donations Register'),
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
        message: 'Formatting contributor records and layout...\nPlease wait, large reports may take a moment.',
        task: () async {
          if (choice == 'share') {
            await PdfReportService.shareCollectionAccountReport(
              provider: provider,
              account: account,
              filter: filter,
            );
          } else {
            await PdfReportService.printCollectionAccountReport(
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
    CollectionAccount account,
    List<ChandaSlip> allSlips,
    NumberFormat currency,
  ) {
    final paidSlips = allSlips.where((s) => s.isFullyPaid).toList();
    final unpaidSlips = allSlips.where((s) => s.isUnpaid || s.pendingAmount > 0).toList();

    final totalPledged = allSlips.fold<double>(0.0, (sum, s) => sum + s.amount);
    final totalPaid = allSlips.fold<double>(0.0, (sum, s) => sum + s.paidAmount);
    final totalDue = allSlips.fold<double>(0.0, (sum, s) => sum + s.pendingAmount);

    return PopupMenuButton<CollectionAccountPdfFilter>(
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
          value: CollectionAccountPdfFilter.all,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_rounded, size: 16, color: Color(0xFF60A5FA)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('All Contributors', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('All (${allSlips.length}) • ${currency.format(totalPledged)}', style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: CollectionAccountPdfFilter.onlyUnpaid,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFFB7185)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Only Unpaid (Pending Dues)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Due (${unpaidSlips.length}) • ${currency.format(totalDue)}', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: CollectionAccountPdfFilter.onlyPaid,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF34D399)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Only Paid (Fully Cleared)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Paid (${paidSlips.length}) • ${currency.format(totalPaid)}', style: const TextStyle(color: Color(0xFF34D399), fontSize: 11)),
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
          color: const Color(0xFF10B981).withAlpha(25),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(110)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF34D399)),
            SizedBox(width: 8),
            Text(
              'Generate PDF',
              style: TextStyle(
                color: Color(0xFF34D399),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF34D399)),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOptionsMenu(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    List<ChandaSlip> allSlips,
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
            value: 'transactions',
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Transactions Log', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
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
          if (val == 'transactions') {
            showDialog(
              context: context,
              builder: (_) => AccountTransactionsDialog(account: account, slips: allSlips),
            );
          } else if (val == 'edit') {
            showDialog(
              context: context,
              builder: (_) => AddCollectionAccountDialog(existing: account),
            );
          } else if (val == 'delete') {
            _confirmDeleteAccount(context, provider, account);
          }
        },
      ),
    );
  }

  void _showSlipPdfOptions(BuildContext context, ChandaSlip slip, PujaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.glassBorder),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Chanda Receipt PDF', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${slip.donorName} • Slip #${slip.slipNumber}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white54),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white12),
              ),
              tileColor: const Color(0x1F1E293B),
              leading: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.print_rounded, color: Color(0xFF38BDF8), size: 18),
              ),
              title: const Text('View & Print / Save PDF', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Preview receipt with Print & Save options', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                ReceiptShareService.printSlipPdf(
                  slip: slip,
                  pujaName: provider.pujaName,
                  currentYear: provider.currentYear,
                  cashierName: provider.cashierName,
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.white12),
              ),
              tileColor: const Color(0x1F1E293B),
              leading: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_rounded, color: Color(0xFF10B981), size: 18),
              ),
              title: const Text('Share PDF File', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Send PDF via WhatsApp, Email, Drive, etc.', style: TextStyle(color: Colors.white54, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                ReceiptShareService.shareSlipPdf(
                  slip: slip,
                  pujaName: provider.pujaName,
                  currentYear: provider.currentYear,
                  cashierName: provider.cashierName,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Retrieve active account
    final account = provider.collectionAccounts.firstWhere(
      (a) => a.id == widget.accountId,
      orElse: () => CollectionAccount(
        id: widget.accountId,
        accountName: 'Collection Account',
        areaName: 'Area',
      ),
    );

    final allSlips = provider.getAccountSlips(account.id);
    final totalPledged = provider.getAccountTotalPledged(account.id);
    final totalPaid = provider.getAccountTotalPaid(account.id);
    final totalUnpaid = provider.getAccountTotalUnpaid(account.id);
    final paidCount = provider.getAccountPaidCount(account.id);
    final unpaidCount = provider.getAccountUnpaidCount(account.id);
    final partialCount = provider.getAccountPartialCount(account.id);

    // Apply filters & search
    final query = _searchQuery.trim().toLowerCase();
    final filteredSlips = allSlips.where((s) {
      final matchesStatus = _statusFilter == null || s.status == _statusFilter;
      final matchesSearch = query.isEmpty ||
          s.donorName.toLowerCase().contains(query) ||
          (s.phone != null && s.phone!.contains(query)) ||
          (s.address != null && s.address!.toLowerCase().contains(query)) ||
          s.slipNumber.toString().contains(query) ||
          s.amount.toString().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    // Apply Sorting Sequence
    filteredSlips.sort((a, b) {
      switch (_currentSort) {
        case ContributorSortOption.numberAsc:
          return a.slipNumber.compareTo(b.slipNumber);
        case ContributorSortOption.numberDesc:
          return b.slipNumber.compareTo(a.slipNumber);
        case ContributorSortOption.nameAsc:
          return a.donorName.trim().toLowerCase().compareTo(b.donorName.trim().toLowerCase());
        case ContributorSortOption.nameDesc:
          return b.donorName.trim().toLowerCase().compareTo(a.donorName.trim().toLowerCase());
        case ContributorSortOption.amountDesc:
          final cmp = b.amount.compareTo(a.amount);
          return cmp != 0 ? cmp : a.slipNumber.compareTo(b.slipNumber);
        case ContributorSortOption.amountAsc:
          final cmp = a.amount.compareTo(b.amount);
          return cmp != 0 ? cmp : a.slipNumber.compareTo(b.slipNumber);
        case ContributorSortOption.dueDesc:
          final cmp = b.pendingAmount.compareTo(a.pendingAmount);
          return cmp != 0 ? cmp : a.slipNumber.compareTo(b.slipNumber);
        case ContributorSortOption.dateDesc:
          final cmp = b.createdAt.compareTo(a.createdAt);
          return cmp != 0 ? cmp : b.slipNumber.compareTo(a.slipNumber);
        case ContributorSortOption.dateAsc:
          final cmp = a.createdAt.compareTo(b.createdAt);
          return cmp != 0 ? cmp : a.slipNumber.compareTo(b.slipNumber);
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background ambient light circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withAlpha(18),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withAlpha(15),
              ),
            ),
          ),

          SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(
                    context,
                    provider,
                    account,
                    allSlips,
                    filteredSlips,
                    totalPledged,
                    totalPaid,
                    totalUnpaid,
                    paidCount,
                    unpaidCount,
                    partialCount,
                    currency,
                  )
                : _buildMobileLayout(
                    context,
                    provider,
                    account,
                    allSlips,
                    filteredSlips,
                    totalPledged,
                    totalPaid,
                    totalUnpaid,
                    paidCount,
                    unpaidCount,
                    partialCount,
                    currency,
                  ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP (PC) LAYOUT: Proper structured toolbar, 4-KPI cards, Grid/Table toggle
  // ===========================================================================
  Widget _buildDesktopLayout(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    List<ChandaSlip> allSlips,
    List<ChandaSlip> filteredSlips,
    double totalPledged,
    double totalPaid,
    double totalUnpaid,
    int paidCount,
    int unpaidCount,
    int partialCount,
    NumberFormat currency,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    const hPadding = 28.0;

    return CustomScrollView(
      slivers: [
        // 1. Desktop Top Navigation Header
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 12),
            child: Row(
              children: [
                // Back Button
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
                    label: const Text('Back to Books', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 16),

                // Account Title & Badges
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

                      // Area Tag
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
                            const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              account.areaName,
                              style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                      // Book & SL Range Tag
                      if (account.bookNumber != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                account.bookSlipRangeText,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Collector Tag
                      if (account.collectorName != null && account.collectorName!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF10B981)),
                              const SizedBox(width: 4),
                              Text(
                                'Collector: ${account.collectorName}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Top-Right Actions
                _buildPdfDropdownButton(context, provider, account, allSlips, currency),
                const SizedBox(width: 10),

                _buildAccountOptionsMenu(context, provider, account, allSlips),
                const SizedBox(width: 12),

                // 4. Primary Desktop Button: + Add Contributor
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0xFF10B981).withAlpha(90),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AddContributorDialog(account: account),
                  ),
                  icon: const Icon(Icons.person_add_rounded, size: 17),
                  label: const Text(
                    '+ Add Contributor',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Desktop 4-KPI Metric Row
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 14),
            child: _buildDesktopKpis(
              totalPledged,
              totalPaid,
              totalUnpaid,
              allSlips.length,
              paidCount,
              unpaidCount,
              partialCount,
              account,
              currency,
            ),
          ),
        ),

        // 3. Desktop Unified Control Toolbar (Search, Filter, Mode toggle)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 12),
            child: _buildDesktopToolbar(
              account,
              allSlips,
              allSlips.length,
              filteredSlips.length,
              paidCount,
              unpaidCount,
              partialCount,
            ),
          ),
        ),

        // 4. Desktop Main Content: Table or Multi-Column Grid
        if (filteredSlips.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 40),
              child: _buildEmptyState(account, allSlips.isEmpty),
            ),
          )
        else if (_isTableView)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 30),
            sliver: _buildDesktopDataTable(context, provider, account, filteredSlips, currency),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 30),
            sliver: _buildDesktopCardGrid(context, provider, account, filteredSlips, currency, screenWidth),
          ),
      ],
    );
  }

  // Desktop 4-KPI Row
  Widget _buildDesktopKpis(
    double totalPledged,
    double totalPaid,
    double totalUnpaid,
    int totalContributors,
    int paidCount,
    int unpaidCount,
    int partialCount,
    CollectionAccount account,
    NumberFormat currency,
  ) {
    final percent = totalPledged > 0 ? ((totalPaid / totalPledged) * 100).clamp(0.0, 100.0) : 0.0;

    return Row(
      children: [
        // 1. Total Chanda (Pledged)
        Expanded(
          child: _buildDesktopKpiCard(
            title: 'TOTAL CHANDA',
            value: currency.format(totalPledged),
            subtitle: '$totalContributors Contributors',
            icon: Icons.volunteer_activism_rounded,
            color: AppTheme.primaryBlue,
            gradientColors: [const Color(0xFF0C2340), const Color(0xFF091428)],
          ),
        ),
        const SizedBox(width: 12),

        // 2. Paid (Jama)
        Expanded(
          child: _buildDesktopKpiCard(
            title: 'PAID (JAMA)',
            value: currency.format(totalPaid),
            subtitle: '$paidCount Fully Paid',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            gradientColors: [const Color(0xFF062A1F), const Color(0xFF061B16)],
          ),
        ),
        const SizedBox(width: 12),

        // 3. Unpaid (Baki Due)
        Expanded(
          child: _buildDesktopKpiCard(
            title: 'UNPAID (BAKI)',
            value: currency.format(totalUnpaid),
            subtitle: '$unpaidCount Due • $partialCount Partial',
            icon: Icons.hourglass_top_rounded,
            color: const Color(0xFFEF4444),
            gradientColors: [const Color(0xFF2E0D17), const Color(0xFF1B070E)],
          ),
        ),
        const SizedBox(width: 12),

        // 4. Progress & Target Card
        Expanded(
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: const Color(0xFF10B981).withAlpha(50), width: 1.2),
            gradient: const LinearGradient(
              colors: [Color(0xFF0B2524), Color(0xFF08151D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('COLLECTION PROGRESS', style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalPledged > 0 ? (totalPaid / totalPledged).clamp(0.0, 1.0) : 0.0,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  account.targetAmount != null && account.targetAmount! > 0
                      ? 'Target: ${currency.format(account.targetAmount!)}'
                      : 'Target: Not Set',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
  }) {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(14),
      border: Border.all(color: color.withAlpha(50), width: 1.2),
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(title, style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Desktop Unified Toolbar
  Widget _buildDesktopToolbar(
    CollectionAccount account,
    List<ChandaSlip> allSlips,
    int allCount,
    int filteredCount,
    int paidCount,
    int unpaidCount,
    int partialCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xD90A1128),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Compact Search Input
          SizedBox(
            width: 290,
            height: 38,
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12.5),
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search donor, phone, slip...',
                hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 17),
                filled: true,
                fillColor: const Color(0x1F1E293B),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Filter status chips
          _buildFilterChip(null, 'All ($allCount)', Colors.white70),
          const SizedBox(width: 6),
          _buildFilterChip(DonationStatus.paid, 'Paid ($paidCount)', const Color(0xFF10B981)),
          const SizedBox(width: 6),
          _buildFilterChip(DonationStatus.unpaid, 'Unpaid ($unpaidCount)', const Color(0xFFEF4444)),
          const SizedBox(width: 6),
          _buildFilterChip(DonationStatus.partial, 'Partial ($partialCount)', const Color(0xFFF59E0B)),

          const SizedBox(width: 12),
          Container(width: 1, height: 20, color: Colors.white12),
          const SizedBox(width: 12),

          // Desktop Sort Selector Dropdown
          _buildDesktopSortSelector(),

          const Spacer(),

          // Transactions Log Button
          Tooltip(
            message: 'All Transactions & Collection History',
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () => showDialog(
                context: context,
                builder: (_) => AccountTransactionsDialog(account: account, slips: allSlips),
              ),
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(20),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 5),
                    Text(
                      'Transactions Log',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Showing Count Label
          Text(
            'Showing $filteredCount of $allCount',
            style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),

          // View Mode Switcher
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
          color: isSelected ? const Color(0xFF10B981).withAlpha(35) : Colors.transparent,
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? const Color(0xFF10B981) : Colors.white60,
          ),
        ),
      ),
    );
  }

  // Desktop Responsive Card Grid
  Widget _buildDesktopCardGrid(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    List<ChandaSlip> slips,
    NumberFormat currency,
    double screenWidth,
  ) {
    final crossAxisCount = screenWidth > 1600 ? 4 : (screenWidth > 1150 ? 3 : 2);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 258, // Ample breathing space: 0px overflow guaranteed
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slip = slips[index];
          return _buildContributorCard(context, provider, account, slip, currency, isGrid: true);
        },
        childCount: slips.length,
      ),
    );
  }

  // Desktop Data Table View - Executive Structured Layout
  Widget _buildDesktopDataTable(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    List<ChandaSlip> slips,
    NumberFormat currency,
  ) {
    return SliverToBoxAdapter(
      child: GlassContainer(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        border: Border.all(color: const Color(0x3B60A5FA), width: 1.2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  border: Border(bottom: BorderSide(color: Color(0x3338BDF8), width: 1.2)),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 48, child: Text('#', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 3, child: Text('CONTRIBUTOR', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('CONTACT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('DATE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('CHANDA DIYA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('PAID (JAMA)', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('DUE (BAKI)', style: TextStyle(color: Color(0xFFFB7185), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 1, child: Text('MODE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    Expanded(flex: 2, child: Text('STATUS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                    SizedBox(width: 175, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                  ],
                ),
              ),

              // Data Rows
              ...List.generate(slips.length, (index) {
                final slip = slips[index];
                final isEven = index % 2 == 0;
                final isPaid = slip.isFullyPaid;
                final isPartial = slip.isPartial;

                final statusColor = isPaid
                    ? const Color(0xFF10B981)
                    : (isPartial ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

                final statusBg = isPaid
                    ? const Color(0x2610B981)
                    : (isPartial ? const Color(0x26F59E0B) : const Color(0x26EF4444));

                final statusBorder = isPaid
                    ? const Color(0x7310B981)
                    : (isPartial ? const Color(0x73F59E0B) : const Color(0x73EF4444));

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => showChandaSlipDetails(context, slip, account: account),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    color: isEven ? Colors.transparent : Colors.white.withAlpha(5),
                    border: Border(top: BorderSide(color: Colors.white.withAlpha(14))),
                  ),
                  child: Row(
                    children: [
                      // # Slip Number Pill
                      SizedBox(
                        width: 48,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${slip.slipNumber}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Contributor Info (Avatar + Name + Subtitle)
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor.withAlpha(25),
                                border: Border.all(color: statusColor.withAlpha(80), width: 1.2),
                              ),
                              child: Center(
                                child: Text(
                                  slip.donorName.isNotEmpty ? slip.donorName[0].toUpperCase() : '?',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: statusColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slip.donorName,
                                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (slip.bookNumber > 0)
                                    Text(
                                      'Book #${slip.bookNumber}',
                                      style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 10.5, fontWeight: FontWeight.w500),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contact Phone Number
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            if (slip.phone != null && slip.phone!.isNotEmpty) ...[
                              Icon(Icons.phone_rounded, size: 12, color: Colors.white.withAlpha(130)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  slip.phone!,
                                  style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ] else
                              Text('—', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 12)),
                          ],
                        ),
                      ),

                      // Payment Date
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white.withAlpha(130)),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM yyyy').format(slip.paymentDate ?? slip.createdAt),
                              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      // Amount Pledged (Chanda Diya)
                      Expanded(
                        flex: 2,
                        child: Text(
                          currency.format(slip.amount),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),

                      // Paid Amount (Jama)
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currency.format(slip.paidAmount),
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                      // Pending Amount (Due / Baki)
                      Expanded(
                        flex: 2,
                        child: slip.pendingAmount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withAlpha(20),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currency.format(slip.pendingAmount),
                                  style: const TextStyle(color: Color(0xFFFB7185), fontSize: 13, fontWeight: FontWeight.w900),
                                ),
                              )
                            : Text(
                                '₹0',
                                style: TextStyle(color: Colors.white.withAlpha(70), fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                      ),

                      // Payment Mode Badge
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Text(
                            slip.paymentMode.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                      // Soft Status Indicator Badge
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusBorder),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  slip.status.displayName.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Clean Action Group (Primary Button + Secondary Popup Menu)
                      SizedBox(
                        width: 175,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Primary Action Button: Collect Due or PDF Receipt
                            if (!isPaid)
                              InkWell(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => CollectDueDialog(slip: slip),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withAlpha(70),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 3),
                                      Text(
                                        'Collect',
                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              InkWell(
                                onTap: () => _showSlipPdfOptions(context, slip, provider),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8).withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF38BDF8).withAlpha(80)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, size: 13, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Receipt',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(width: 6),

                            // Secondary Options Popup Menu (3 Dots)
                            PopupMenuButton<String>(
                              tooltip: 'More Actions',
                              icon: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(12),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: Colors.white.withAlpha(20)),
                                ),
                                child: const Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white70),
                              ),
                              color: const Color(0xFF0F172A),
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: AppTheme.glassBorder),
                              ),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'details',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF38BDF8)),
                                      SizedBox(width: 10),
                                      Text('View Details', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'history',
                                  child: Row(
                                    children: [
                                      Icon(Icons.history_rounded, size: 16, color: Color(0xFF34D399)),
                                      SizedBox(width: 10),
                                      Text('Payment History', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFEF4444)),
                                      SizedBox(width: 10),
                                      Text('Generate PDF', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined, size: 16, color: AppTheme.goldAccent),
                                      SizedBox(width: 10),
                                      Text('Edit Contributor', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
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
                                      Text('Delete Entry', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (val) {
                                if (val == 'details') {
                                  showChandaSlipDetails(context, slip, account: account);
                                } else if (val == 'history') {
                                  showDialog(
                                    context: context,
                                    builder: (_) => ContributorPaymentHistoryDialog(slip: slip),
                                  );
                                } else if (val == 'pdf') {
                                  _showSlipPdfOptions(context, slip, provider);
                                } else if (val == 'edit') {
                                  showDialog(
                                    context: context,
                                    builder: (_) => AddContributorDialog(account: account, existingSlip: slip),
                                  );
                                } else if (val == 'delete') {
                                  provider.deleteDonation(slip.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
  // MOBILE (PHONE) LAYOUT: Compact vertical touch-friendly flow
  // ===========================================================================
  Widget _buildMobileLayout(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    List<ChandaSlip> allSlips,
    List<ChandaSlip> filteredSlips,
    double totalPledged,
    double totalPaid,
    double totalUnpaid,
    int paidCount,
    int unpaidCount,
    int partialCount,
    NumberFormat currency,
  ) {
    const horizontalPadding = 16.0;

    return CustomScrollView(
      slivers: [
        // Mobile App Bar
        SliverToBoxAdapter(
          child: Container(
            height: 54,
            margin: const EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 6),
            child: Row(
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0x1F1E293B),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        account.accountName,
                        style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFF10B981)),
                              const SizedBox(width: 2.5),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 130),
                                child: Text(
                                  account.areaName,
                                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (account.bookNumber != null) ...[
                            const Text('•', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_rounded, size: 11, color: Color(0xFF10B981)),
                                const SizedBox(width: 2.5),
                                Text(
                                  account.bookSlipRangeText,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                          if (account.collectorName != null && account.collectorName!.isNotEmpty) ...[
                            const Text('•', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, size: 11, color: AppTheme.primaryBlue),
                                const SizedBox(width: 2.5),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 110),
                                  child: Text(
                                    account.collectorName!,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // PDF Generate Menu Button
                PopupMenuButton<CollectionAccountPdfFilter>(
                  tooltip: 'Generate PDF Report',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, size: 17, color: Color(0xFF34D399)),
                  ),
                  color: const Color(0xFF0F172A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppTheme.glassBorder),
                  ),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: CollectionAccountPdfFilter.all,
                      child: Row(
                        children: [
                          Icon(Icons.description_rounded, size: 16, color: Color(0xFF60A5FA)),
                          SizedBox(width: 8),
                          Text('All Contributors', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CollectionAccountPdfFilter.onlyUnpaid,
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded, size: 16, color: Color(0xFFFB7185)),
                          SizedBox(width: 8),
                          Text('Only Unpaid (Due)', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: CollectionAccountPdfFilter.onlyPaid,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF34D399)),
                          SizedBox(width: 8),
                          Text('Only Paid', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (filter) => _handleGeneratePdf(context, provider, account, filter),
                ),

                // 3-Dots Options Popup Menu
                PopupMenuButton<String>(
                  tooltip: 'Account Options',
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                  color: const Color(0xFF0F172A),
                  elevation: 12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppTheme.glassBorder)),
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'transactions',
                      child: Row(
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Text('Transactions Log', style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(height: 1),
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
                    if (val == 'transactions') {
                      showDialog(
                        context: context,
                        builder: (_) => AccountTransactionsDialog(account: account, slips: allSlips),
                      );
                    } else if (val == 'edit') {
                      showDialog(
                        context: context,
                        builder: (_) => AddCollectionAccountDialog(existing: account),
                      );
                    } else if (val == 'delete') {
                      _confirmDeleteAccount(context, provider, account);
                    }
                  },
                ),
              ],
            ),
          ),
        ),

        // Mobile Financial KPI Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 8),
            child: GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(16),
              border: Border.all(color: const Color(0xFF10B981).withAlpha(80), width: 1.2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF062A1F),
                  Color(0xFF091F38),
                  Color(0xFF0A1128),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collector & Target Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_rounded, size: 11, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              account.collectorName != null && account.collectorName!.isNotEmpty
                                  ? 'Collector: ${account.collectorName}'
                                  : 'Collection Account',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                      if (account.targetAmount != null && account.targetAmount! > 0)
                        Text(
                          'Target: ${currency.format(account.targetAmount!)}',
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160), fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3 Pillars: Chanda Diya, Paid, Unpaid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x1F3B82F6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withAlpha(40)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.volunteer_activism_rounded, size: 11, color: AppTheme.primaryBlue),
                                  SizedBox(width: 3),
                                  Text('Total Chanda', style: TextStyle(fontSize: 10, color: Colors.white70)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currency.format(totalPledged),
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x1F10B981),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                                  SizedBox(width: 3),
                                  Text('Paid (Jama)', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currency.format(totalPaid),
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0x1FEF4444),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withAlpha(50)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.hourglass_top_rounded, size: 11, color: Color(0xFFEF4444)),
                                  SizedBox(width: 3),
                                  Text('Unpaid (Due)', style: TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currency.format(totalUnpaid),
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: totalUnpaid > 0 ? const Color(0xFFEF4444) : Colors.white38,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${allSlips.length} Contributors ($paidCount Paid • $unpaidCount Due • $partialCount Partial)',
                            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(170), fontWeight: FontWeight.w500),
                          ),
                          Text(
                            totalPledged > 0
                                ? '${((totalPaid / totalPledged) * 100).clamp(0, 100).toStringAsFixed(1)}%'
                                : '0%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalPledged > 0 ? (totalPaid / totalPledged).clamp(0.0, 1.0) : 0.0,
                          minHeight: 6,
                          backgroundColor: Colors.white.withAlpha(20),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Mobile Action Button: "+ Add Contributor"
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AddContributorDialog(account: account),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 19),
                  SizedBox(width: 8),
                  Text(
                    '+ Add Contributor / Chanda Entry',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Mobile Search Box
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
            child: SizedBox(
              height: 38,
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search contributor name, phone, slip number...',
                  hintStyle: TextStyle(color: Colors.white.withAlpha(110), fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF10B981), size: 17),
                  filled: true,
                  fillColor: const Color(0xD9081022),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981))),
                ),
              ),
            ),
          ),
        ),

        // Mobile Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 2),
              children: [
                _buildFilterChip(null, 'All (${allSlips.length})', Colors.white70),
                const SizedBox(width: 6),
                _buildFilterChip(DonationStatus.paid, 'Paid ($paidCount)', const Color(0xFF10B981)),
                const SizedBox(width: 6),
                _buildFilterChip(DonationStatus.unpaid, 'Unpaid ($unpaidCount)', const Color(0xFFEF4444)),
                const SizedBox(width: 6),
                _buildFilterChip(DonationStatus.partial, 'Partial ($partialCount)', const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ),

        // Mobile Sequence & Sorting Quick Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 5, horizontalPadding, 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildQuickSortChip(
                          label: _isSortSlipNumber
                              ? (_currentSort == ContributorSortOption.numberAsc ? 'Slip # (1→9) ↑' : 'Slip # (9→1) ↓')
                              : 'Slip #',
                          icon: Icons.tag_rounded,
                          isActive: _isSortSlipNumber,
                          onTap: () {
                            setState(() {
                              if (_currentSort == ContributorSortOption.numberAsc) {
                                _currentSort = ContributorSortOption.numberDesc;
                              } else {
                                _currentSort = ContributorSortOption.numberAsc;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickSortChip(
                          label: _isSortName
                              ? (_currentSort == ContributorSortOption.nameAsc ? 'Name (A→Z) ↑' : 'Name (Z→A) ↓')
                              : 'Name (A-Z)',
                          icon: Icons.sort_by_alpha_rounded,
                          isActive: _isSortName,
                          onTap: () {
                            setState(() {
                              if (_currentSort == ContributorSortOption.nameAsc) {
                                _currentSort = ContributorSortOption.nameDesc;
                              } else {
                                _currentSort = ContributorSortOption.nameAsc;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickSortChip(
                          label: _isSortAmount
                              ? (_currentSort == ContributorSortOption.amountDesc ? 'Amount (High) ↓' : 'Amount (Low) ↑')
                              : 'Amount',
                          icon: Icons.currency_rupee_rounded,
                          isActive: _isSortAmount,
                          onTap: () {
                            setState(() {
                              if (_currentSort == ContributorSortOption.amountDesc) {
                                _currentSort = ContributorSortOption.amountAsc;
                              } else {
                                _currentSort = ContributorSortOption.amountDesc;
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickSortChip(
                          label: _currentSort == ContributorSortOption.dueDesc ? 'Due Balance ↓' : 'Due Balance',
                          icon: Icons.hourglass_top_rounded,
                          isActive: _currentSort == ContributorSortOption.dueDesc,
                          onTap: () {
                            setState(() {
                              _currentSort = ContributorSortOption.dueDesc;
                            });
                          },
                        ),
                        const SizedBox(width: 6),
                        _buildQuickSortChip(
                          label: _isSortDate
                              ? (_currentSort == ContributorSortOption.dateDesc ? 'Date (New) ↓' : 'Date (Old) ↑')
                              : 'Date',
                          icon: Icons.calendar_today_rounded,
                          isActive: _isSortDate,
                          onTap: () {
                            setState(() {
                              if (_currentSort == ContributorSortOption.dateDesc) {
                                _currentSort = ContributorSortOption.dateAsc;
                              } else {
                                _currentSort = ContributorSortOption.dateDesc;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Detailed Sort Modal Button
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showSortModalBottomSheet(context),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune_rounded, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text('Sort', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 6)),

        // Mobile 1-Column Contributor List
        if (filteredSlips.isEmpty)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: _buildEmptyState(account, allSlips.isEmpty),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final slip = filteredSlips[index];
                  return _buildContributorCard(context, provider, account, slip, currency);
                },
                childCount: filteredSlips.length,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // SHARED WIDGETS
  // ===========================================================================
  Widget _buildEmptyState(CollectionAccount account, bool isCompletelyEmpty) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.people_outline_rounded, size: 44, color: Colors.white.withAlpha(50)),
        const SizedBox(height: 10),
        Text(
          isCompletelyEmpty
              ? 'No contributors added to this account yet.'
              : 'No contributors match your search.',
          style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13),
        ),
        if (isCompletelyEmpty) ...[
          const SizedBox(height: 14),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Contributor', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AddContributorDialog(account: account),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFilterChip(DonationStatus? status, String label, Color color) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(40) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppTheme.glassBorder,
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

  Widget _buildQuickSortChip({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981).withAlpha(35) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF10B981) : AppTheme.glassBorder,
            width: isActive ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isActive ? const Color(0xFF10B981) : Colors.white60,
            ),
            const SizedBox(width: 4.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSortSelector() {
    return PopupMenuButton<ContributorSortOption>(
      tooltip: 'Sort Contributors Sequence',
      color: const Color(0xFF0F172A),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      offset: const Offset(0, 42),
      itemBuilder: (ctx) => ContributorSortOption.values.map((opt) {
        final isSel = _currentSort == opt;
        return PopupMenuItem<ContributorSortOption>(
          value: opt,
          height: 42,
          child: Row(
            children: [
              Icon(opt.icon, size: 16, color: isSel ? const Color(0xFF10B981) : Colors.white60),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? const Color(0xFF10B981) : Colors.white,
                      ),
                    ),
                    Text(
                      opt.hindiSubtitle,
                      style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140)),
                    ),
                  ],
                ),
              ),
              if (isSel)
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)),
            ],
          ),
        );
      }).toList(),
      onSelected: (opt) => setState(() => _currentSort = opt),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 15, color: Color(0xFF10B981)),
            const SizedBox(width: 6),
            Text(
              'Sort: ${_currentSort.shortLabel}',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFF10B981)),
          ],
        ),
      ),
    );
  }

  void _showSortModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Color(0x3310B981)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sort Contributors Sequence',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select sequence for ordering chanda slips',
                          style: TextStyle(color: Colors.white54, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 8),

              // Options list with grouped sections
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.65,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSortSectionHeader('SLIP NUMBER (SERIAL)'),
                      _buildSortOptionTile(ctx, ContributorSortOption.numberAsc),
                      _buildSortOptionTile(ctx, ContributorSortOption.numberDesc),
                      const SizedBox(height: 10),

                      _buildSortSectionHeader('CONTRIBUTOR NAME'),
                      _buildSortOptionTile(ctx, ContributorSortOption.nameAsc),
                      _buildSortOptionTile(ctx, ContributorSortOption.nameDesc),
                      const SizedBox(height: 10),

                      _buildSortSectionHeader('CHANDA AMOUNT & DUE BALANCE'),
                      _buildSortOptionTile(ctx, ContributorSortOption.amountDesc),
                      _buildSortOptionTile(ctx, ContributorSortOption.amountAsc),
                      _buildSortOptionTile(ctx, ContributorSortOption.dueDesc),
                      const SizedBox(height: 10),

                      _buildSortSectionHeader('DATE RECORDED'),
                      _buildSortOptionTile(ctx, ContributorSortOption.dateDesc),
                      _buildSortOptionTile(ctx, ContributorSortOption.dateAsc),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF10B981),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSortOptionTile(BuildContext ctx, ContributorSortOption option) {
    final isSelected = _currentSort == option;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF10B981).withAlpha(30) : const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF10B981) : AppTheme.glassBorder,
          width: isSelected ? 1.4 : 1.0,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981).withAlpha(40) : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(option.icon, size: 16, color: isSelected ? const Color(0xFF10B981) : Colors.white70),
        ),
        title: Text(
          option.title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withAlpha(220),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          option.hindiSubtitle,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6EE7B7) : Colors.white38,
            fontSize: 11,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20)
            : const Icon(Icons.circle_outlined, color: Colors.white24, size: 18),
        onTap: () {
          setState(() => _currentSort = option);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Widget _buildContributorCard(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    ChandaSlip slip,
    NumberFormat currency, {
    bool isGrid = false,
  }) {
    final isPaid = slip.isFullyPaid;
    final isPartial = slip.isPartial;
    final statusColor = isPaid
        ? const Color(0xFF10B981)
        : (isPartial ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => showChandaSlipDetails(context, slip, account: account),
          child: GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            border: Border.all(color: statusColor.withAlpha(70), width: 1.2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. TOP HEADER: Sl No (Left) <---> Status Badge & Menu (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Serial / Slip Number Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF38BDF8).withAlpha(140), width: 1.1),
                      ),
                      child: Text(
                        '#${slip.slipNumber}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    // Right: In-Kind Pill + Status Badge + 3-Dots Menu
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (slip.isInKind) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(90)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_rounded, size: 10, color: slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)),
                                const SizedBox(width: 3.5),
                                Text(
                                  'KIND',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: slip.inKindCategory?.color ?? const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Status Badge (Paid / Unpaid / Partial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(28),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withAlpha(90), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(slip.status.icon, size: 11.5, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                slip.status.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 2),

                        // 3-dots Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, size: 19, color: Colors.white70),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.glassBorder)),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility_rounded, size: 15, color: Color(0xFF38BDF8)),
                                  SizedBox(width: 8),
                                  Text('View Full Details', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'history',
                              child: Row(
                                children: [
                                  Icon(Icons.history_rounded, size: 15, color: Color(0xFF34D399)),
                                  SizedBox(width: 8),
                                  Text('Payment History', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'pdf',
                              child: Row(
                                children: [
                                  Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFFEF4444)),
                                  SizedBox(width: 8),
                                  Text('Generate PDF', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 15, color: AppTheme.goldAccent),
                                  SizedBox(width: 8),
                                  Text('Edit Entry', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 15, color: AppTheme.dangerRose),
                                  SizedBox(width: 8),
                                  Text('Delete Entry', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12.5)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (val) {
                            if (val == 'details') {
                              showChandaSlipDetails(context, slip, account: account);
                            } else if (val == 'history') {
                              showDialog(
                                context: context,
                                builder: (_) => ContributorPaymentHistoryDialog(slip: slip),
                              );
                            } else if (val == 'pdf') {
                              _showSlipPdfOptions(context, slip, provider);
                            } else if (val == 'edit') {
                              showDialog(
                                context: context,
                                builder: (_) => AddContributorDialog(account: account, existingSlip: slip),
                              );
                            } else if (val == 'delete') {
                              provider.deleteDonation(slip.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 2. CONTRIBUTOR FULL NAME & DETAILS (Dedicated Row)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Circle
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(color: statusColor.withAlpha(90), width: 1.3),
                      ),
                      child: Center(
                        child: Text(
                          slip.donorName.isNotEmpty ? slip.donorName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: statusColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Donor Name & Subtitle Info (Full Width)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slip.donorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              if (slip.phone != null && slip.phone!.isNotEmpty) ...[
                                Icon(Icons.phone_rounded, size: 11, color: Colors.white.withAlpha(140)),
                                const SizedBox(width: 3),
                                Text(
                                  slip.phone!,
                                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160), fontWeight: FontWeight.w500),
                                ),
                                const Text(' • ', style: TextStyle(color: Colors.white24)),
                              ],
                              Text(
                                DateFormat('dd MMM yyyy').format(slip.paymentDate ?? slip.createdAt),
                                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(130)),
                              ),
                              if (slip.address != null && slip.address!.isNotEmpty) ...[
                                const Text(' • ', style: TextStyle(color: Colors.white24)),
                                Flexible(
                                  child: Text(
                                    slip.address!,
                                    style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(130)),
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
                const SizedBox(height: 10),

                // 3. SYSTEMATIC 3-PILLAR FINANCIAL METRICS OR IN-KIND CARD
                if (slip.isInKind) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x1F0F172A),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(70)),
                    ),
                    child: Row(
                      children: [
                        Icon(slip.inKindCategory?.icon ?? Icons.inventory_2_rounded, size: 16, color: slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                slip.inKindItemName ?? 'Samagri Item',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${slip.inKindCategory?.displayName.split(' (')[0] ?? 'In-Kind'} • Qty: ${slip.inKindQuantity ?? '1 unit'}',
                                style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(160)),
                              ),
                            ],
                          ),
                        ),
                        if (slip.amount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF10B981).withAlpha(70)),
                            ),
                            child: Text(
                              currency.format(slip.amount),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1F0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorderLight.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Column 1: Chanda Diya
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CHANDA DIYA', style: TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(currency.format(slip.amount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Colors.white)),
                              ],
                            ),
                            Container(height: 20, width: 1, color: Colors.white24),

                            // Column 2: Paid (Jama)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('PAID (JAMA)', style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(currency.format(slip.paidAmount), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                              ],
                            ),
                            Container(height: 20, width: 1, color: Colors.white24),

                            // Column 3: Unpaid (Baki)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('UNPAID (BAKI)', style: TextStyle(fontSize: 9, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(
                                  currency.format(slip.pendingAmount),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: slip.pendingAmount > 0 ? const Color(0xFFEF4444) : Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isPartial) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (slip.paidAmount / slip.amount).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 9),

                // 4. ROW: Payment Mode, Details & Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Payment Mode / Kind chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: slip.isInKind
                            ? (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6)).withAlpha(20)
                            : Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            slip.isInKind
                                ? (slip.inKindCategory?.icon ?? Icons.card_giftcard_rounded)
                                : Icons.payment_rounded,
                            size: 10.5,
                            color: slip.isInKind
                                ? (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6))
                                : Colors.white60,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            slip.isInKind
                                ? (slip.inKindQuantity ?? 'SAMAGRI')
                                : slip.paymentMode.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              color: slip.isInKind
                                  ? (slip.inKindCategory?.color ?? const Color(0xFF8B5CF6))
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Details hint
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_rounded, size: 11, color: Colors.white.withAlpha(100)),
                            const SizedBox(width: 2),
                            Text(
                              'Details',
                              style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // Generate PDF Receipt Slip
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showSlipPdfOptions(context, slip, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withAlpha(60)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.picture_as_pdf_rounded, size: 11, color: Color(0xFFEF4444)),
                                SizedBox(width: 4),
                                Text('PDF Receipt', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                              ],
                            ),
                          ),
                        ),

                        // Collect Due Action (if unpaid or partial)
                        if (!isPaid) ...[
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => CollectDueDialog(slip: slip),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments_rounded, size: 11, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Collect Due', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
