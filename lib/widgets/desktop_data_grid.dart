import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/desktop_controller.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';

class GridTransactionItem {
  final String id;
  final String type; // 'donation', 'expense', 'advance'
  final String refNo;
  final String name;
  final String categoryOrBook;
  final PaymentMode paymentMode;
  final double amount;
  final DateTime date;
  final String status;
  final dynamic raw;

  GridTransactionItem({
    required this.id,
    required this.type,
    required this.refNo,
    required this.name,
    required this.categoryOrBook,
    required this.paymentMode,
    required this.amount,
    required this.date,
    required this.status,
    required this.raw,
  });
}

class DesktopDataGrid extends StatelessWidget {
  final String? eventId;

  const DesktopDataGrid({super.key, this.eventId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final desktopCtrl = Provider.of<DesktopController>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    // 1. Gather Items
    final List<GridTransactionItem> items = [];

    final slips = eventId == null ? provider.slips : provider.slips.where((s) => s.eventId == eventId).toList();
    for (final s in slips) {
      items.add(GridTransactionItem(
        id: s.id,
        type: 'donation',
        refNo: 'Slip #${s.slipNumber}',
        name: s.donorName,
        categoryOrBook: 'Book #${s.bookNumber}',
        paymentMode: s.paymentMode,
        amount: s.amount,
        date: s.createdAt,
        status: s.isFullyPaid ? 'Paid' : 'Due',
        raw: s,
      ));
    }

    final expenses = eventId == null ? provider.expenses : provider.expenses.where((e) => e.eventId == eventId).toList();
    for (final e in expenses) {
      items.add(GridTransactionItem(
        id: e.id,
        type: 'expense',
        refNo: 'Voucher #${e.voucherNo}',
        name: e.payeeName.isNotEmpty ? e.payeeName : (e.description ?? 'Expense'),
        categoryOrBook: e.category.displayName,
        paymentMode: e.paymentMode,
        amount: e.amount,
        date: e.date,
        status: 'Approved',
        raw: e,
      ));
    }

    final advances = eventId == null ? provider.advances : provider.advances.where((a) => a.eventId == eventId).toList();
    for (final a in advances) {
      items.add(GridTransactionItem(
        id: a.id,
        type: 'advance',
        refNo: 'Adv #${a.id.substring(0, a.id.length > 5 ? 5 : a.id.length)}',
        name: a.memberName,
        categoryOrBook: a.category.displayName,
        paymentMode: a.paymentMode,
        amount: a.advanceAmount,
        date: a.dateGiven,
        status: a.status,
        raw: a,
      ));
    }

    // 2. Filter Items
    final query = desktopCtrl.searchQuery.toLowerCase();
    final paymentFilter = desktopCtrl.paymentFilter;

    final filtered = items.where((item) {
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.refNo.toLowerCase().contains(query) ||
          item.categoryOrBook.toLowerCase().contains(query) ||
          item.amount.toString().contains(query);

      final matchesPayment = paymentFilter == 'All' ||
          (paymentFilter == 'Cash' && item.paymentMode == PaymentMode.cash) ||
          (paymentFilter == 'Online/UPI' && item.paymentMode == PaymentMode.upi) ||
          (paymentFilter == 'Bank' && item.paymentMode == PaymentMode.bankTransfer);

      return matchesSearch && matchesPayment;
    }).toList();

    // 3. Sort Items
    filtered.sort((a, b) {
      int cmp = 0;
      switch (desktopCtrl.sortColumn) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'ref':
          cmp = a.refNo.compareTo(b.refNo);
          break;
        case 'date':
        default:
          cmp = a.date.compareTo(b.date);
          break;
      }
      return desktopCtrl.sortAscending ? cmp : -cmp;
    });

    final allSelected = filtered.isNotEmpty && filtered.every((i) => desktopCtrl.isItemSelected(i.id));

    return Column(
      children: [
        // Table Filter & Bulk Actions Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0x1F1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              // Bulk Selection Summary or Total Count
              if (desktopCtrl.selectedCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                  ),
                  child: Text(
                    '${desktopCtrl.selectedCount} selected',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x3338BDF8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy CSV', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  onPressed: () => desktopCtrl.exportSelectedToCSV(context, provider),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => desktopCtrl.clearAllSelections(),
                  child: const Text('Clear Selection', style: TextStyle(fontSize: 11, color: Colors.white60)),
                ),
              ] else ...[
                Text(
                  '${filtered.length} Total Records',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
              ],
              const Spacer(),

              // Payment Filter Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0x1F0F172A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: desktopCtrl.paymentFilter,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(fontSize: 11.5, color: Colors.white),
                    items: ['All', 'Cash', 'Online/UPI', 'Bank'].map((mode) {
                      return DropdownMenuItem(value: mode, child: Text('Mode: $mode'));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) desktopCtrl.setPaymentFilter(val);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xF70C1527),
            border: Border(bottom: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Checkbox(
                  value: allSelected,
                  activeColor: AppTheme.primaryBlue,
                  onChanged: (v) {
                    if (v == true) {
                      desktopCtrl.selectAllItems(filtered.map((i) => i.id));
                    } else {
                      desktopCtrl.clearAllSelections();
                    }
                  },
                ),
              ),
              _buildHeaderColumn('Date & Time', 'date', flex: 3, desktopCtrl: desktopCtrl),
              _buildHeaderColumn('Ref / Voucher #', 'ref', flex: 2, desktopCtrl: desktopCtrl),
              _buildHeaderColumn('Party / Name', 'name', flex: 4, desktopCtrl: desktopCtrl),
              _buildHeaderColumn('Category / Book', 'category', flex: 3, desktopCtrl: desktopCtrl),
              _buildHeaderColumn('Payment Mode', 'mode', flex: 2, desktopCtrl: desktopCtrl),
              _buildHeaderColumn('Amount (₹)', 'amount', flex: 2, desktopCtrl: desktopCtrl, alignRight: true),
              _buildHeaderColumn('Status', 'status', flex: 2, desktopCtrl: desktopCtrl, alignRight: true),
              const SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white60), textAlign: TextAlign.center)),
            ],
          ),
        ),

        // Table Rows
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.white.withAlpha(80)),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching records found',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try adjusting your search query or filters',
                        style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(120)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemExtent: desktopCtrl.rowHeight,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = desktopCtrl.selectedTransactionId == item.id;
                    final isChecked = desktopCtrl.isItemSelected(item.id);

                    return InkWell(
                      onTap: () => desktopCtrl.selectTransaction(item.id, item.type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue.withAlpha(30)
                              : index.isEven
                                  ? const Color(0x08FFFFFF)
                                  : Colors.transparent,
                          border: Border(
                            bottom: const BorderSide(color: Color(0x0DFFFFFF)),
                            left: isSelected
                                ? const BorderSide(color: AppTheme.primaryBlue, width: 3.5)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Checkbox(
                                value: isChecked,
                                activeColor: AppTheme.primaryBlue,
                                onChanged: (_) => desktopCtrl.toggleItemSelection(item.id),
                              ),
                            ),
                            // Date
                            Expanded(
                              flex: 3,
                              child: Text(
                                dateFormat.format(item.date),
                                style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Ref #
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.refNo,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Name
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: item.type == 'donation'
                                          ? AppTheme.successGreen
                                          : item.type == 'expense'
                                              ? AppTheme.dangerRose
                                              : AppTheme.goldAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Category / Book
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.categoryOrBook,
                                style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(180)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Payment Mode Badge
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1FFFFFFF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.paymentMode.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white70),
                                  ),
                                ),
                              ),
                            ),
                            // Amount
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${item.type == "expense" ? "-" : "+"} ${currency.format(item.amount)}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: item.type == 'donation'
                                      ? AppTheme.successGreen
                                      : item.type == 'expense'
                                          ? AppTheme.dangerRose
                                          : AppTheme.goldAccent,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            // Status
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.status == 'Paid' || item.status == 'Approved' ? AppTheme.successGreen : AppTheme.goldAccent).withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: item.status == 'Paid' || item.status == 'Approved' ? AppTheme.successGreen : AppTheme.goldAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Actions
                            SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (item.type == 'donation')
                                    IconButton(
                                      icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white70),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Print Slip',
                                      onPressed: () => ReceiptShareService.printSlipPdf(
                                        slip: item.raw as ChandaSlip,
                                        pujaName: provider.pujaName,
                                        currentYear: provider.currentYear,
                                        cashierName: provider.cashierName,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16, color: AppTheme.primaryBlue),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Inspect Details',
                                    onPressed: () => desktopCtrl.selectTransaction(item.id, item.type),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderColumn(
    String title,
    String columnKey, {
    required int flex,
    required DesktopController desktopCtrl,
    bool alignRight = false,
  }) {
    final isSorted = desktopCtrl.sortColumn == columnKey;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => desktopCtrl.setSorting(columnKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
              ),
              if (isSorted) ...[
                const SizedBox(width: 4),
                Icon(
                  desktopCtrl.sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 12,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
