import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../services/receipt_share_service.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';
import 'glass_container.dart';

class AdvanceAccountCard extends StatefulWidget {
  final MemberAdvance advance;
  final NumberFormat currency;
  final PujaProvider provider;
  final PujaEvent? activeEvent;
  final EdgeInsetsGeometry? margin;
  final bool isGrid;

  const AdvanceAccountCard({
    super.key,
    required this.advance,
    required this.currency,
    required this.provider,
    this.activeEvent,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.isGrid = false,
  });

  @override
  State<AdvanceAccountCard> createState() => _AdvanceAccountCardState();
}

class _AdvanceAccountCardState extends State<AdvanceAccountCard> {
  bool _isInstallmentsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final adv = widget.advance;
    final currency = widget.currency;
    final provider = widget.provider;
    final isPending = adv.status == 'Pending';
    final hasContract = adv.hasContract;

    return GlassContainer(
      borderRadius: 20,
      margin: widget.margin,
      padding: EdgeInsets.all(widget.isGrid ? 13 : 16),
      border: Border.all(
        color: isPending
            ? const Color(0xFFF59E0B).withAlpha(55)
            : const Color(0xFF10B981).withAlpha(55),
        width: 1.2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category Avatar, Contractor/Member Name, Category/Date Subtitle, Status & 3-Line Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: adv.category.color.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: adv.category.color.withAlpha(75)),
                ),
                child: Center(
                  child: Icon(adv.category.icon, size: 20, color: adv.category.color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adv.memberName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${adv.category.displayName} • ${DateFormat('dd MMM yyyy').format(adv.dateGiven)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
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
                  color: isPending
                      ? const Color(0xFFF59E0B).withAlpha(30)
                      : const Color(0xFF10B981).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPending
                        ? const Color(0xFFF59E0B).withAlpha(100)
                        : const Color(0xFF10B981).withAlpha(100),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending ? Icons.schedule_rounded : Icons.check_circle_rounded,
                      size: 11,
                      color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPending ? 'PENDING' : 'SETTLED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Bill Badge (if attached)
              if (adv.receiptPhotoUrl != null && adv.receiptPhotoUrl!.isNotEmpty) ...[
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => BillImagePreviewDialog(
                      imageUrl: adv.receiptPhotoUrl!,
                      title: adv.memberName,
                      subtitle: '${adv.category.displayName} Advance Receipt',
                      onDelete: () {
                        provider.updateAdvanceReceiptPhoto(advanceId: adv.id, photoUrl: null);
                        Navigator.pop(context);
                      },
                      onReplace: () => showAttachBillModal(
                        context,
                        onUploaded: (url) {
                          provider.updateAdvanceReceiptPhoto(advanceId: adv.id, photoUrl: url);
                        },
                        existingUrl: adv.receiptPhotoUrl,
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
                const SizedBox(width: 6),
              ],

              // 3-Line Menu Button ("chota bra 3 line" menu)
              _buildCardMenuButton(context, provider),
            ],
          ),

          // Row 2: Structured Financial Overview (Contract Deal, Advance Paid, Balance Due)
          Container(
            margin: EdgeInsets.symmetric(vertical: widget.isGrid ? 8 : 12),
            padding: EdgeInsets.symmetric(horizontal: widget.isGrid ? 12 : 14, vertical: widget.isGrid ? 9 : 12),
            decoration: BoxDecoration(
              color: const Color(0x1F0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPending
                    ? const Color(0xFFF59E0B).withAlpha(40)
                    : const Color(0xFF10B981).withAlpha(40),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasContract) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Contract Deal
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract Deal',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currency.format(adv.effectiveOriginalAmount),
                            style: TextStyle(fontSize: widget.isGrid ? 14 : 15, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),

                      // Total Advance Paid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            !isPending ? 'Total Paid (${adv.installments.length})' : 'Advance Paid (${adv.installments.length})',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !isPending ? currency.format(adv.actualSpent ?? adv.advanceAmount) : currency.format(adv.advanceAmount),
                            style: TextStyle(fontSize: widget.isGrid ? 14.5 : 15.5, fontWeight: FontWeight.w900, color: AppTheme.goldAccent),
                          ),
                        ],
                      ),

                      // Balance Due
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Balance Due',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !isPending ? '₹0 (Settled)' : currency.format(adv.remainingDue),
                            style: TextStyle(
                              fontSize: widget.isGrid ? 14 : 15,
                              fontWeight: FontWeight.w900,
                              color: !isPending ? const Color(0xFF10B981) : (adv.remainingDue > 0 ? const Color(0xFFF87171) : const Color(0xFF10B981)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: widget.isGrid ? 8 : 10),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            !isPending
                                ? '✅ 100% Contract Cleared'
                                : '${(adv.paidPercentage * 100).toStringAsFixed(0)}% Disbursed in advance',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: !isPending ? const Color(0xFF10B981) : Colors.white.withAlpha(150),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            !isPending
                                ? '${currency.format(adv.actualSpent ?? adv.advanceAmount)} / ${currency.format(adv.effectiveOriginalAmount)}'
                                : '${currency.format(adv.advanceAmount)} / ${currency.format(adv.effectiveOriginalAmount)}',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(150), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: adv.paidPercentage,
                          minHeight: 6,
                          backgroundColor: const Color(0x33FFFFFF),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            adv.paidPercentage >= 1.0 ? const Color(0xFF10B981) : AppTheme.goldAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Advance Handed Over',
                            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currency.format(adv.advanceAmount),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.goldAccent),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primaryBlue.withAlpha(60)),
                        ),
                        child: Text(
                          '${adv.installments.length} payment(s)',
                          style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],

