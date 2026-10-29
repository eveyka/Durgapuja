import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/desktop_controller.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';

class DesktopInspectorPanel extends StatelessWidget {
  const DesktopInspectorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final desktopCtrl = Provider.of<DesktopController>(context);
    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final txId = desktopCtrl.selectedTransactionId;
    final txType = desktopCtrl.selectedTransactionType;

    if (txId == null) return const SizedBox.shrink();

    // Find the record
    ChandaSlip? slip;
    ExpenseVoucher? expense;
    MemberAdvance? advance;

    if (txType == 'donation') {
      slip = provider.slips.where((s) => s.id == txId).firstOrNull;
    } else if (txType == 'expense') {
      expense = provider.expenses.where((e) => e.id == txId).firstOrNull;
    } else if (txType == 'advance') {
      advance = provider.advances.where((a) => a.id == txId).firstOrNull;
    }

    if (slip == null && expense == null && advance == null) {
      return const SizedBox.shrink();
    }

    final isDonation = slip != null;
    final isExpense = expense != null;
    final isAdvance = advance != null;

    final title = isDonation
        ? slip.donorName
        : isExpense
            ? expense.payeeName
            : advance!.memberName;

    final amount = isDonation
        ? slip.amount
        : isExpense
            ? expense.amount
            : advance!.advanceAmount;

    final date = isDonation
        ? slip.createdAt
        : isExpense
            ? expense.date
            : advance!.dateGiven;

    final mode = isDonation
        ? slip.paymentMode
        : isExpense
            ? expense.paymentMode
            : advance!.paymentMode;

    return Container(
      width: 380,
      margin: const EdgeInsets.fromLTRB(6, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xF7091124),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 20,
            offset: const Offset(-2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with Close Button
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDonation
                            ? AppTheme.successGreen.withAlpha(30)
                            : isExpense
                                ? AppTheme.dangerRose.withAlpha(30)
                                : AppTheme.goldAccent.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDonation
                            ? Icons.receipt_rounded
                            : isExpense
                                ? Icons.receipt_long_rounded
                                : Icons.wallet_rounded,
                        color: isDonation
                            ? AppTheme.successGreen
                            : isExpense
                                ? AppTheme.dangerRose
                                : AppTheme.goldAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDonation
                              ? 'DONATION SLIP #${slip.slipNumber}'
                              : isExpense
                                  ? 'EXPENSE VOUCHER #${expense.voucherNo}'
                                  : 'MEMBER ADVANCE',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isDonation ? 'Chanda Collection Record' : isExpense ? 'Puja Expenditure Record' : 'Contract Advance',
                          style: const TextStyle(fontSize: 10, color: Colors.white60),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Close Panel (Esc)',
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  onPressed: () => desktopCtrl.closeInspector(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // 2. Main Details Scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Amount Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDonation
                            ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                            : isExpense
                                ? [const Color(0xFF881337), const Color(0xFF4C0519)]
                                : [const Color(0xFF78350F), const Color(0xFF451A03)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDonation
                            ? AppTheme.successGreen.withAlpha(80)
                            : isExpense
                                ? AppTheme.dangerRose.withAlpha(80)
                                : AppTheme.goldAccent.withAlpha(80),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDonation ? 'Total Received' : isExpense ? 'Total Paid Out' : 'Advance Disbursed',
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.format(amount),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    mode == PaymentMode.cash
                                        ? Icons.money_rounded
                                        : mode == PaymentMode.upi
                                            ? Icons.qr_code_rounded
                                            : Icons.account_balance_rounded,
                                    size: 13,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    mode.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isDonation ? (slip.isFullyPaid ? AppTheme.successGreen : AppTheme.dangerRose) : AppTheme.successGreen).withAlpha(40),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isDonation ? (slip.isFullyPaid ? 'FULLY PAID' : 'PAYMENT DUE') : (isExpense ? 'APPROVED' : advance!.status.toUpperCase()),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: isDonation ? (slip.isFullyPaid ? AppTheme.successGreen : AppTheme.dangerRose) : AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Detail Attributes List
                  _buildDetailRow('Name / Party', title, Icons.person_rounded),
                  _buildDetailRow('Timestamp', dateFormat.format(date), Icons.access_time_rounded),

                  if (isDonation) ...[
                    _buildDetailRow('Book Number', 'Book #${slip.bookNumber}', Icons.menu_book_rounded),
                    _buildDetailRow('Slip Number', 'Slip #${slip.slipNumber}', Icons.numbers_rounded),
                    if (slip.phone != null && slip.phone!.isNotEmpty)
                      _buildDetailRow('Contact Phone', slip.phone!, Icons.phone_rounded),
                    if (slip.address != null && slip.address!.isNotEmpty)
                      _buildDetailRow('Address', slip.address!, Icons.home_rounded),
                    if (slip.collectedBy.isNotEmpty)
                      _buildDetailRow('Cashier / Collector', slip.collectedBy, Icons.badge_rounded),
                    if (slip.notes != null && slip.notes!.isNotEmpty)
                      _buildDetailRow('Notes / Remarks', slip.notes!, Icons.note_alt_rounded),
                  ] else if (isExpense) ...[
                    _buildDetailRow('Category', expense.category.displayName, Icons.category_rounded),
                    _buildDetailRow('Voucher No.', '#${expense.voucherNo}', Icons.tag_rounded),
                    if (expense.paidBy.isNotEmpty)
                      _buildDetailRow('Authorized / Paid By', expense.paidBy, Icons.verified_user_rounded),
                    if (expense.description != null && expense.description!.isNotEmpty)
                      _buildDetailRow('Description', expense.description!, Icons.description_rounded),
                  ] else if (isAdvance) ...[
                    _buildDetailRow('Category', advance.category.displayName, Icons.category_rounded),
                    _buildDetailRow('Purpose', advance.purpose, Icons.assignment_rounded),
                    _buildDetailRow('Remaining Due', currency.format(advance.remainingDue), Icons.pending_actions_rounded),
                  ],
                ],
              ),
            ),
          ),

          // 3. Quick Action Buttons Footer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0x1F1E293B),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Column(
              children: [
                if (isDonation) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: const Color(0xFF070D1E),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('Print Slip', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          onPressed: () => ReceiptShareService.printSlipPdf(
                            slip: slip!,
                            pujaName: provider.pujaName,
                            currentYear: provider.currentYear,
                            cashierName: provider.cashierName,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: AppTheme.glassBorder),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.share_rounded, size: 15),
                          label: const Text('Share PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          onPressed: () => ReceiptShareService.shareSlipPdf(
                            slip: slip!,
                            pujaName: provider.pujaName,
                            currentYear: provider.currentYear,
                            cashierName: provider.cashierName,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerRose,
                          side: BorderSide(color: AppTheme.dangerRose.withAlpha(90)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 15),
                        label: const Text('Delete / Void', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _confirmDelete(context, provider, desktopCtrl, isDonation, isExpense, isAdvance, txId),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    PujaProvider provider,
    DesktopController desktopCtrl,
    bool isDonation,
    bool isExpense,
    bool isAdvance,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Delete Record?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently remove this transaction from the ledger? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRose),
            onPressed: () {
              Navigator.pop(ctx);
              if (isDonation) {
                provider.deleteDonation(id);
              } else if (isExpense) {
                provider.deleteExpense(id);
              } else if (isAdvance) {
                provider.deleteAdvance(id);
              }
              desktopCtrl.closeInspector();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
