import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/advance_account_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';
import 'collection_account_detail_screen.dart';
import 'expenditure_account_detail_screen.dart';

class ChandaBooksScreen extends StatefulWidget {
  final VoidCallback? onBackToEvents;
  final String? initialEventId;

  const ChandaBooksScreen({super.key, this.onBackToEvents, this.initialEventId});

  @override
  State<ChandaBooksScreen> createState() => _ChandaBooksScreenState();
}

// Sort cycle: 0=Book# Asc, 1=Book# Desc, 2=Name A-Z, 3=Name Z-A, 4=Amount High-Low, 5=Amount Low-High
enum _AccountSortMode { bookAsc, bookDesc, nameAsc, nameDesc, amountDesc, amountAsc }

class _ChandaBooksScreenState extends State<ChandaBooksScreen> {
  DonationStatus? _selectedStatusFilter;
  String? _selectedCollectorFilter;
  String _searchQuery = '';
  String _advanceStatusFilter = 'All'; // 'All', 'Pending', 'Settled'
  int _viewMode = 0; // 0: Event Chanda, 1: Event Expenses, 2: Event Advances, 3: Top Donors
  int _chandaSubTab = 0; // 0: Collection Accounts, 1: All Slips
  int _expenseSubTab = 0; // 0: Expenditure Accounts, 1: All Vouchers
  int _donorSubTab = 0; // 0: In-Kind / Samagri Dan, 1: King / Top Donors CRM
  int _accountFilterMode = 0; // 0: All A/C, 1: Collecting A/C, 2: Expenditure A/C
  bool _isDesktopTableView = false; // Desktop Ledger Table vs Card Grid toggle
  _AccountSortMode _accountSort = _AccountSortMode.bookAsc; // Sort sequence for Accounts list

  // Cycle through sort modes on tap
  void _cycleAccountSort() {
    setState(() {
      _accountSort = _AccountSortMode.values[(_accountSort.index + 1) % _AccountSortMode.values.length];
    });
  }

  String get _accountSortLabel {
    switch (_accountSort) {
      case _AccountSortMode.bookAsc:    return 'Book# 1→9 ↑';
      case _AccountSortMode.bookDesc:   return 'Book# 9→1 ↓';
      case _AccountSortMode.nameAsc:    return 'Name A→Z ↑';
      case _AccountSortMode.nameDesc:   return 'Name Z→A ↓';
      case _AccountSortMode.amountDesc: return 'Amount ↓';
      case _AccountSortMode.amountAsc:  return 'Amount ↑';
    }
  }

  IconData get _accountSortIcon {
    switch (_accountSort) {
      case _AccountSortMode.bookAsc:    return Icons.tag_rounded;
      case _AccountSortMode.bookDesc:   return Icons.tag_rounded;
      case _AccountSortMode.nameAsc:    return Icons.sort_by_alpha_rounded;
      case _AccountSortMode.nameDesc:   return Icons.sort_by_alpha_rounded;
      case _AccountSortMode.amountDesc: return Icons.arrow_downward_rounded;
      case _AccountSortMode.amountAsc:  return Icons.arrow_upward_rounded;
    }
  }

  List<CollectionAccount> _sortCollectionAccounts(List<CollectionAccount> list, PujaProvider provider) {
    final sorted = List<CollectionAccount>.from(list);
    switch (_accountSort) {
      case _AccountSortMode.bookAsc:
        sorted.sort((a, b) => (a.bookNumber ?? 9999).compareTo(b.bookNumber ?? 9999));
        break;
      case _AccountSortMode.bookDesc:
        sorted.sort((a, b) => (b.bookNumber ?? 0).compareTo(a.bookNumber ?? 0));
        break;
      case _AccountSortMode.nameAsc:
        sorted.sort((a, b) => a.accountName.compareTo(b.accountName));
        break;
      case _AccountSortMode.nameDesc:
        sorted.sort((a, b) => b.accountName.compareTo(a.accountName));
        break;
      case _AccountSortMode.amountDesc:
        sorted.sort((a, b) => provider.getAccountTotalPledged(b.id).compareTo(provider.getAccountTotalPledged(a.id)));
        break;
      case _AccountSortMode.amountAsc:
        sorted.sort((a, b) => provider.getAccountTotalPledged(a.id).compareTo(provider.getAccountTotalPledged(b.id)));
        break;
    }
    return sorted;
  }

  List<ExpenditureAccount> _sortExpenditureAccounts(List<ExpenditureAccount> list, PujaProvider provider) {
    final sorted = List<ExpenditureAccount>.from(list);
    switch (_accountSort) {
      case _AccountSortMode.bookAsc:
      case _AccountSortMode.bookDesc:
        // Expenditure accounts don't have book# — fallback to name
        sorted.sort((a, b) => _accountSort == _AccountSortMode.bookAsc
            ? a.accountName.compareTo(b.accountName)
            : b.accountName.compareTo(a.accountName));
        break;
      case _AccountSortMode.nameAsc:
        sorted.sort((a, b) => a.accountName.compareTo(b.accountName));
        break;
      case _AccountSortMode.nameDesc:
        sorted.sort((a, b) => b.accountName.compareTo(a.accountName));
        break;
      case _AccountSortMode.amountDesc:
        sorted.sort((a, b) => provider.getAccountTotalSpent(b.id).compareTo(provider.getAccountTotalSpent(a.id)));
        break;
      case _AccountSortMode.amountAsc:
        sorted.sort((a, b) => provider.getAccountTotalSpent(a.id).compareTo(provider.getAccountTotalSpent(b.id)));
        break;
    }
    return sorted;
  }