                if (adv.purpose.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '📝 ${adv.purpose}',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(170), fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Row 3: Installments Timeline Section ("thora thora krke add krna")
          Container(
            margin: EdgeInsets.only(bottom: widget.isGrid ? 8 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(12)),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    if (widget.isGrid) {
                      // On Desktop Grid, open detailed breakdown dialog to prevent card flex overflow
                      showDialog(
                        context: context,
                        builder: (_) => AdvanceActionDialog(advance: adv),
                      );
                    } else {
                      setState(() => _isInstallmentsExpanded = !_isInstallmentsExpanded);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isGrid ? 10 : 12,
                      vertical: widget.isGrid ? 7 : 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history_rounded, size: 14, color: Colors.white.withAlpha(180)),
                            const SizedBox(width: 6),
                            Text(
                              'Payment Installments (${adv.installments.length})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              widget.isGrid
                                  ? 'View All ↗'
                                  : (_isInstallmentsExpanded ? 'Hide' : 'View Breakdown'),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: widget.isGrid ? AppTheme.primaryBlue : Colors.white.withAlpha(140),
                                fontWeight: widget.isGrid ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              widget.isGrid
                                  ? Icons.arrow_outward_rounded
                                  : (_isInstallmentsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                              size: widget.isGrid ? 14 : 16,
                              color: widget.isGrid ? AppTheme.primaryBlue : Colors.white70,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (!widget.isGrid && _isInstallmentsExpanded) ...[
                  const Divider(height: 1, color: AppTheme.glassBorder),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: adv.installments.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final inst = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldAccent.withAlpha(30),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$idx',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currency.format(inst.amount),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Text(
                                        '${DateFormat('dd MMM yyyy').format(inst.date)} • ${inst.paymentMode.name.toUpperCase()}${inst.note.isNotEmpty ? " • ${inst.note}" : ""}',
                                        style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Installment options',
                                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.white70),
                                color: const Color(0xFF0F172A),
                                elevation: 8,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: AppTheme.glassBorder),
                                ),
                                onSelected: (val) {
                                  if (val == 'edit') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => EditAdvanceInstallmentDialog(
                                        advance: adv,
                                        installment: inst,
                                      ),
                                    );
                                  } else if (val == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (_) => ConfirmDeleteDialog(
                                        title: 'Delete Installment #$idx?',
                                        message: 'Delete installment of ${currency.format(inst.amount)} recorded on ${DateFormat('dd MMM yyyy').format(inst.date)}?',
                                        onConfirm: () => provider.deleteAdvanceInstallment(
                                          advanceId: adv.id,
                                          installmentId: inst.id,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    height: 38,
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
                                        SizedBox(width: 10),
                                        Text('Edit Installment', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuDivider(height: 1),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    height: 38,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRose),
                                        SizedBox(width: 10),
                                        Text('Delete Installment', style: TextStyle(color: AppTheme.dangerRose, fontSize: 12.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Row 4: Settlement Details if already settled
          if (!isPending && adv.actualSpent != null) ...[
            Container(
              margin: EdgeInsets.only(bottom: widget.isGrid ? 8 : 12),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: widget.isGrid ? 7 : 10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(50)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Final Spent: ${currency.format(adv.actualSpent!)}',
                    style: TextStyle(fontSize: widget.isGrid ? 11 : 11.5, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (adv.returnAmount != null && adv.returnAmount! > 0)
                    Text(
                      'Returned: ${currency.format(adv.returnAmount!)}',
                      style: TextStyle(fontSize: widget.isGrid ? 11 : 11.5, color: const Color(0xFF10B981), fontWeight: FontWeight.bold),
                    )
                  else if (adv.extraClaimAmount != null && adv.extraClaimAmount! > 0)
                    Text(
                      'Extra Paid: ${currency.format(adv.extraClaimAmount!)}',
                      style: TextStyle(fontSize: widget.isGrid ? 11 : 11.5, color: const Color(0xFFF87171), fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          ],

          // Row 5: Action Buttons (+ Add Advance & Settle Account)
          if (isPending)
            Row(
              children: [
                // Quick "+ Add Advance" Button
                Expanded(
                  child: SizedBox(
                    height: widget.isGrid ? 35 : 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent.withAlpha(40),
                        foregroundColor: AppTheme.goldAccent,
                        side: BorderSide(color: AppTheme.goldAccent.withAlpha(120)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 14),
                      label: const Text(
                        '+ Add Advance',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddAdvanceInstallmentDialog(advance: adv),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // "Settle Account" Button
                Expanded(
                  child: SizedBox(
                    height: widget.isGrid ? 35 : 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 14),
                      label: const Text(
                        'Settle Final Bill',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => SettleAdvanceDialog(advance: adv),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCardMenuButton(BuildContext context, PujaProvider provider) {
    final adv = widget.advance;
    final isPending = adv.status == 'Pending';

    return PopupMenuButton<String>(
      tooltip: 'Options',
      color: const Color(0xFF0F172A),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.glassBorder, width: 1.2),
      ),
      onSelected: (val) {
        if (val == 'add_advance') {
          showDialog(
            context: context,
            builder: (_) => AddAdvanceInstallmentDialog(advance: adv),
          );
        } else if (val == 'view') {
          showDialog(
            context: context,
            builder: (_) => AdvanceActionDialog(advance: adv),
          );
        } else if (val == 'view_bill') {
          if (adv.receiptPhotoUrl != null && adv.receiptPhotoUrl!.isNotEmpty) {
            showDialog(
              context: context,
              builder: (_) => BillImagePreviewDialog(
                imageUrl: adv.receiptPhotoUrl!,
                title: adv.memberName,
                subtitle: '${adv.category.displayName} Advance Receipt',
                onDelete: () {
                  provider.updateAdvanceReceiptPhoto(advanceId: adv.id, photoUrl: null);
                  Navigator.pop(context);
                },
                onReplace: () => showAttachBillModal(
                  context,
                  onUploaded: (url) {
                    provider.updateAdvanceReceiptPhoto(advanceId: adv.id, photoUrl: url);
                  },
                  existingUrl: adv.receiptPhotoUrl,
                ),
              ),
            );
          }
        } else if (val == 'attach_bill') {
          showAttachBillModal(
            context,
            onUploaded: (url) {
              provider.updateAdvanceReceiptPhoto(advanceId: adv.id, photoUrl: url);
            },
            existingUrl: adv.receiptPhotoUrl,
          );
        } else if (val == 'share') {
          ReceiptShareService.sendAdvanceStatementOnWhatsApp(
            advance: adv,
            pujaName: provider.pujaName,
            currentYear: provider.currentYear,
            eventTitle: widget.activeEvent?.title,
          );
        } else if (val == 'edit') {
          showDialog(
            context: context,
            builder: (_) => GiveAdvanceDialog(
              existing: adv,
              initialEventId: widget.activeEvent?.id,
            ),
          );
        } else if (val == 'delete') {
          _confirmDelete(context, provider);
        }
      },
      itemBuilder: (ctx) => [
        if (isPending) ...[
          PopupMenuItem<String>(
            value: 'add_advance',
            height: 44,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppTheme.goldAccent),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Advance Payment',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
        if (adv.receiptPhotoUrl != null && adv.receiptPhotoUrl!.isNotEmpty) ...[
          PopupMenuItem<String>(
            value: 'view_bill',
            height: 44,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'View Attached Bill',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ] else ...[
          PopupMenuItem<String>(
            value: 'attach_bill',
            height: 44,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.goldAccent.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.attach_file_rounded, size: 16, color: AppTheme.goldAccent),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Attach Bill / Receipt',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),
        ],
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
                'View Full Statement',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
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
                  color: AppTheme.primaryBlue.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Account & Deal',
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
                'Delete Account',
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

  void _confirmDelete(BuildContext context, PujaProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => DeleteConfirmDialog(
        title: 'Delete Advance Account?',
        message: 'Are you sure you want to delete the advance account for "${widget.advance.memberName}" of ${widget.currency.format(widget.advance.advanceAmount)}?',
        onConfirm: () => provider.deleteAdvance(widget.advance.id),
      ),
    );
  }
}