  void _confirmDeleteCollectionAccount(BuildContext context, PujaProvider provider, CollectionAccount account) {
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

  void _confirmDeleteExpenditureAccount(BuildContext context, PujaProvider provider, ExpenditureAccount account) {
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
                'Delete Expenditure Account?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${account.accountName}"? All expense vouchers recorded under this account will also be permanently deleted.',
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
                        provider.deleteExpenditureAccount(account.id);
                        Navigator.pop(ctx);
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

  @override
  void initState() {
    super.initState();
    if (widget.initialEventId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<PujaProvider>(context, listen: false).selectEvent(widget.initialEventId!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final horizontalPadding = isDesktop ? 28.0 : 16.0;
    final bottomPadding = isDesktop ? 24.0 : 115.0;

    final activeEvent = provider.selectedEvent;
    final activeSlips = provider.activeEventSlips;
    final collectors = provider.availableCollectors;

    final query = _searchQuery.toLowerCase().trim();

    // 1. Filtered Slips for active event (Tab 0: Chanda)
    final filteredSlips = activeSlips.where((s) {
      final matchesStatus = _selectedStatusFilter == null || s.status == _selectedStatusFilter;
      final matchesCollector = _selectedCollectorFilter == null ||
          s.collectedBy.trim().toLowerCase() == _selectedCollectorFilter!.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          s.donorName.toLowerCase().contains(query) ||
          s.collectedBy.toLowerCase().contains(query) ||
          (s.phone != null && s.phone!.contains(query)) ||
          (s.address != null && s.address!.toLowerCase().contains(query)) ||
          (s.notes != null && s.notes!.toLowerCase().contains(query)) ||
          (s.inKindItemName != null && s.inKindItemName!.toLowerCase().contains(query)) ||
          s.amount.toString().contains(query);
      return matchesStatus && matchesCollector && matchesSearch;
    }).toList();

    // 3. Filtered Expenses for active event
    final filteredExpenses = provider.activeEventExpenses.where((exp) {
      return query.isEmpty ||
          exp.payeeName.toLowerCase().contains(query) ||
          exp.voucherNo.toLowerCase().contains(query) ||
          exp.category.displayName.toLowerCase().contains(query);
    }).toList();

    // 4. Filtered Advances for active event
    final activeAdvances = provider.activeEventAdvances;
    final filteredAdvances = activeAdvances.where((adv) {
      final matchesStatus = _advanceStatusFilter == 'All' ||
          adv.status.toLowerCase() == _advanceStatusFilter.toLowerCase();
      final matchesSearch = query.isEmpty ||
          adv.memberName.toLowerCase().contains(query) ||
          adv.purpose.toLowerCase().contains(query) ||
          adv.category.displayName.toLowerCase().contains(query) ||
          adv.advanceAmount.toString().contains(query);
      return matchesStatus && matchesSearch;
    }).toList();

    // 5. In-Kind Offering Transactions (from Slips & inKindDonations)
    final inKindFromProvider = provider.inKindDonations
        .map((item) => ChandaSlip(
              id: item.id,
              slipNumber: 0,
              bookNumber: 0,
              donorName: item.donorName,
              phone: item.phone,
              amount: item.estimatedValue ?? 0.0,
              paidAmount: item.estimatedValue ?? 0.0,
              status: DonationStatus.paid,
              paymentMode: PaymentMode.cash,
              collectedBy: item.receivedBy,
              createdAt: item.date,
              donationType: DonationType.inKind,
              inKindItemName: item.itemName,
              inKindCategory: item.category,
              inKindQuantity: item.quantity,
              notes: item.notes,
              eventId: activeEvent?.id,
            ))
        .toList();

    final allInKindSlips = [
      ...activeSlips.where((s) => s.isInKind),
      ...inKindFromProvider.where((pItem) => !activeSlips.any((s) => s.id == pItem.id)),
    ];
    allInKindSlips.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final filteredInKind = allInKindSlips.where((s) {
      final matchesSearch = query.isEmpty ||
          s.donorName.toLowerCase().contains(query) ||
          (s.inKindItemName != null && s.inKindItemName!.toLowerCase().contains(query)) ||
          (s.inKindCategory != null && s.inKindCategory!.displayName.toLowerCase().contains(query)) ||
          (s.phone != null && s.phone!.contains(query)) ||
          (s.notes != null && s.notes!.toLowerCase().contains(query)) ||
          s.amount.toString().contains(query);
      return matchesSearch;
    }).toList();

    // 6. Filtered Donors (King / Top Donors CRM)
    final filteredDonors = provider.donorSummaries.where((d) {
      return query.isEmpty || d.name.toLowerCase().contains(query);
    }).toList();

    // 7. Filtered Collection Accounts for active event
    final activeCollectionAccounts = provider.activeEventCollectionAccounts;
    final accountCollectors = activeCollectionAccounts
        .map((a) => a.collectorName?.trim() ?? '')
        .where((name) => name.isNotEmpty);
    final allCollectors = {
      ...collectors,
      ...accountCollectors,
    }.toList()..sort();

    final filteredCollectionAccounts = activeCollectionAccounts.where((acc) {
      final matchesCollector = _selectedCollectorFilter == null ||
          (acc.collectorName ?? '').trim().toLowerCase() == _selectedCollectorFilter!.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          acc.accountName.toLowerCase().contains(query) ||
          acc.areaName.toLowerCase().contains(query) ||
          (acc.collectorName ?? '').toLowerCase().contains(query) ||
          (acc.notes ?? '').toLowerCase().contains(query);
      return matchesCollector && matchesSearch;
    }).toList();

    // 8. Filtered Expenditure Accounts for active event
    final activeExpenditureAccounts = provider.activeEventExpenditureAccounts;
    final filteredExpenditureAccounts = activeExpenditureAccounts.where((acc) {
      final matchesCollector = _selectedCollectorFilter == null ||
          (acc.inChargeName ?? '').trim().toLowerCase() == _selectedCollectorFilter!.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          acc.accountName.toLowerCase().contains(query) ||
          acc.category.displayName.toLowerCase().contains(query) ||
          (acc.inChargeName ?? '').toLowerCase().contains(query) ||
          (acc.notes ?? '').toLowerCase().contains(query);
      return matchesCollector && matchesSearch;
    }).toList();

    return PopScope(
      canPop: widget.onBackToEvents == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onBackToEvents != null) {
          widget.onBackToEvents!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: isDesktop
            ? _buildDesktopWorkspace(
                context,
                provider: provider,
                currency: currency,
                activeEvent: activeEvent,
                activeSlips: activeSlips,
                activeAdvances: activeAdvances,
                filteredSlips: filteredSlips,
                filteredExpenses: filteredExpenses,
                filteredAdvances: filteredAdvances,
                filteredInKind: filteredInKind,
                filteredDonors: filteredDonors,
                filteredCollectionAccounts: filteredCollectionAccounts,
                filteredExpenditureAccounts: filteredExpenditureAccounts,
                collectors: allCollectors,
              )
            : _buildMobileWorkspace(
                context,
                provider: provider,
                currency: currency,
                activeEvent: activeEvent,
                activeSlips: activeSlips,
                activeAdvances: activeAdvances,
                filteredSlips: filteredSlips,
                filteredExpenses: filteredExpenses,
                filteredAdvances: filteredAdvances,
                filteredInKind: filteredInKind,
                filteredDonors: filteredDonors,
                activeCollectionAccounts: activeCollectionAccounts,
                activeExpenditureAccounts: activeExpenditureAccounts,
                filteredCollectionAccounts: filteredCollectionAccounts,
                filteredExpenditureAccounts: filteredExpenditureAccounts,
                collectors: allCollectors,
                horizontalPadding: horizontalPadding,
                bottomPadding: bottomPadding,
                isDesktop: isDesktop,
              ),
      ),
    );
  }

  Widget _buildMobileWorkspace(
    BuildContext context, {
    required PujaProvider provider,
    required NumberFormat currency,
    required PujaEvent? activeEvent,
    required List<ChandaSlip> activeSlips,
    required List<MemberAdvance> activeAdvances,
    required List<ChandaSlip> filteredSlips,
    required List<ExpenseVoucher> filteredExpenses,
    required List<MemberAdvance> filteredAdvances,
    required List<ChandaSlip> filteredInKind,
    required List<DonorSummary> filteredDonors,
    required List<CollectionAccount> activeCollectionAccounts,
    required List<ExpenditureAccount> activeExpenditureAccounts,
    required List<CollectionAccount> filteredCollectionAccounts,
    required List<ExpenditureAccount> filteredExpenditureAccounts,
    required List<String> collectors,
    required double horizontalPadding,
    required double bottomPadding,
    required bool isDesktop,
  }) {
    return CustomScrollView(
      slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                height: 52,
                margin: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 6),
                child: Row(
                  children: [
                    if (widget.onBackToEvents != null) ...[
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
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: widget.onBackToEvents,
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            activeEvent != null ? activeEvent.name : 'Event Workspace',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                activeEvent != null
                                    ? '${activeEvent.year} • ${activeEvent.status.toUpperCase()}'
                                    : 'Festival entries',
                                style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                              ),
                              if (activeEvent != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: activeEvent.isSynced
                                        ? AppTheme.successGreen.withAlpha(25)
                                        : AppTheme.warningAmber.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: activeEvent.isSynced
                                          ? AppTheme.successGreen.withAlpha(90)
                                          : AppTheme.warningAmber.withAlpha(90),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        activeEvent.isSynced ? Icons.link_rounded : Icons.folder_outlined,
                                        size: 10,
                                        color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.goldAccent,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        activeEvent.isSynced ? 'IN TOTAL BALANCE' : 'EVENT ONLY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.goldAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (activeEvent != null) ...[
                      const SizedBox(width: 8),
                      // Give Advance Icon Button in Header (Compact 40x40, zero overflow)
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: Tooltip(
                          message: 'Give Advance',
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD97706), // Amber 600
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => GiveAdvanceDialog(initialEventId: activeEvent.id),
                            ),
                            child: const Icon(Icons.wallet_rounded, size: 19, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3-Dot Options Button with Sync, Edit, Delete
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0x1F1E293B),
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: AppTheme.glassBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => _showEventActionSheet(context, provider, activeEvent),
                          child: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),



          // 2. Structured Event Overview Command Card
          if (activeEvent != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 2, horizontalPadding, 8),
                child: GlassContainer(
                  borderRadius: 18,
                  padding: const EdgeInsets.all(12),
                  border: Border.all(color: AppTheme.glassBorderLight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Sync Status indicator strip (Height: 24px)
                      SizedBox(
                        height: 24,
                        child: Row(
                          children: [
                            Icon(
                              activeEvent.isSynced ? Icons.check_circle_rounded : Icons.cloud_done_rounded,
                              size: 14,
                              color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                activeEvent.isSynced
                                    ? '☁️ Cloud Saved • Included in Committee Main Balance'
                                    : '☁️ Cloud Saved • Event Only Mode (Tap ⋮ to merge)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.primaryBlue,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                              ),
                              child: Text(
                                '${activeSlips.length + provider.activeEventExpenses.length} entries',
                                style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Row 2: 3 Equal KPI Columns (Height: 52px)
                      SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            // KPI 1: Collected
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.successGreen.withAlpha(40)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.check_circle, size: 10, color: AppTheme.successGreen),
                                        SizedBox(width: 3),
                                        Text('Collected', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.format(provider.eventTotalCollected),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.successGreen),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // KPI 2: Expenses
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerRose.withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.dangerRose.withAlpha(40)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.receipt_long, size: 10, color: AppTheme.dangerRose),
                                        SizedBox(width: 3),
                                        Text('Expenses', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.format(provider.eventTotalExpense),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.dangerRose),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // KPI 3: Net Balance
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (provider.eventNetBalance >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose).withAlpha(15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: (provider.eventNetBalance >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose).withAlpha(40),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.account_balance_wallet, size: 10, color: AppTheme.goldAccent),
                                        SizedBox(width: 3),
                                        Text('Net Balance', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currency.format(provider.eventNetBalance),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: provider.eventNetBalance >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose,
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
                      ),
                      const SizedBox(height: 8),

                      // Row 3: Quick Action Dock (Fixed Height: 54px, 2 Solid Structured Action Cards)
                      SizedBox(
                        height: 54,
                        child: Row(
                          children: [
                            // 1. Add Collection A/C Card
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AddCollectionAccountDialog(
                                      initialEventId: activeEvent.id,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF047857), // Emerald 700
                                          Color(0xFF10B981), // Emerald 500
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(color: const Color(0xFF6EE7B7).withAlpha(140), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF059669).withAlpha(70),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(45),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withAlpha(70)),
                                          ),
                                          child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 19),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Add Collection A/C',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.1,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 1),
                                              Text(
                                                'Area & Collector Book',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white70,
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
                              ),
                            ),
                            const SizedBox(width: 10),

                            // 2. Add Expenditure A/C Card
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => showDialog(
                                    context: context,
                                    builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent.id),
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFBE123C), // Rose 700
                                          Color(0xFFF43F5E), // Rose 500
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(color: const Color(0xFFFDA4AF).withAlpha(140), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFBE123C).withAlpha(70),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withAlpha(45),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white.withAlpha(70)),
                                          ),
                                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 19),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Add Expenditure A/C',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: 0.1,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 1),
                                              Text(
                                                'Department & Head',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white70,
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
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Optional Row 4: Budget Goal Progress Bar
                      if (activeEvent.targetBudget != null && activeEvent.targetBudget! > 0) ...[
                        const SizedBox(height: 8),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Budget Goal: ${currency.format(activeEvent.targetBudget!)}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white60),
                                  ),
                                  Text(
                                    '${((provider.eventTotalCollected / activeEvent.targetBudget!) * 100).clamp(0, 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (provider.eventTotalCollected / activeEvent.targetBudget!).clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withAlpha(20),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
                                ),
                              ),
                            ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // 3. Account Type Segmented Selector (All A/C, Collecting A/C, Expenditure A/C)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, 6),
              child: Container(
                height: 44,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    // Option 0: All A/C
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _accountFilterMode = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: _accountFilterMode == 0 ? AppTheme.primaryBlue.withAlpha(45) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _accountFilterMode == 0 ? AppTheme.primaryBlue : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_rounded, size: 13, color: _accountFilterMode == 0 ? AppTheme.primaryBlue : Colors.white60),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'All A/C (${activeCollectionAccounts.length + activeExpenditureAccounts.length})',
                                  style: TextStyle(
                                    color: _accountFilterMode == 0 ? Colors.white : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: _accountFilterMode == 0 ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),

                    // Option 1: Collecting A/C
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _accountFilterMode = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: _accountFilterMode == 1 ? const Color(0xFF10B981).withAlpha(45) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _accountFilterMode == 1 ? const Color(0xFF10B981) : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_shared_rounded, size: 13, color: _accountFilterMode == 1 ? const Color(0xFF10B981) : Colors.white60),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Collecting A/C (${activeCollectionAccounts.length})',
                                  style: TextStyle(
                                    color: _accountFilterMode == 1 ? Colors.white : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: _accountFilterMode == 1 ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),

                    // Option 2: Expenditure A/C
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _accountFilterMode = 2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          decoration: BoxDecoration(
                            color: _accountFilterMode == 2 ? const Color(0xFFF43F5E).withAlpha(45) : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: _accountFilterMode == 2 ? const Color(0xFFF43F5E) : Colors.transparent,
                              width: 1.2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance_wallet_rounded, size: 13, color: _accountFilterMode == 2 ? const Color(0xFFF43F5E) : Colors.white60),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Expenditure A/C (${activeExpenditureAccounts.length})',
                                  style: TextStyle(
                                    color: _accountFilterMode == 2 ? Colors.white : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: _accountFilterMode == 2 ? FontWeight.w800 : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
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

          // 4. Accounts Search Input + Sort Button Row
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 4),
              child: Row(
                children: [
                  // Search TextField
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: _accountFilterMode == 1
                              ? 'Search collection account, area, collector...'
                              : _accountFilterMode == 2
                                  ? 'Search expenditure account, category, head...'
                                  : 'Search accounts, area, collector, department...',
                          hintStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue, size: 17),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() => _searchQuery = ''),
                                  child: const Icon(Icons.clear, size: 16, color: Colors.white60),
                                )
                              : null,
                          filled: true,
                          fillColor: const Color(0xD9081022),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort Cycle Button
                  GestureDetector(
                    onTap: _cycleAccountSort,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryBlue.withAlpha(120), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_accountSortIcon, size: 13, color: AppTheme.primaryBlue),
                          const SizedBox(width: 5),
                          Text(
                            _accountSortLabel,
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
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

          // 5. Collector Selection Bar (Height: 32px)
          if (collectors.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 1),
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _selectedCollectorFilter = null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _selectedCollectorFilter == null ? AppTheme.primaryBlue.withAlpha(35) : const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCollectorFilter == null ? AppTheme.primaryBlue : AppTheme.glassBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'All Collectors',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: _selectedCollectorFilter == null ? AppTheme.primaryBlue : Colors.white60,
                              fontWeight: _selectedCollectorFilter == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...collectors.map((col) {
                      final isSel = _selectedCollectorFilter == col;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCollectorFilter = isSel ? null : col),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSel ? AppTheme.primaryBlue.withAlpha(35) : const Color(0x1F1E293B),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel ? AppTheme.primaryBlue : AppTheme.glassBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded, size: 12, color: isSel ? AppTheme.primaryBlue : Colors.white60),
                                const SizedBox(width: 4),
                                Text(
                                  col,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isSel ? AppTheme.primaryBlue : Colors.white70,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
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

          // 6. ACCOUNTS LIST DISPLAY

          // MODE 1: Only Collecting A/C
          if (_accountFilterMode == 1)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, bottomPadding),
              sliver: filteredCollectionAccounts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_shared_outlined, size: 40, color: Colors.white24),
                              const SizedBox(height: 10),
                              const Text(
                                'No collection accounts found.',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Organize chanda collections by Area & Collector book to track contributors and due balance.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Collection A/C', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AddCollectionAccountDialog(initialEventId: activeEvent?.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sorted = _sortCollectionAccounts(filteredCollectionAccounts, provider);
                          final acc = sorted[index];
                          return _buildCollectionAccountCard(context, provider, acc, currency);
                        },
                        childCount: filteredCollectionAccounts.length,
                      ),
                    ),
            ),

          // MODE 2: Only Expenditure A/C
          if (_accountFilterMode == 2)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, bottomPadding),
              sliver: filteredExpenditureAccounts.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.white24),
                              const SizedBox(height: 10),
                              const Text(
                                'No expenditure accounts found.',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Create expenditure accounts for departments (e.g. Pandal, Lighting, Bhog) to allocate budgets and track costs.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.dangerRose,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Expenditure A/C', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent?.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sorted = _sortExpenditureAccounts(filteredExpenditureAccounts, provider);
                          final acc = sorted[index];
                          return _buildExpenditureAccountCard(context, provider, acc, currency);
                        },
                        childCount: filteredExpenditureAccounts.length,
                      ),
                    ),
            ),

          // MODE 0: All A/C (Both Collecting A/C & Expenditure A/C)
          if (_accountFilterMode == 0 && filteredCollectionAccounts.isEmpty && filteredExpenditureAccounts.isEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, bottomPadding),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_shared_outlined, size: 44, color: Colors.white24),
                        const SizedBox(height: 10),
                        const Text('No accounts created yet.', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text(
                          'Create collection accounts for donor books and expenditure accounts for puja departments.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Collection A/C', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AddCollectionAccountDialog(initialEventId: activeEvent?.id),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dangerRose,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Expenditure A/C', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent?.id),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_accountFilterMode == 0 && filteredCollectionAccounts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.folder_shared_rounded, color: AppTheme.successGreen, size: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'COLLECTION ACCOUNTS (${filteredCollectionAccounts.length})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, filteredExpenditureAccounts.isEmpty ? bottomPadding : 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sorted = _sortCollectionAccounts(filteredCollectionAccounts, provider);
                    final acc = sorted[index];
                    return _buildCollectionAccountCard(context, provider, acc, currency);
                  },
                  childCount: filteredCollectionAccounts.length,
                ),
              ),
            ),
          ],

          if (_accountFilterMode == 0 && filteredExpenditureAccounts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRose.withAlpha(35),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.dangerRose, size: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'EXPENDITURE ACCOUNTS (${filteredExpenditureAccounts.length})',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 4, horizontalPadding, bottomPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final sorted = _sortExpenditureAccounts(filteredExpenditureAccounts, provider);
                    final acc = sorted[index];
                    return _buildExpenditureAccountCard(context, provider, acc, currency);
                  },
                  childCount: filteredExpenditureAccounts.length,
                ),
              ),
            ),
          ],
        ],
    );
  }

  // ==========================================================================
  // DEDICATED DESKTOP WORKSPACE (Structured for PC Screens)
  // ==========================================================================

  Widget _buildDesktopWorkspace(
    BuildContext context, {
    required PujaProvider provider,
    required NumberFormat currency,
    required PujaEvent? activeEvent,
    required List<ChandaSlip> activeSlips,
    required List<MemberAdvance> activeAdvances,
    required List<ChandaSlip> filteredSlips,
    required List<ExpenseVoucher> filteredExpenses,
    required List<MemberAdvance> filteredAdvances,
    required List<ChandaSlip> filteredInKind,
    required List<DonorSummary> filteredDonors,
    required List<CollectionAccount> filteredCollectionAccounts,
    required List<ExpenditureAccount> filteredExpenditureAccounts,
    required List<String> collectors,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridColumns = screenWidth > 1750 ? 4 : (screenWidth > 1250 ? 3 : 2);

    return CustomScrollView(
      slivers: [
        // 1. Sleek Desktop Header & Actions Toolbar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
            child: Row(
              children: [
                if (widget.onBackToEvents != null) ...[
                  SizedBox(
                    height: 42,
                    width: 42,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0x1F1E293B),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: widget.onBackToEvents,
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                // Title and badges
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          activeEvent != null ? activeEvent.name : 'Event Workspace',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (activeEvent != null) ...[
                        // Year & Status Chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                          ),
                          child: Text(
                            '${activeEvent.year} • ${activeEvent.status.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Interactive Sync / Total Balance Pill
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            provider.toggleEventSync(activeEvent.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  !activeEvent.isSynced
                                      ? '${activeEvent.name} merged in Main Balance!'
                                      : '${activeEvent.name} set to Event Only Mode.',
                                ),
                                backgroundColor: const Color(0xFF1E293B),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeEvent.isSynced
                                  ? AppTheme.successGreen.withAlpha(25)
                                  : AppTheme.warningAmber.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: activeEvent.isSynced
                                    ? AppTheme.successGreen.withAlpha(90)
                                    : AppTheme.warningAmber.withAlpha(90),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  activeEvent.isSynced ? Icons.link_rounded : Icons.folder_outlined,
                                  size: 13,
                                  color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.goldAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activeEvent.isSynced ? 'IN MAIN BALANCE' : 'EVENT ONLY (TAP TO MERGE)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: activeEvent.isSynced ? AppTheme.successGreen : AppTheme.goldAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Right Action Buttons
                if (activeEvent != null) ...[
                  // + Collection A/C
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.account_balance_rounded, size: 16),
                    label: const Text(
                      '+ Collection A/C',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddCollectionAccountDialog(
                        initialEventId: activeEvent.id,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // + Expenditure A/C
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dangerRose,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                    label: const Text(
                      '+ Expenditure A/C',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent.id),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Give Advance
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706), // Amber 600
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.wallet_rounded, size: 16),
                    label: const Text(
                      'Give Advance',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => GiveAdvanceDialog(initialEventId: activeEvent.id),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Export PDF Statement
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0x1F1E293B),
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: AppTheme.glassBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFFFB7185)),
                    label: const Text('Export PDF', style: TextStyle(fontSize: 12.5)),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => EventPdfExportDialog(event: activeEvent),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Options 3-dots
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0x1F1E293B),
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => _showEventActionSheet(context, provider, activeEvent),
                      child: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2. Desktop 4-Card KPI Strip
        if (activeEvent != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 4, 28, 14),
              child: Row(
                children: [
                  // KPI 1: Collections
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      border: Border.all(color: AppTheme.successGreen.withAlpha(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL COLLECTIONS',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.5),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.successGreen.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.successGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currency.format(provider.eventTotalCollected),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.successGreen),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activeSlips.length} Slips • ₹${provider.eventTotalPending.toStringAsFixed(0)} pending',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 2: Expenses
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      border: Border.all(color: AppTheme.dangerRose.withAlpha(50)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL EXPENSES',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.5),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerRose.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.payments_outlined, size: 14, color: AppTheme.dangerRose),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currency.format(provider.eventTotalExpense),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.dangerRose),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.activeEventExpenses.length} Vouchers disbursed',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 3: Net Balance
                  Expanded(
                    child: GlassContainer(
                      borderRadius: 16,
                      padding: const EdgeInsets.all(16),
                      border: Border.all(
                        color: provider.eventNetBalance >= 0
                            ? AppTheme.successGreen.withAlpha(50)
                            : AppTheme.dangerRose.withAlpha(50),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'NET BALANCE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60, letterSpacing: 0.5),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: (provider.eventNetBalance >= 0 ? AppTheme.successGreen : AppTheme.dangerRose).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: provider.eventNetBalance >= 0 ? AppTheme.successGreen : AppTheme.dangerRose,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currency.format(provider.eventNetBalance),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: provider.eventNetBalance >= 0 ? AppTheme.successGreen : AppTheme.dangerRose,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            provider.eventNetBalance >= 0 ? 'Surplus Funds' : 'Deficit / Shortfall',
                            style: const TextStyle(fontSize: 11, color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // KPI 4: Pending / Active Advances
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final pendingAmount = provider.eventTotalPendingAdvance;
                        final isPending = pendingAmount > 0;
                        final totalCleared = activeAdvances.where((a) => a.status == 'Settled').fold(0.0, (s, a) => s + a.advanceAmount);
                        final pendingCount = activeAdvances.where((a) => a.status == 'Pending').length;

                        return GlassContainer(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(16),
                          border: Border.all(
                            color: isPending
                                ? const Color(0xFFF59E0B).withAlpha(60)
                                : AppTheme.successGreen.withAlpha(50),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PENDING ADVANCES',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isPending ? const Color(0xFFF59E0B) : Colors.white60,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: (isPending ? const Color(0xFFF59E0B) : AppTheme.successGreen).withAlpha(25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPending ? Icons.wallet_rounded : Icons.check_circle_outline_rounded,
                                      size: 14,
                                      color: isPending ? const Color(0xFFF59E0B) : AppTheme.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                currency.format(pendingAmount),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: isPending ? const Color(0xFFF59E0B) : AppTheme.successGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isPending
                                    ? '$pendingCount Pending • ${currency.format(totalCleared)} cleared'
                                    : (activeAdvances.isNotEmpty
                                        ? 'All Settled • ${currency.format(totalCleared)} cleared'
                                        : '0 Accounts • No Pending'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isPending ? Colors.white60 : AppTheme.successGreen.withAlpha(220),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Optional Budget Meter for Desktop
        if (activeEvent != null && activeEvent.targetBudget != null && activeEvent.targetBudget! > 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
              child: GlassContainer(
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: AppTheme.primaryBlue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Budget Goal: ${currency.format(activeEvent.targetBudget!)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: (provider.eventTotalCollected / activeEvent.targetBudget!).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white.withAlpha(20),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${((provider.eventTotalCollected / activeEvent.targetBudget!) * 100).clamp(0, 100).toStringAsFixed(1)}% Achieved',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 3. Desktop Tab & Navigation Toolbar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
            child: GlassContainer(
              borderRadius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: Border.all(color: AppTheme.glassBorder),
              child: Row(
                children: [
                  // Tab Pills
                  _buildDesktopTabPill(
                    title: 'Chanda Slips (${activeSlips.length})',
                    icon: Icons.receipt_long_rounded,
                    isSelected: _viewMode == 0,
                    color: AppTheme.primaryBlue,
                    onTap: () => setState(() => _viewMode = 0),
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopTabPill(
                    title: 'Expenses (${provider.activeEventExpenses.length})',
                    icon: Icons.payments_outlined,
                    isSelected: _viewMode == 1,
                    color: AppTheme.dangerRose,
                    onTap: () => setState(() => _viewMode = 1),
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopTabPill(
                    title: 'Advances (${activeAdvances.length})',
                    icon: Icons.wallet_rounded,
                    isSelected: _viewMode == 2,
                    color: const Color(0xFFF59E0B),
                    onTap: () => setState(() => _viewMode = 2),
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopTabPill(
                    title: 'In-Kind (${filteredInKind.length})',
                    icon: Icons.inventory_2_rounded,
                    isSelected: _viewMode == 3 && _donorSubTab == 0,
                    color: const Color(0xFF10B981),
                    onTap: () => setState(() {
                      _viewMode = 3;
                      _donorSubTab = 0;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _buildDesktopTabPill(
                    title: 'King Donors (${filteredDonors.length})',
                    icon: Icons.workspace_premium_rounded,
                    isSelected: _viewMode == 3 && _donorSubTab == 1,
                    color: Colors.amber,
                    onTap: () => setState(() {
                      _viewMode = 3;
                      _donorSubTab = 1;
                    }),
                  ),

                  const Spacer(),

                  // Desktop Search Bar
                  SizedBox(
                    width: 250,
                    height: 36,
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      controller: TextEditingController(text: _searchQuery)
                        ..selection = TextSelection.fromPosition(TextPosition(offset: _searchQuery.length)),
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search records...',
                        hintStyle: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryBlue, size: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14, color: Colors.white60),
                                onPressed: () => setState(() => _searchQuery = ''),
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xD9081022),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.primaryBlue)),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // View Toggle: Card Grid vs Ledger Table
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Card Grid View',
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            onTap: () => setState(() => _isDesktopTableView = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isDesktopTableView ? AppTheme.primaryBlue.withAlpha(45) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: !_isDesktopTableView ? AppTheme.primaryBlue : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 18, color: AppTheme.glassBorder),
                        Tooltip(
                          message: 'Ledger Table View',
                          child: InkWell(
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            onTap: () => setState(() => _isDesktopTableView = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isDesktopTableView ? AppTheme.primaryBlue.withAlpha(45) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              ),
                              child: Icon(
                                Icons.table_chart_rounded,
                                size: 16,
                                color: _isDesktopTableView ? AppTheme.primaryBlue : Colors.white60,
                              ),
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
        ),

        // Contextual Sub-Tab & Filter bar for Tab 0
        if (_viewMode == 0)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: Row(
                children: [
                  _buildDesktopTabPill(
                    title: 'Collection A/C (${filteredCollectionAccounts.length})',
                    icon: Icons.folder_shared_rounded,
                    isSelected: _chandaSubTab == 0,
                    color: const Color(0xFF10B981),
                    onTap: () => setState(() => _chandaSubTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _buildDesktopTabPill(
                    title: 'All Slips (${filteredSlips.length})',
                    icon: Icons.receipt_long_rounded,
                    isSelected: _chandaSubTab == 1,
                    color: AppTheme.primaryBlue,
                    onTap: () => setState(() => _chandaSubTab = 1),
                  ),
                  if (_chandaSubTab == 1) ...[
                    const SizedBox(width: 14),
                    Container(height: 16, width: 1, color: AppTheme.glassBorder),
                    const SizedBox(width: 14),
                    _buildStatusChip(null, 'All Status (${activeSlips.length})', Colors.white70, Icons.filter_list),
                    const SizedBox(width: 6),
                    _buildStatusChip(DonationStatus.paid, 'Paid (${provider.eventPaidCount})', AppTheme.successGreen, Icons.check_circle_outline),
                    const SizedBox(width: 6),
                    _buildStatusChip(DonationStatus.unpaid, 'Unpaid / Due (${provider.eventUnpaidCount})', AppTheme.dangerRose, Icons.hourglass_top_outlined),
                    const SizedBox(width: 6),
                    _buildStatusChip(DonationStatus.partial, 'Partial (${provider.eventPartialCount})', AppTheme.warningAmber, Icons.pie_chart_outline),
                    if (collectors.isNotEmpty) ...[
                      const SizedBox(width: 14),
                      Container(height: 16, width: 1, color: AppTheme.glassBorder),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => setState(() => _selectedCollectorFilter = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _selectedCollectorFilter == null ? AppTheme.primaryBlue.withAlpha(35) : const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _selectedCollectorFilter == null ? AppTheme.primaryBlue : AppTheme.glassBorder),
                          ),
                          child: Text(
                            'All Collectors',
                            style: TextStyle(
                              fontSize: 11,
                              color: _selectedCollectorFilter == null ? AppTheme.primaryBlue : Colors.white60,
                              fontWeight: _selectedCollectorFilter == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ...collectors.take(5).map((col) {
                        final isSel = _selectedCollectorFilter == col;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCollectorFilter = isSel ? null : col),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primaryBlue.withAlpha(35) : const Color(0x1F1E293B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSel ? AppTheme.primaryBlue : AppTheme.glassBorder),
                              ),
                              child: Text(
                                col,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSel ? AppTheme.primaryBlue : Colors.white70,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ],
              ),
            ),
          ),

        // Contextual Sub-Tab bar for Tab 1
        if (_viewMode == 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: Row(
                children: [
                  _buildDesktopTabPill(
                    title: 'Expenditure A/C (${filteredExpenditureAccounts.length})',
                    icon: Icons.account_balance_wallet_rounded,
                    isSelected: _expenseSubTab == 0,
                    color: AppTheme.dangerRose,
                    onTap: () => setState(() => _expenseSubTab = 0),
                  ),
                  const SizedBox(width: 8),
                  _buildDesktopTabPill(
                    title: 'All Vouchers (${filteredExpenses.length})',
                    icon: Icons.payments_outlined,
                    isSelected: _expenseSubTab == 1,
                    color: AppTheme.primaryBlue,
                    onTap: () => setState(() => _expenseSubTab = 1),
                  ),
                ],
              ),
            ),
          ),

        // Contextual Filter sub-bar for Tab 2 Advances
        if (_viewMode == 2)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
              child: Row(
                children: [
                  _buildAdvanceFilterChip('All', 'All Advances (${activeAdvances.length})', AppTheme.primaryBlue, Icons.filter_list),
                  const SizedBox(width: 6),
                  _buildAdvanceFilterChip('Pending', 'Pending (${activeAdvances.where((a) => a.status == 'Pending').length})', const Color(0xFFF59E0B), Icons.hourglass_top_rounded),
                  const SizedBox(width: 6),
                  _buildAdvanceFilterChip('Settled', 'Settled (${activeAdvances.where((a) => a.status == 'Settled').length})', AppTheme.successGreen, Icons.check_circle_outline),
                ],
              ),
            ),
          ),

        // 4. Content Sliver: Either Desktop Table or Card Grid
        if (_isDesktopTableView)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
            sliver: SliverToBoxAdapter(
              child: _buildDesktopTableView(
                context,
                provider: provider,
                currency: currency,
                activeEvent: activeEvent,
                filteredSlips: filteredSlips,
                filteredExpenses: filteredExpenses,
                filteredAdvances: filteredAdvances,
                filteredInKind: filteredInKind,
                filteredDonors: filteredDonors,
              ),
            ),
          )
        else ...[
          // Grid View for Tab 0: Collection A/C
          if (_viewMode == 0 && _chandaSubTab == 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: filteredCollectionAccounts.isEmpty
                  ? _buildEmptyStateSliver('No collection accounts created yet.', Icons.folder_shared_outlined)
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 240,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCollectionAccountCard(context, provider, filteredCollectionAccounts[index], currency, isGrid: true),
                        childCount: filteredCollectionAccounts.length,
                      ),
                    ),
            ),

          // Grid View for Tab 0: All Slips
          if (_viewMode == 0 && _chandaSubTab == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: filteredSlips.isEmpty
                  ? _buildEmptyStateSliver('No chanda records found.', Icons.volunteer_activism_outlined)
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 265,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildDonationCard(context, provider, filteredSlips[index], currency, activeEvent, isGrid: true),
                        childCount: filteredSlips.length,
                      ),
                    ),
            ),

          // Grid View for Tab 1: Expenditure A/C
          if (_viewMode == 1 && _expenseSubTab == 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: filteredExpenditureAccounts.isEmpty
                  ? _buildEmptyStateSliver('No expenditure accounts created yet.', Icons.account_balance_wallet_outlined)
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 240,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildExpenditureAccountCard(context, provider, filteredExpenditureAccounts[index], currency, isGrid: true),
                        childCount: filteredExpenditureAccounts.length,
                      ),
                    ),
            ),

          // Grid View for Tab 1: All Expense Vouchers
          if (_viewMode == 1 && _expenseSubTab == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: filteredExpenses.isEmpty
                  ? _buildEmptyStateSliver('No expenses recorded yet.', Icons.payments_outlined)
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 260,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildExpenseCard(context, filteredExpenses[index], currency, provider, isGrid: true),
                        childCount: filteredExpenses.length,
                      ),
                    ),
            ),

          // Grid View for Tab 2: Advances
          if (_viewMode == 2)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: filteredAdvances.isEmpty
                  ? _buildEmptyStateSliver('No advances recorded yet.', Icons.wallet_rounded)
                  : SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridColumns,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 330, // Ample breathing space: 0px overflow guaranteed
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildAdvanceCard(context, filteredAdvances[index], currency, provider, activeEvent, isGrid: true),
                        childCount: filteredAdvances.length,
                      ),
                    ),
            ),

          // Grid View for Tab 3: In-Kind / King Donors
          if (_viewMode == 3)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 30),
              sliver: _donorSubTab == 0
                  ? (filteredInKind.isEmpty
                      ? _buildEmptyStateSliver('No in-kind offerings found.', Icons.inventory_2_rounded)
                      : SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 200,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildInKindDonationCard(context, provider, filteredInKind[index], currency, activeEvent, isGrid: true),
                            childCount: filteredInKind.length,
                          ),
                        ))
                  : (filteredDonors.isEmpty
                      ? _buildEmptyStateSliver('No donors found.', Icons.workspace_premium_rounded)
                      : SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridColumns,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            mainAxisExtent: 115,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildDonorCard(context, filteredDonors[index], index + 1, currency, isGrid: true),
                            childCount: filteredDonors.length,
                          ),
                        )),
            ),
        ],
      ],
    );
  }

  Widget _buildDesktopTabPill({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(45) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : Colors.white60),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateSliver(String message, IconData icon) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 42, color: Colors.white24),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTableView(
    BuildContext context, {
    required PujaProvider provider,
    required NumberFormat currency,
    required PujaEvent? activeEvent,
    required List<ChandaSlip> filteredSlips,
    required List<ExpenseVoucher> filteredExpenses,
    required List<MemberAdvance> filteredAdvances,
    required List<ChandaSlip> filteredInKind,
    required List<DonorSummary> filteredDonors,
  }) {
    if (_viewMode == 0) {
      // Table for Chanda
      if (filteredSlips.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No chanda records to display in table view', style: TextStyle(color: Colors.white60)),
          ),
        );
      }
      return GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        border: Border.all(color: AppTheme.glassBorder),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0x331E293B)),
                headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('SLIP #')),
                  DataColumn(label: Text('DONOR NAME')),
                  DataColumn(label: Text('CONTACT')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('PAID')),
                  DataColumn(label: Text('PENDING')),
                  DataColumn(label: Text('MODE')),
                  DataColumn(label: Text('COLLECTOR')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: filteredSlips.map((slip) {
                  return DataRow(
                    cells: [
                      DataCell(Text('#${slip.slipNumber} (Bk #${slip.bookNumber})', style: const TextStyle(color: Colors.white60, fontSize: 11))),
                      DataCell(Text(slip.donorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(slip.phone ?? '-', style: const TextStyle(color: Colors.white70, fontSize: 11))),
                      DataCell(Text(currency.format(slip.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(currency.format(slip.paidAmount), style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold))),
                      DataCell(
                        slip.pendingAmount > 0
                            ? Text(currency.format(slip.pendingAmount), style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold))
                            : const Text('-', style: TextStyle(color: Colors.white38)),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x221E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Text(slip.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataCell(Text(slip.collectedBy.isNotEmpty ? slip.collectedBy : 'Admin', style: const TextStyle(fontSize: 11))),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(slip.paymentDate ?? slip.createdAt), style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (slip.slipPhotoUrl != null && slip.slipPhotoUrl!.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF10B981)),
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
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white70),
                              tooltip: 'View Slip',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => SlipReceiptActionDialog(slip: slip),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF25D366)),
                              tooltip: 'WhatsApp',
                              onPressed: () => ReceiptShareService.sendOnWhatsApp(
                                slip: slip,
                                pujaName: provider.pujaName,
                                currentYear: provider.currentYear,
                                cashierName: provider.cashierName,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
                              tooltip: 'Edit',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AddEditDonationDialog(existing: slip),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                              tooltip: 'Delete',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => DeleteConfirmDialog(
                                  title: 'Delete Donation?',
                                  message: 'Delete donation of ₹${slip.amount.toStringAsFixed(0)} by ${slip.donorName}?',
                                  onConfirm: () => provider.deleteDonation(slip.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else if (_viewMode == 1) {
      // Table for Expenses
      if (filteredExpenses.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No expenses to display in table view', style: TextStyle(color: Colors.white60)),
          ),
        );
      }
      return GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        border: Border.all(color: AppTheme.glassBorder),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0x331E293B)),
                headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('VOUCHER #')),
                  DataColumn(label: Text('PAYEE / PURPOSE')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('MODE')),
                  DataColumn(label: Text('PAID BY')),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('BILL')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: filteredExpenses.map((expense) {
                  final hasBill = expense.receiptPhotoUrl != null && expense.receiptPhotoUrl!.isNotEmpty;
                  return DataRow(
                    cells: [
                      DataCell(Text('#${expense.voucherNo}', style: const TextStyle(color: Colors.white60, fontSize: 11))),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(expense.payeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (expense.description != null && expense.description!.isNotEmpty)
                              Text(expense.description!, style: const TextStyle(fontSize: 10.5, color: Colors.white54)),
                          ],
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(expense.category.displayName, style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryBlue)),
                        ),
                      ),
                      DataCell(Text(currency.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dangerRose))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x221E293B),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Text(expense.paymentMode.name.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataCell(Text(expense.paidBy.isNotEmpty ? expense.paidBy : 'Cashier', style: const TextStyle(fontSize: 11))),
                      DataCell(Text(DateFormat('dd MMM yyyy').format(expense.date), style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      DataCell(
                        hasBill
                            ? InkWell(
                                onTap: () => showDialog(
                                  context: context,
                                  builder: (_) => BillImagePreviewDialog(
                                    imageUrl: expense.receiptPhotoUrl!,
                                    title: expense.payeeName,
                                    subtitle: 'Voucher #${expense.voucherNo}',
                                    onDelete: () {
                                      provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: null);
                                      Navigator.pop(context);
                                    },
                                    onReplace: () => showAttachBillModal(
                                      context,
                                      onUploaded: (url) {
                                        provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: url);
                                      },
                                      existingUrl: expense.receiptPhotoUrl,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withAlpha(90)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 11),
                                      SizedBox(width: 3),
                                      Text('VIEW', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                    ],
                                  ),
                                ),
                              )
                            : const Text('-', style: TextStyle(color: Colors.white38)),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white70),
                              tooltip: 'View Voucher',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ExpenseVoucherActionDialog(voucher: expense),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share_rounded, size: 16, color: Color(0xFF25D366)),
                              tooltip: 'WhatsApp',
                              onPressed: () => ReceiptShareService.sendExpenseVoucherOnWhatsApp(
                                voucher: expense,
                                pujaName: provider.pujaName,
                                currentYear: provider.currentYear,
                                cashierName: provider.cashierName,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
                              tooltip: 'Edit',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => AddExpenseDialog(initialEventId: expense.eventId, existing: expense),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                              tooltip: 'Delete',
                              onPressed: () => _confirmDeleteExpense(context, provider, expense),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else if (_viewMode == 2) {
      // Table for Advances
      if (filteredAdvances.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: Text('No advances to display in table view', style: TextStyle(color: Colors.white60)),
          ),
        );
      }
      return GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        border: Border.all(color: AppTheme.glassBorder),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0x331E293B)),
                headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('MEMBER')),
                  DataColumn(label: Text('PURPOSE')),
                  DataColumn(label: Text('CATEGORY')),
                  DataColumn(label: Text('DISBURSED')),
                  DataColumn(label: Text('CONTRACT TOTAL')),
                  DataColumn(label: Text('REMAINING DUE')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: filteredAdvances.map((adv) {
                  return DataRow(
                    cells: [
                      DataCell(Text(adv.memberName, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(adv.purpose, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(adv.category.displayName, style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      DataCell(Text(currency.format(adv.advanceAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)))),
                      DataCell(Text(adv.hasContract ? currency.format(adv.effectiveOriginalAmount) : '-', style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      DataCell(Text(
                        adv.remainingDue > 0 ? currency.format(adv.remainingDue) : '-',
                        style: TextStyle(fontWeight: FontWeight.bold, color: adv.remainingDue > 0 ? const Color(0xFFFBBF24) : Colors.white38),
                      )),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (adv.status == 'Settled' ? AppTheme.successGreen : const Color(0xFFF59E0B)).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            adv.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: adv.status == 'Settled' ? AppTheme.successGreen : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );
    } else {
      // Table for In-Kind or King Donors
      if (_donorSubTab == 0) {
        if (filteredInKind.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No in-kind offerings to display in table view', style: TextStyle(color: Colors.white60)),
            ),
          );
        }
        return GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(12),
          border: Border.all(color: AppTheme.glassBorder),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0x331E293B)),
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                  dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('DONOR')),
                    DataColumn(label: Text('SAMAGRI / ITEM')),
                    DataColumn(label: Text('CATEGORY')),
                    DataColumn(label: Text('QUANTITY')),
                    DataColumn(label: Text('EST. VALUE')),
                    DataColumn(label: Text('RECEIVED BY')),
                    DataColumn(label: Text('DATE')),
                  ],
                  rows: filteredInKind.map((slip) {
                    return DataRow(
                      cells: [
                        DataCell(Text(slip.donorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(slip.inKindItemName ?? '-', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))),
                        DataCell(Text(slip.inKindCategory?.displayName ?? 'Samagri', style: const TextStyle(fontSize: 11, color: Colors.white70))),
                        DataCell(Text(slip.inKindQuantity ?? '-', style: const TextStyle(fontSize: 11))),
                        DataCell(Text(currency.format(slip.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(slip.collectedBy.isNotEmpty ? slip.collectedBy : 'Admin', style: const TextStyle(fontSize: 11))),
                        DataCell(Text(DateFormat('dd MMM yyyy').format(slip.createdAt), style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      } else {
        if (filteredDonors.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('No donors to display in table view', style: TextStyle(color: Colors.white60)),
            ),
          );
        }
        return GlassContainer(
          borderRadius: 16,
          padding: const EdgeInsets.all(12),
          border: Border.all(color: AppTheme.glassBorder),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0x331E293B)),
                  headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
                  dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.white),
                  columnSpacing: 18,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('RANK')),
                    DataColumn(label: Text('DONOR NAME')),
                    DataColumn(label: Text('TOTAL DONATIONS')),
                    DataColumn(label: Text('SLIPS COUNT')),
                  ],
                  rows: filteredDonors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final donor = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))),
                        DataCell(Text(donor.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataCell(Text(currency.format(donor.totalDonated), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successGreen))),
                        DataCell(Text('${donor.donationCount} donations', style: const TextStyle(fontSize: 11, color: Colors.white70))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      }
    }
  }

  // ==========================================================================
  // HELPER WIDGETS
  // ==========================================================================

  Widget _buildExpenseCard(
    BuildContext context,
    ExpenseVoucher expense,
    NumberFormat currency,
    PujaProvider provider, {
    bool isGrid = false,
  }) {
    final isAdvance = expense.isAdvance;
    final themeColor = isAdvance ? const Color(0xFFF59E0B) : AppTheme.dangerRose;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showDialog(
        context: context,
        builder: (_) => ExpenseVoucherActionDialog(voucher: expense),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        border: Border.all(
          color: themeColor.withAlpha(55),
          width: 1.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon Avatar, Payee Name, Subtitle, Type Badge & 3-Line Menu Button
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
                      isAdvance ? Icons.wallet_rounded : expense.category.icon,
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
                        expense.payeeName.isNotEmpty ? expense.payeeName : 'Expense Voucher',
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${expense.category.displayName} • #${expense.voucherNo}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withAlpha(140),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Type Badge (Advance vs Expense)
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
                if (expense.receiptPhotoUrl != null && expense.receiptPhotoUrl!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BillImagePreviewDialog(
                        imageUrl: expense.receiptPhotoUrl!,
                        title: expense.payeeName,
                        subtitle: 'Voucher #${expense.voucherNo}',
                        onDelete: () {
                          provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: null);
                          Navigator.pop(context);
                        },
                        onReplace: () => showAttachBillModal(
                          context,
                          onUploaded: (url) {
                            provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: url);
                          },
                          existingUrl: expense.receiptPhotoUrl,
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

                // 3-Line Menu Button ("chota bra 3 line" button)
                _buildThreeLineMenuButton(
                  context: context,
                  hasBill: expense.receiptPhotoUrl != null && expense.receiptPhotoUrl!.isNotEmpty,
                  onBillAction: () {
                    if (expense.receiptPhotoUrl != null && expense.receiptPhotoUrl!.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (_) => BillImagePreviewDialog(
                          imageUrl: expense.receiptPhotoUrl!,
                          title: expense.payeeName,
                          subtitle: 'Voucher #${expense.voucherNo}',
                          onDelete: () {
                            provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: null);
                            Navigator.pop(context);
                          },
                          onReplace: () => showAttachBillModal(
                            context,
                            onUploaded: (url) {
                              provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: url);
                            },
                            existingUrl: expense.receiptPhotoUrl,
                          ),
                        ),
                      );
                    } else {
                      showAttachBillModal(
                        context,
                        onUploaded: (url) {
                          provider.updateExpenseReceiptPhoto(expenseId: expense.id, photoUrl: url);
                        },
                      );
                    }
                  },
                  onViewSlip: () => showDialog(
                    context: context,
                    builder: (_) => ExpenseVoucherActionDialog(voucher: expense),
                  ),
                  onShare: () => ReceiptShareService.sendExpenseVoucherOnWhatsApp(
                    voucher: expense,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  ),
                  onEdit: () => showDialog(
                    context: context,
                    builder: (_) => AddExpenseDialog(initialEventId: expense.eventId, existing: expense),
                  ),
                  onDelete: () => _confirmDeleteExpense(context, provider, expense),
                ),
              ],
            ),

            // Row 2: Structured Amount & Payment Mode Card Box
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
                  // Amount Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currency.format(expense.amount),
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

                  // Mode Chip & Paid By
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
                              expense.paymentMode == PaymentMode.upi
                                  ? Icons.qr_code_rounded
                                  : expense.paymentMode == PaymentMode.bankTransfer
                                      ? Icons.account_balance_rounded
                                      : Icons.payments_rounded,
                              size: 11,
                              color: themeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expense.paymentMode.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (expense.paidBy.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'By: ${expense.paidBy}',
                          style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Row 3: Description Note (if present)
            if (expense.description != null && expense.description!.trim().isNotEmpty) ...[
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
                        expense.description!.trim(),
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
                      DateFormat('dd MMM yyyy').format(expense.date),
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (expense.installmentId != null)
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
  }

  void _confirmDeleteExpense(BuildContext context, PujaProvider provider, ExpenseVoucher expense) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 22,
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

  Widget _buildAdvanceFilterChip(String status, String label, Color color, IconData icon) {
    final isSel = _advanceStatusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _advanceStatusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withAlpha(45) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? color : AppTheme.glassBorder,
            width: isSel ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSel ? color : Colors.white60),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSel ? Colors.white : Colors.white70,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvanceCard(
    BuildContext context,
    MemberAdvance advance,
    NumberFormat currency,
    PujaProvider provider,
    PujaEvent? activeEvent, {
    bool isGrid = false,
  }) {
    return AdvanceAccountCard(
      advance: advance,
      currency: currency,
      provider: provider,
      activeEvent: activeEvent,
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      isGrid: isGrid,
    );
  }




  Widget _buildStatusChip(DonationStatus? status, String label, Color color, IconData icon) {
    final isSel = _selectedStatusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatusFilter = isSel ? null : status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? color.withAlpha(45) : const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? color : AppTheme.glassBorder,
            width: isSel ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSel ? color : Colors.white60),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
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
                    color: AppTheme.primaryBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                const Text(
                  'View Slip / Receipt',
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

  Widget _buildCollectionAccountCard(
    BuildContext context,
    PujaProvider provider,
    CollectionAccount account,
    NumberFormat currency, {
    bool isGrid = false,
  }) {
    final slips = provider.getAccountSlips(account.id);
    final totalPledged = provider.getAccountTotalPledged(account.id);
    final totalPaid = provider.getAccountTotalPaid(account.id);
    final totalUnpaid = provider.getAccountTotalUnpaid(account.id);
    final paidCount = provider.getAccountPaidCount(account.id);
    final unpaidCount = provider.getAccountUnpaidCount(account.id);
    final percent = totalPledged > 0 ? (totalPaid / totalPledged).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CollectionAccountDetailScreen(accountId: account.id),
              ),
            );
          },
          child: GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            border: Border.all(
              color: AppTheme.successGreen.withAlpha(60),
              width: 1.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Account Icon, Name & Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_rounded, color: AppTheme.successGreen, size: 20),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          // Badges Wrap (Never breaks or overflows on any screen size)
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Area Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0x221E293B),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.glassBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 11, color: Colors.white70),
                                    const SizedBox(width: 3.5),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 160),
                                      child: Text(
                                        account.areaName,
                                        style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Book Slip Range Badge
                              if (account.bookNumber != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withAlpha(75)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.menu_book_rounded, size: 11, color: Color(0xFF10B981)),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        account.bookSlipRangeText,
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              // Collector Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: (account.collectorName != null && account.collectorName!.isNotEmpty)
                                      ? AppTheme.primaryBlue.withAlpha(25)
                                      : Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (account.collectorName != null && account.collectorName!.isNotEmpty)
                                        ? AppTheme.primaryBlue.withAlpha(70)
                                        : Colors.white.withAlpha(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 11,
                                      color: (account.collectorName != null && account.collectorName!.isNotEmpty)
                                          ? AppTheme.primaryBlue
                                          : Colors.white38,
                                    ),
                                    const SizedBox(width: 3.5),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 130),
                                      child: Text(
                                        (account.collectorName != null && account.collectorName!.isNotEmpty)
                                            ? account.collectorName!
                                            : 'No collector',
                                        style: TextStyle(
                                          color: (account.collectorName != null && account.collectorName!.isNotEmpty)
                                              ? Colors.white70
                                              : Colors.white38,
                                          fontSize: 10.5,
                                          fontWeight: (account.collectorName != null && account.collectorName!.isNotEmpty)
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                      color: AppTheme.cardSurface,
                      padding: EdgeInsets.zero,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'open', child: Text('Open Account (Ek-Ek Insan)', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'edit', child: Text('Edit Account', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: AppTheme.dangerRose))),
                      ],
                      onSelected: (val) {
                        if (val == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CollectionAccountDetailScreen(accountId: account.id),
                            ),
                          );
                        } else if (val == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => AddCollectionAccountDialog(existing: account),
                          );
                        } else if (val == 'delete') {
                          _confirmDeleteCollectionAccount(context, provider, account);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3 Systematic Metric Boxes: Chanda Diya, Paid, Unpaid
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Row(
                    children: [
                      // Total Pledged / Chanda Diya
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chanda Diya',
                              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(totalPledged),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white12),
                      const SizedBox(width: 8),
                      // Paid (Jama)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Paid (Jama)',
                              style: TextStyle(color: AppTheme.accentEmerald, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(totalPaid),
                                style: const TextStyle(color: AppTheme.accentEmerald, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white12),
                      const SizedBox(width: 8),
                      // Unpaid (Baki)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unpaid (Baki)',
                              style: TextStyle(color: AppTheme.dangerRose, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(totalUnpaid),
                                style: const TextStyle(color: AppTheme.dangerRose, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Progress Bar and Contributors info
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${slips.length} Contributor${slips.length == 1 ? '' : 's'} • $paidCount Paid${unpaidCount > 0 ? ' • $unpaidCount Due' : ''}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(percent * 100).toStringAsFixed(0)}% Paid',
                      style: TextStyle(
                        color: percent >= 1.0 ? AppTheme.accentEmerald : const Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percent >= 1.0 ? AppTheme.accentEmerald : const Color(0xFFF59E0B),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Bottom Call to Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentEmerald.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.accentEmerald.withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Contributors / Add (Ek ek insan)',
                            style: TextStyle(
                              color: AppTheme.accentEmerald,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.accentEmerald),
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
    );
  }

  Widget _buildExpenditureAccountCard(
    BuildContext context,
    PujaProvider provider,
    ExpenditureAccount account,
    NumberFormat currency, {
    bool isGrid = false,
  }) {
    final vouchers = provider.getAccountExpenses(account.id);
    final totalSpent = provider.getAccountTotalSpent(account.id);
    final budget = account.allocatedBudget;
    final remaining = provider.getAccountRemainingBudget(account);
    final isOverBudget = remaining < 0;
    final percent = (budget != null && budget > 0) ? (totalSpent / budget).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenditureAccountDetailScreen(accountId: account.id),
              ),
            );
          },
          child: GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            border: Border.all(
              color: AppTheme.dangerRose.withAlpha(60),
              width: 1.2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Account Icon, Name & Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRose.withAlpha(30),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          // Badges Wrap
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Category Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withAlpha(25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryBlue.withAlpha(70)),
                                ),
                                child: Text(
                                  account.category.displayName,
                                  style: const TextStyle(color: AppTheme.primaryBlue, fontSize: 10.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              // In-Charge Badge
                              if (account.inChargeName != null && account.inChargeName!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(10),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.white.withAlpha(18)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.person_outline_rounded, size: 11, color: Colors.white54),
                                      const SizedBox(width: 3.5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 140),
                                        child: Text(
                                          'In-Charge: ${account.inChargeName}',
                                          style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action Menu
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white38, size: 18),
                      color: AppTheme.cardSurface,
                      padding: EdgeInsets.zero,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'open', child: Text('Open Account', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'edit', child: Text('Edit Account', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete Account', style: TextStyle(color: AppTheme.dangerRose))),
                      ],
                      onSelected: (val) {
                        if (val == 'open') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ExpenditureAccountDetailScreen(accountId: account.id),
                            ),
                          );
                        } else if (val == 'edit') {
                          showDialog(
                            context: context,
                            builder: (_) => AddExpenditureAccountDialog(existing: account),
                          );
                        } else if (val == 'delete') {
                          _confirmDeleteExpenditureAccount(context, provider, account);
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 3 Metric Boxes: Budget, Spent, Balance
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Row(
                    children: [
                      // Budget
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Allocated Budget', style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                budget != null && budget > 0 ? currency.format(budget) : 'Not Set',
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white12),
                      const SizedBox(width: 8),
                      // Spent
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Spent', style: TextStyle(color: AppTheme.dangerRose, fontSize: 10, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(totalSpent),
                                style: const TextStyle(color: AppTheme.dangerRose, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: Colors.white12),
                      const SizedBox(width: 8),
                      // Remaining / Over
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOverBudget ? 'Over Budget' : 'Remaining',
                              style: TextStyle(
                                color: isOverBudget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currency.format(remaining.abs()),
                                style: TextStyle(
                                  color: isOverBudget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Progress Bar and Vouchers info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${vouchers.length} Expense Voucher${vouchers.length == 1 ? '' : 's'}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (budget != null && budget > 0)
                      Text(
                        '${((totalSpent / budget) * 100).clamp(0, 999).toStringAsFixed(0)}% Used',
                        style: TextStyle(
                          color: isOverBudget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                if (budget != null && budget > 0) ...[
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOverBudget ? AppTheme.dangerRose : AppTheme.accentEmerald,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 10),

                // Bottom Call to Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRose.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dangerRose.withAlpha(60)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Vouchers / Record Expense',
                            style: TextStyle(
                              color: AppTheme.dangerRose,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.dangerRose),
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
    );
  }

  Widget _buildInKindDonationCard(
    BuildContext context,
    PujaProvider provider,
    ChandaSlip slip,
    NumberFormat currency,
    PujaEvent? activeEvent, {
    bool isGrid = false,
  }) {
    final isFullyPaid = slip.status == DonationStatus.paid;
    final isPartial = slip.status == DonationStatus.partial;
    final Color statusColor = isFullyPaid
        ? const Color(0xFF10B981)
        : (isPartial ? const Color(0xFFF59E0B) : const Color(0xFFFB7185));
    final String statusLabel = isFullyPaid
        ? 'RECEIVED'
        : (isPartial ? 'PARTIAL' : 'PROMISED');
    final IconData statusIcon = isFullyPaid
        ? Icons.check_circle_rounded
        : (isPartial ? Icons.pie_chart_rounded : Icons.schedule_rounded);
    final cat = slip.inKindCategory;
    final catColor = cat?.color ?? const Color(0xFF10B981);
    final catIcon = cat?.icon ?? Icons.inventory_2_rounded;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showDialog(
        context: context,
        builder: (_) => SlipReceiptActionDialog(slip: slip),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        border: Border.all(
          color: statusColor.withAlpha(60),
          width: 1.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Category Icon, Item Name, Status Pill & 3-Line Menu Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: catColor.withAlpha(80)),
                  ),
                  child: Icon(catIcon, size: 20, color: catColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slip.inKindItemName ?? 'In-Kind Offering',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Donor: ${slip.donorName}${slip.phone != null && slip.phone!.isNotEmpty ? " • ${slip.phone}" : ""}',
                        style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(160)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withAlpha(90)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3-Line Menu Button ("chota bra 3 line" button)
                _buildThreeLineMenuButton(
                  context: context,
                  onViewSlip: () => showDialog(
                    context: context,
                    builder: (_) => SlipReceiptActionDialog(slip: slip),
                  ),
                  onShare: () => ReceiptShareService.sendOnWhatsApp(
                    slip: slip,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  ),
                  onEdit: () => showDialog(
                    context: context,
                    builder: (_) => AddEditDonationDialog(existing: slip),
                  ),
                  onDelete: () => showDialog(
                    context: context,
                    builder: (_) => DeleteConfirmDialog(
                      title: 'Delete Offering?',
                      message: 'Are you sure you want to delete the in-kind offering "${slip.inKindItemName ?? 'item'}" by ${slip.donorName}?',
                      onConfirm: () => provider.deleteDonation(slip.id),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 2: Tags - Category, Quantity, Estimated Value
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                // Category tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: catColor.withAlpha(60)),
                  ),
                  child: Text(
                    cat?.displayName.split(' (')[0] ?? 'Samagri',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                  ),
                ),
                // Quantity tag
                if (slip.inKindQuantity != null && slip.inKindQuantity!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.scale_rounded, size: 11, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${slip.inKindQuantity}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                // Estimated Value tag if > 0
                if (slip.amount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.currency_rupee, size: 11, color: Color(0xFF10B981)),
                        Text(
                          'Est. ${currency.format(slip.amount)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  if (isPartial) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.successGreen.withAlpha(60)),
                      ),
                      child: Text(
                        'Rec: ${currency.format(slip.paidAmount)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRose.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.dangerRose.withAlpha(60)),
                      ),
                      child: Text(
                        'Due: ${currency.format(slip.pendingAmount)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.dangerRose),
                      ),
                    ),
                  ],
                ],
                if (slip.slipPhotoUrl != null && slip.slipPhotoUrl!.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => BillImagePreviewDialog(
                        imageUrl: slip.slipPhotoUrl!,
                        title: slip.donorName,
                        subtitle: 'In-Kind • ${slip.inKindItemName ?? 'Offering'}',
                        onDelete: () => provider.updateSlipReceiptPhoto(slipId: slip.id, photoUrl: null),
                        onReplace: () => showAttachSlipModal(
                          context,
                          onUploaded: (url) => provider.updateSlipReceiptPhoto(slipId: slip.id, photoUrl: url),
                          existingUrl: slip.slipPhotoUrl,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_outlined, size: 11, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Slip Photo',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Receiver & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_outlined, size: 12, color: AppTheme.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Recorded By: ${slip.collectedBy}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(160)),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(slip.paymentDate ?? slip.createdAt),
                  style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(130)),
                ),
              ],
            ),

            if (slip.notes != null && slip.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '“${slip.notes!}”',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withAlpha(140)),
              ),
            ],

            const Divider(height: 18, color: AppTheme.glassBorder),

            // Row 4: Actions (Mark Received or Delivered status)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isFullyPaid)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withAlpha(40),
                      foregroundColor: const Color(0xFF10B981),
                      side: BorderSide(color: const Color(0xFF10B981).withAlpha(100)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Mark Received', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => RecordPaymentDialog(slip: slip),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.done_all, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Delivered / In Stock',
                          style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
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
  }

  Widget _buildDonationCard(
    BuildContext context,
    PujaProvider provider,
    ChandaSlip slip,
    NumberFormat currency,
    PujaEvent? activeEvent, {
    bool isGrid = false,
  }) {
    if (slip.isInKind) {
      return _buildInKindDonationCard(context, provider, slip, currency, activeEvent, isGrid: isGrid);
    }

    final status = slip.status;
    final isUnpaidOrPartial = !slip.isFullyPaid;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showDialog(
        context: context,
        builder: (_) => SlipReceiptActionDialog(slip: slip),
      ),
      child: GlassContainer(
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
        border: Border.all(
          color: status == DonationStatus.paid
              ? const Color(0xFF10B981).withAlpha(55)
              : status == DonationStatus.unpaid
                  ? const Color(0xFFEF4444).withAlpha(65)
                  : const Color(0xFFF59E0B).withAlpha(65),
          width: 1.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Donor Avatar, Name, Slip/Book #, Status Badge & 3-Line Menu Button
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: status.color.withAlpha(25),
                    shape: BoxShape.circle,
                    border: Border.all(color: status.color.withAlpha(70)),
                  ),
                  child: Center(
                    child: Icon(Icons.person_outline_rounded, size: 19, color: status.color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slip.donorName,
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
                      Row(
                        children: [
                          Text(
                            'Slip #${slip.slipNumber} • Book #${slip.bookNumber}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withAlpha(140),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (slip.phone != null && slip.phone!.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(100)),
                            ),
                            Icon(Icons.phone_rounded, size: 10, color: Colors.white.withAlpha(140)),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                slip.phone!,
                                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: status.color.withAlpha(90)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 12, color: status.color),
                      const SizedBox(width: 4),
                      Text(
                        status.displayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3-Line Menu Button ("chota bra 3 line" button)
                _buildThreeLineMenuButton(
                  context: context,
                  onViewSlip: () => showDialog(
                    context: context,
                    builder: (_) => SlipReceiptActionDialog(slip: slip),
                  ),
                  onShare: () => ReceiptShareService.sendOnWhatsApp(
                    slip: slip,
                    pujaName: provider.pujaName,
                    currentYear: provider.currentYear,
                    cashierName: provider.cashierName,
                  ),
                  onEdit: () => showDialog(
                    context: context,
                    builder: (_) => AddEditDonationDialog(existing: slip),
                  ),
                  onDelete: () => showDialog(
                    context: context,
                    builder: (_) => DeleteConfirmDialog(
                      title: 'Delete Donation?',
                      message: 'Are you sure you want to delete the donation of ₹${slip.amount.toStringAsFixed(0)} by ${slip.donorName}?',
                      onConfirm: () => provider.deleteDonation(slip.id),
                    ),
                  ),
                ),
              ],
            ),

            // Row 2: Structured Amount & Collector Info Card Box
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0x1F0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: status == DonationStatus.paid
                      ? const Color(0xFF10B981).withAlpha(40)
                      : status == DonationStatus.unpaid
                          ? const Color(0xFFEF4444).withAlpha(50)
                          : const Color(0xFFF59E0B).withAlpha(50),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Amount Block
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (slip.isFullyPaid) ...[
                          Text(
                            currency.format(slip.paidAmount),
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF10B981)),
                              const SizedBox(width: 3),
                              const Text(
                                'Received in full',
                                style: TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ] else if (slip.isPartial) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                currency.format(slip.paidAmount),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              Text(
                                ' / ${currency.format(slip.amount)}',
                                style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Pending Due: ${currency.format(slip.pendingAmount)}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFBBF24)),
                          ),
                        ] else ...[
                          Text(
                            currency.format(slip.amount),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(height: 1),
                          const Text(
                            'Full Amount Pending',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFFF87171), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Collector Chip & Date
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
                            const Icon(Icons.badge_outlined, size: 11, color: AppTheme.primaryBlue),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                slip.collectedBy.isNotEmpty ? slip.collectedBy : 'Admin',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withAlpha(130)),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(slip.paymentDate ?? slip.createdAt),
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (slip.notes != null && slip.notes!.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(14)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded, size: 13, color: Colors.white54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        slip.notes!.trim(),
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white.withAlpha(170)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Row 3: Footer Meta & Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Payment Mode Badge & Slip Photo
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            slip.paymentMode == PaymentMode.cash
                                ? Icons.payments_outlined
                                : slip.paymentMode == PaymentMode.upi
                                    ? Icons.qr_code_2_rounded
                                    : Icons.account_balance_outlined,
                            size: 12,
                            color: Colors.white60,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Mode: ${slip.paymentMode.name.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withAlpha(170),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (slip.slipPhotoUrl != null && slip.slipPhotoUrl!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(7),
                        onTap: () => showDialog(
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(25),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 11, color: Color(0xFF10B981)),
                              SizedBox(width: 4),
                              Text(
                                'Slip Photo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Right Side: Quick "Pay Due" Button if unpaid or partial
                if (isUnpaidOrPartial)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981).withAlpha(40),
                      foregroundColor: const Color(0xFF10B981),
                      side: BorderSide(color: const Color(0xFF10B981).withAlpha(110)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.price_check, size: 14),
                    label: Text(
                      'Pay Due (₹${slip.pendingAmount.toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => RecordPaymentDialog(slip: slip),
                    ),
                  )
                else if (slip.dayLabel != null && slip.dayLabel!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
                    ),
                    child: Text(
                      slip.dayLabel!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventActionSheet(BuildContext context, PujaProvider provider, PujaEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${event.name} (${event.year})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 14),

                // 1. Interactive Sync to Net Balance Tile
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: event.isSynced
                        ? AppTheme.successGreen.withAlpha(25)
                        : AppTheme.warningAmber.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: event.isSynced
                          ? AppTheme.successGreen.withAlpha(100)
                          : AppTheme.warningAmber.withAlpha(100),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: event.isSynced
                              ? AppTheme.successGreen.withAlpha(40)
                              : AppTheme.primaryBlue.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          event.isSynced ? Icons.link_rounded : Icons.account_balance_wallet_outlined,
                          color: event.isSynced ? AppTheme.successGreen : AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        event.isSynced ? 'Merged in Main Balance' : 'Merge with Main Committee Balance',
                        style: TextStyle(
                          color: event.isSynced ? AppTheme.successGreen : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        event.isSynced
                            ? 'Included in committee totals. Tap to keep in this event only.'
                            : 'Tap to include this event in committee Total Net Balance.',
                        style: const TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      trailing: Switch(
                        value: event.isSynced,
                        activeThumbColor: AppTheme.successGreen,
                        onChanged: (val) {
                          Navigator.pop(ctx);
                          provider.setEventSync(event.id, val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                val
                                    ? '${event.name} synced to Total Net Balance!'
                                    : '${event.name} removed from Total Net Balance.',
                              ),
                              backgroundColor: const Color(0xFF1E293B),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        provider.toggleEventSync(event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              !event.isSynced
                                  ? '${event.name} synced to Total Net Balance!'
                                  : '${event.name} removed from Total Net Balance.',
                            ),
                            backgroundColor: const Color(0xFF1E293B),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 2. Export PDF Statement Tile
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE11D48).withAlpha(80)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48).withAlpha(35),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFB7185), size: 22),
                      ),
                      title: const Text(
                        'Export PDF Statement',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'All Transactions, Collections, Expenses or Advances',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFB7185), size: 14),
                      onTap: () {
                        Navigator.pop(ctx);
                        showDialog(
                          context: context,
                          builder: (_) => EventPdfExportDialog(event: event),
                        );
                      },
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue),
                  title: const Text('Edit Event Details', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => CreateEditEventDialog(existing: event),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.dangerRose),
                  title: const Text('Delete Event', style: TextStyle(color: AppTheme.dangerRose)),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder: (_) => DeleteConfirmDialog(
                        title: 'Delete Event?',
                        message: 'Deleting "${event.name} (${event.year})" will remove its association. Are you sure?',
                        onConfirm: () => provider.deleteEvent(event.id),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  Widget _buildDonorCard(
    BuildContext context,
    DonorSummary donor,
    int rank,
    NumberFormat currency, {
    bool isGrid = false,
  }) {
    final Color rankColor;
    final IconData? rankIcon;
    switch (rank) {
      case 1:
        rankColor = AppTheme.goldAccent;
        rankIcon = Icons.workspace_premium;
        break;
      case 2:
        rankColor = const Color(0xFFB8C4D9);
        rankIcon = Icons.emoji_events;
        break;
      case 3:
        rankColor = const Color(0xFFCD8A54);
        rankIcon = Icons.emoji_events;
        break;
      default:
        rankColor = Colors.white38;
        rankIcon = null;
    }

    final initials = donor.name.trim().isNotEmpty
        ? donor.name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : '?';

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      border: Border.all(
        color: rank <= 3 ? rankColor.withAlpha(90) : AppTheme.glassBorder,
        width: rank <= 3 ? 1.3 : 1.0,
      ),
      onTap: () => showDialog(
        context: context,
        builder: (_) => DonorHistoryDialog(donor: donor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(28),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor.withAlpha(110)),
            ),
            alignment: Alignment.center,
            child: rankIcon != null
                ? Icon(rankIcon, size: 18, color: rankColor)
                : Text(
                    '$rank',
                    style: TextStyle(color: Colors.white.withAlpha(170), fontWeight: FontWeight.w800, fontSize: 13),
                  ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF38BDF8)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        donor.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rank <= 3) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: rankColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: rankColor.withAlpha(120), width: 0.8),
                        ),
                        child: Text(
                          rank == 1 ? '👑 KING #1' : (rank == 2 ? '🥈 VIP #2' : '🥉 VIP #3'),
                          style: TextStyle(
                            color: rankColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${donor.donationCount} donation${donor.donationCount > 1 ? 's' : ''} • Last: ${DateFormat('dd MMM').format(donor.lastDonation)}',
                  style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currency.format(donor.totalDonated),
                style: const TextStyle(color: AppTheme.successGreenLight, fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('History', style: TextStyle(color: AppTheme.primaryBlue.withAlpha(200), fontSize: 10, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 12, color: AppTheme.primaryBlue.withAlpha(200)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
