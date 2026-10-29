import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';

class ReceiptShareService {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);
  static final _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  /// Build formatted text receipt
  static String buildReceiptText({
    required ChandaSlip slip,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
  }) {
    final dateStr = _dateFormat.format(slip.paymentDate ?? slip.createdAt);
    final amtStr = _currency.format(slip.amount).replaceAll('Rs. ', '₹');
    final paidStr = _currency.format(slip.paidAmount).replaceAll('Rs. ', '₹');
    final pendingStr = _currency.format(slip.pendingAmount).replaceAll('Rs. ', '₹');
    final payModeStr = slip.paymentMode == PaymentMode.upi
        ? 'UPI / QR'
        : slip.paymentMode == PaymentMode.bankTransfer
            ? 'Bank Transfer'
            : 'Cash';

    final headerTitle = eventTitle ?? '$pujaName - $currentYear';

    if (slip.isInKind) {
      final valStr = slip.amount > 0 ? '💰 *Estimated Value:* ${_currency.format(slip.amount).replaceAll('Rs. ', '₹')}\n' : '';
      final statusStr = slip.isFullyPaid ? '✅ *Status:* RECEIVED / DELIVERED' : '⏳ *Status:* PROMISED / PENDING';
      final itemStr = slip.inKindItemName ?? 'Samagri Donation';
      final qtyStr = slip.inKindQuantity != null && slip.inKindQuantity!.isNotEmpty ? ' (${slip.inKindQuantity!})' : '';
      final catStr = slip.inKindCategory != null ? '📦 *Category:* ${slip.inKindCategory!.displayName.split(' (')[0]}\n' : '';

      return '''
🕉️ *${headerTitle.toUpperCase()}* 🕉️
_Official Samagri / In-Kind Donation Receipt_
━━━━━━━━━━━━━━━━━━━━
🧾 *Book No.:* #${slip.bookNumber}  |  *SL No.:* #${slip.slipNumber}
👤 *Donor Name:* ${slip.donorName}
${slip.phone != null && slip.phone!.isNotEmpty ? '📞 *Phone:* ${slip.phone}\n' : ''}${slip.address != null && slip.address!.isNotEmpty ? '📍 *Address:* ${slip.address}\n' : ''}🎁 *Item Donated:* $itemStr$qtyStr
$catStr$valStr$statusStr
🤝 *Received By:* ${slip.collectedBy}
📅 *Date:* $dateStr
${slip.notes != null && slip.notes!.isNotEmpty ? '📝 *Notes:* ${slip.notes}\n' : ''}━━━━━━━━━━━━━━━━━━━━
_May the divine blessings bring health, wealth & prosperity to you and your family!_ 🙏✨
''';
    }

    String statusSection;
    if (slip.isFullyPaid) {
      statusSection = '''
💰 *Amount Received:* $paidStr
✅ *Status:* FULLY PAID
💳 *Payment Mode:* $payModeStr''';
    } else if (slip.isPartial) {
      statusSection = '''
💰 *Total Amount:* $amtStr
💵 *Paid Amount:* $paidStr
⏳ *Pending Due:* $pendingStr
⚠️ *Status:* PARTIALLY PAID
💳 *Payment Mode:* $payModeStr''';
    } else {
      statusSection = '''
💰 *Total Chanda:* $amtStr
⏳ *Pending Due:* $amtStr
❌ *Status:* UNPAID / PENDING''';
    }

    String installmentHistory = '';
    if (slip.payments.isNotEmpty) {
      final pLines = slip.payments.map((p) {
        final d = _dateFormat.format(p.date);
        final a = _currency.format(p.amount).replaceAll('Rs. ', '₹');
        final m = p.paymentMode.name.toUpperCase();
        return '  • $d: $a ($m)';
      }).join('\n');
      installmentHistory = '\n\n🗓️ *Payment Dates & Amounts:*\n$pLines';
    }

    return '''
🕉️ *${headerTitle.toUpperCase()}* 🕉️
_Official Digital Chanda Receipt_
━━━━━━━━━━━━━━━━━━━━
🧾 *Book No.:* #${slip.bookNumber}  |  *SL No.:* #${slip.slipNumber}
👤 *Donor Name:* ${slip.donorName}
${slip.phone != null && slip.phone!.isNotEmpty ? '📞 *Phone:* ${slip.phone}\n' : ''}${slip.address != null && slip.address!.isNotEmpty ? '📍 *Address:* ${slip.address}\n' : ''}$statusSection$installmentHistory
🤝 *Collector:* ${slip.collectedBy}
📅 *Date & Time:* $dateStr
${slip.notes != null && slip.notes!.isNotEmpty ? '📝 *Notes:* ${slip.notes}\n' : ''}━━━━━━━━━━━━━━━━━━━━
_May the divine blessings bring health, wealth & prosperity to you and your family!_ 🙏✨
''';
  }

  /// Launch WhatsApp with PDF receipt
  static Future<void> sendOnWhatsApp({
    required ChandaSlip slip,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
    String? cashierName,
  }) async {
    await shareSlipPdf(
      slip: slip,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName ?? 'Cashier',
    );
  }

  /// Build formatted text statement for Contractor / Member Advance
  static String buildAdvanceStatementText({
    required MemberAdvance advance,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
  }) {
    final title = eventTitle ?? '$pujaName - $currentYear';
    final hasContract = advance.hasContract;
    final totalAmtStr = _currency.format(advance.effectiveOriginalAmount).replaceAll('Rs. ', '₹');
    final paidAmtStr = _currency.format(advance.advanceAmount).replaceAll('Rs. ', '₹');
    final dueAmtStr = _currency.format(advance.remainingDue).replaceAll('Rs. ', '₹');

    final installmentsText = advance.installments.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final inst = entry.value;
      final dStr = DateFormat('dd MMM yyyy').format(inst.date);
      final aStr = _currency.format(inst.amount).replaceAll('Rs. ', '₹');
      final mStr = inst.paymentMode.name.toUpperCase();
      final nStr = inst.note.isNotEmpty ? ' - ${inst.note}' : '';
      return '  $idx. $dStr: $aStr ($mStr)$nStr';
    }).join('\n');

    final statusStr = advance.status == 'Pending' ? '⏳ PENDING' : '✅ SETTLED';

    return '''
🕉️ *${title.toUpperCase()}* 🕉️
📋 *CONTRACTOR & ADVANCE STATEMENT*
━━━━━━━━━━━━━━━━━━━━
👤 *Contractor / Member:* ${advance.memberName}
📦 *Category:* ${advance.category.displayName}
📝 *Purpose / Details:* ${advance.purpose}
${hasContract ? '📜 *Total Contract / Deal Amount:* $totalAmtStr\n' : ''}💰 *Total Advance Disbursed:* $paidAmtStr
${hasContract ? '⏳ *Remaining Balance Due:* $dueAmtStr\n' : ''}📌 *Account Status:* $statusStr
━━━━━━━━━━━━━━━━━━━━
📑 *PAYMENT INSTALLMENTS (${advance.installments.length}):*
$installmentsText
━━━━━━━━━━━━━━━━━━━━
_Issued officially by Durga Puja Committee / Cashier Desk._
''';
  }

  /// Launch WhatsApp with Contractor Advance Statement
  static Future<void> sendAdvanceStatementOnWhatsApp({
    required MemberAdvance advance,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
    String? phone,
  }) async {
    final text = buildAdvanceStatementText(
      advance: advance,
      pujaName: pujaName,
      currentYear: currentYear,
      eventTitle: eventTitle,
    );

    String? cleanPhone = phone?.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone != null && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final encodedText = Uri.encodeComponent(text);

    if (cleanPhone != null && cleanPhone.isNotEmpty) {
      final uri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    await Share.share(text, subject: '$pujaName - Advance Statement: ${advance.memberName}');
  }

  /// Build formatted expense voucher text
  static String buildExpenseVoucherText({
    required ExpenseVoucher voucher,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
  }) {
    final title = eventTitle ?? '$pujaName - $currentYear';
    final dateStr = _dateFormat.format(voucher.date);
    final amtStr = _currency.format(voucher.amount).replaceAll('Rs. ', '₹');
    final payModeStr = voucher.paymentMode == PaymentMode.upi
        ? '📱 UPI / QR'
        : voucher.paymentMode == PaymentMode.bankTransfer
            ? '🏦 Bank Transfer'
            : '💵 Cash';

    final isAdv = voucher.isAdvance;

    return '''
🕉️ *${title.toUpperCase()}* 🕉️
${isAdv ? '👛 *OFFICIAL ADVANCE DISBURSEMENT VOUCHER*' : '💸 *OFFICIAL EXPENSE PAYMENT VOUCHER*'}
━━━━━━━━━━━━━━━━━━━━
🧾 *Voucher No:* #${voucher.voucherNo}
👤 *Paid To (Payee):* ${voucher.payeeName}
💰 *Amount Paid:* $amtStr
💳 *Payment Mode:* $payModeStr
📦 *Category:* ${voucher.category.displayName}
📅 *Date:* $dateStr
${voucher.paidBy.isNotEmpty ? '✍️ *Disbursed By:* ${voucher.paidBy}\n' : ''}${voucher.description != null && voucher.description!.isNotEmpty ? '📝 *Note / Purpose:* ${voucher.description}\n' : ''}━━━━━━━━━━━━━━━━━━━━
_Issued officially by Durga Puja Committee / Cashier Desk._
''';
  }

  /// Launch WhatsApp with Expense Voucher PDF
  static Future<void> sendExpenseVoucherOnWhatsApp({
    required ExpenseVoucher voucher,
    required String pujaName,
    required int currentYear,
    String? eventTitle,
    String? phone,
    String? cashierName,
  }) async {
    await shareExpenseVoucherPdf(
      voucher: voucher,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName ?? 'Cashier',
    );
  }

  /// Generate Single Expense Voucher PDF & Open Print / Save
  static Future<void> printExpenseVoucherPdf({
    required ExpenseVoucher voucher,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final pdfBytes = await generateExpenseVoucherPdf(
      voucher: voucher,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Expense_Voucher_${voucher.voucherNo}.pdf',
    );
  }

  /// Generate Single Expense Voucher PDF & Share directly
  static Future<void> shareExpenseVoucherPdf({
    required ExpenseVoucher voucher,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final pdfBytes = await generateExpenseVoucherPdf(
      voucher: voucher,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Expense_Voucher_${voucher.voucherNo}.pdf',
    );
  }

  /// Core Expense Voucher PDF Layout
  static Future<Uint8List> generateExpenseVoucherPdf({
    required ExpenseVoucher voucher,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final dateStr = _dateFormat.format(voucher.date);
    final amtStr = _currency.format(voucher.amount);
    final isAdv = voucher.isAdvance;

    final primaryColor = isAdv ? PdfColors.amber800 : PdfColors.red800;
    final bgColor = isAdv ? PdfColors.amber50 : PdfColors.red50;
    final borderColor = isAdv ? PdfColors.amber300 : PdfColors.red300;

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(148 * PdfPageFormat.mm, 105 * PdfPageFormat.mm), // A6 Landscape Card
        margin: const pw.EdgeInsets.all(16),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: primaryColor, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Top Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          pujaName.toUpperCase(),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                        ),
                        pw.Text(
                          isAdv
                              ? 'OFFICIAL ADVANCE DISBURSEMENT VOUCHER - $currentYear'
                              : 'OFFICIAL FESTIVAL EXPENSE VOUCHER - $currentYear',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'VOUCHER #${voucher.voucherNo}',
                        style: pw.TextStyle(color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: primaryColor, thickness: 1, height: 10),

                // Details Rows
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Paid To (Payee): ${voucher.payeeName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Category: ${voucher.category.displayName}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Amount Highlight Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: bgColor,
                    border: pw.Border.all(color: borderColor),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        isAdv ? 'Advance Disbursed Amount:' : 'Amount Paid in Full:',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        amtStr,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: isAdv ? PdfColors.amber900 : PdfColors.red900,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Mode: ${voucher.paymentMode.name.toUpperCase()}',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                    ),
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ],
                ),

                if (voucher.description != null && voucher.description!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Note / Purpose: ${voucher.description!.trim()}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                    maxLines: 2,
                  ),
                ],

                if (isAdv) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '* Linked to Contractor / Member Advance Installment Account *',
                    style: pw.TextStyle(fontSize: 7, color: PdfColors.amber900, fontStyle: pw.FontStyle.italic),
                  ),
                ],

                pw.Spacer(),

                // Signatory
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      voucher.paidBy.isNotEmpty ? 'Disbursed By: ${voucher.paidBy}' : 'Disbursed By: $cashierName',
                      style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 70, height: 0.8, color: PdfColors.grey600),
                        pw.SizedBox(height: 2),
                        pw.Text('Authorized Treasurer', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generate Single Slip PDF & Open Print / Save
  static Future<void> printSlipPdf({
    required ChandaSlip slip,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final pdfBytes = await generateSlipPdf(
      slip: slip,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Chanda_Receipt_Slip_${slip.slipNumber}.pdf',
    );
  }

  /// Generate Single Slip PDF & Share directly
  static Future<void> shareSlipPdf({
    required ChandaSlip slip,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final pdfBytes = await generateSlipPdf(
      slip: slip,
      pujaName: pujaName,
      currentYear: currentYear,
      cashierName: cashierName,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Chanda_Receipt_Slip_${slip.slipNumber}.pdf',
    );
  }

  /// Core Single Slip PDF Layout
  static Future<Uint8List> generateSlipPdf({
    required ChandaSlip slip,
    required String pujaName,
    required int currentYear,
    required String cashierName,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    final isKind = slip.isInKind;
    final primaryColor = isKind ? PdfColors.teal800 : PdfColors.amber800;
    final accentBg = isKind ? PdfColors.teal50 : PdfColors.amber50;
    final borderColor = isKind ? PdfColors.teal300 : PdfColors.amber300;

    // Collect and sort payments chronologically
    final sortedPayments = List<SlipPayment>.from(slip.payments)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Fallback if payments list was empty but paidAmount > 0
    final paymentList = sortedPayments.isNotEmpty
        ? sortedPayments
        : (slip.paidAmount > 0
            ? [
                SlipPayment(
                  id: '${slip.id}_init',
                  amount: slip.paidAmount,
                  date: slip.paymentDate ?? slip.createdAt,
                  paymentMode: slip.paymentMode,
                  collectedBy: slip.collectedBy,
                  note: 'Chanda Payment',
                ),
              ]
            : <SlipPayment>[]);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return [
            // Outer Frame Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryColor, width: 2),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER ROW
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              pujaName.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blueGrey900,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              isKind
                                  ? 'OFFICIAL SAMAGRI / IN-KIND DONATION RECEIPT - $currentYear'
                                  : 'OFFICIAL CHANDA RECEIPT & PAYMENT STATEMENT - $currentYear',
                              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                            ),
                            if (slip.accountName != null && slip.accountName!.isNotEmpty) ...[
                              pw.SizedBox(height: 1.5),
                              pw.Text(
                                'Collection A/C: ${slip.accountName}',
                                style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey700),
                              ),
                            ],
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: pw.BoxDecoration(
                          color: isKind ? PdfColors.teal900 : PdfColors.blueGrey900,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(
                            color: isKind ? PdfColors.teal300 : PdfColors.amber300,
                            width: 1,
                          ),
                        ),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'BOOK NO.',
                                  style: const pw.TextStyle(
                                    fontSize: 6.5,
                                    color: PdfColors.grey300,
                                  ),
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  '#${slip.bookNumber}',
                                  style: pw.TextStyle(
                                    color: isKind ? PdfColors.teal200 : PdfColors.amber300,
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            pw.Container(
                              height: 18,
                              width: 1,
                              color: isKind ? PdfColors.teal700 : PdfColors.blueGrey600,
                              margin: const pw.EdgeInsets.symmetric(horizontal: 8),
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'SL NO.',
                                  style: const pw.TextStyle(
                                    fontSize: 6.5,
                                    color: PdfColors.grey300,
                                  ),
                                ),
                                pw.SizedBox(height: 1),
                                pw.Text(
                                  '#${slip.slipNumber}',
                                  style: pw.TextStyle(
                                    color: isKind ? PdfColors.teal100 : PdfColors.amber300,
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.Divider(color: primaryColor, thickness: 1, height: 10),

                  // 2. CONTRIBUTOR & SLIP DETAILS
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.RichText(
                                text: pw.TextSpan(
                                  children: [
                                    const pw.TextSpan(text: 'Donor Name: ', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                                    pw.TextSpan(text: slip.donorName, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                                  ],
                                ),
                              ),
                              if (slip.phone != null && slip.phone!.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text('Phone: ${slip.phone}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                              ],
                              if (slip.address != null && slip.address!.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text('Address: ${slip.address}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                              ],
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Book No: #${slip.bookNumber}   •   SL No: #${slip.slipNumber}',
                                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey700),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Issue Date: ${_dateFormat.format(slip.paymentDate ?? slip.createdAt)}',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'Collector: ${slip.collectedBy.isNotEmpty ? slip.collectedBy : cashierName}',
                                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: pw.BoxDecoration(
                                  color: slip.isFullyPaid
                                      ? PdfColors.green100
                                      : (slip.isPartial ? PdfColors.amber100 : PdfColors.red100),
                                  borderRadius: pw.BorderRadius.circular(3),
                                ),
                                child: pw.Text(
                                  slip.isFullyPaid ? 'FULLY PAID' : (slip.isPartial ? 'PARTIALLY PAID' : 'UNPAID / DUE'),
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: slip.isFullyPaid
                                        ? PdfColors.green900
                                        : (slip.isPartial ? PdfColors.amber900 : PdfColors.red900),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 8),

                  // 3. IN-KIND HIGHLIGHT BOX (IF APPLICABLE)
                  if (isKind) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal50,
                        border: pw.Border.all(color: PdfColors.teal300),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'Offering: ${slip.inKindItemName ?? "Samagri"}${slip.inKindQuantity != null && slip.inKindQuantity!.isNotEmpty ? " (${slip.inKindQuantity})" : ""}',
                                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                              ),
                              if (slip.inKindCategory != null)
                                pw.Text('Category: ${slip.inKindCategory!.displayName.split(" (")[0]}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                slip.isFullyPaid ? 'RECEIVED' : 'PROMISED',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: slip.isFullyPaid ? PdfColors.green800 : PdfColors.orange800,
                                ),
                              ),
                              if (slip.amount > 0)
                                pw.Text('Est. Value: ${_currency.format(slip.amount)}', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],

                  // 4. FINANCIAL SUMMARY CARDS (3 COLUMNS)
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            border: pw.Border.all(color: PdfColors.blue200),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('TOTAL CHANDA', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.blue800)),
                              pw.SizedBox(height: 2),
                              pw.Text(_currency.format(slip.amount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            border: pw.Border.all(color: PdfColors.green200),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('TOTAL PAID (KUL JAMA)', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.green800)),
                              pw.SizedBox(height: 2),
                              pw.Text(_currency.format(slip.paidAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: slip.pendingAmount > 0 ? PdfColors.red50 : PdfColors.green50,
                            border: pw.Border.all(color: slip.pendingAmount > 0 ? PdfColors.red200 : PdfColors.green200),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('BALANCE DUE (BAKI)', style: pw.TextStyle(fontSize: 6.5, color: slip.pendingAmount > 0 ? PdfColors.red800 : PdfColors.green800)),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                _currency.format(slip.pendingAmount),
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: slip.pendingAmount > 0 ? PdfColors.red900 : PdfColors.green900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),

                  // 5. PAYMENT HISTORY TABLE ("KAB KITNA AMOUNT DIYA")
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PAYMENT HISTORY & DATES (KAB KITNA AMOUNT DIYA)',
                        style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800),
                      ),
                      pw.Text(
                        '${paymentList.length} Payment${paymentList.length == 1 ? "" : "s"} Recorded',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),

                  if (paymentList.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        border: pw.Border.all(color: PdfColors.red200),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'No payment has been received yet for this slip. Outstanding Due: ${_currency.format(slip.pendingAmount)}',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.red900),
                        textAlign: pw.TextAlign.center,
                      ),
                    )
                  else ...[
                    pw.TableHelper.fromTextArray(
                      headers: ['#', 'Payment Date & Time', 'Amount Paid', 'Mode', 'Collector', 'Note / Remarks'],
                      data: paymentList.asMap().entries.map((entry) {
                        final idx = entry.key + 1;
                        final p = entry.value;
                        final pDateStr = _dateFormat.format(p.date);
                        final pModeStr = p.paymentMode == PaymentMode.upi
                            ? 'UPI / QR'
                            : (p.paymentMode == PaymentMode.bankTransfer ? 'Bank Transfer' : 'Cash');
                        return [
                          '$idx',
                          pDateStr,
                          _currency.format(p.amount),
                          pModeStr,
                          p.collectedBy.isNotEmpty ? p.collectedBy : '-',
                          p.note != null && p.note!.trim().isNotEmpty ? p.note!.trim() : '-',
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5, color: PdfColors.white),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                      cellStyle: const pw.TextStyle(fontSize: 7.5),
                      cellAlignments: {
                        0: pw.Alignment.center,
                        1: pw.Alignment.centerLeft,
                        2: pw.Alignment.centerRight,
                        3: pw.Alignment.center,
                        4: pw.Alignment.centerLeft,
                        5: pw.Alignment.centerLeft,
                      },
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3.5),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                        borderRadius: const pw.BorderRadius.only(
                          bottomLeft: pw.Radius.circular(4),
                          bottomRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total Paid (Kul Jama): ${_currency.format(slip.paidAmount)}',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                          ),
                          pw.Text(
                            slip.pendingAmount > 0
                                ? 'Balance Remaining (Baki): ${_currency.format(slip.pendingAmount)}'
                                : 'All Dues Cleared',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                              color: slip.pendingAmount > 0 ? PdfColors.red900 : PdfColors.green900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 8),

                  // 6. DONOR NOTES (IF ANY)
                  if (slip.notes != null && slip.notes!.trim().isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: accentBg,
                        border: pw.Border.all(color: borderColor, width: 0.5),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'Notes / Instructions: ${slip.notes!.trim()}',
                        style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],

                  // 7. SIGNATURES & BLESSING FOOTER
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(width: 80, height: 0.6, color: PdfColors.grey600),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Received By: ${slip.collectedBy.isNotEmpty ? slip.collectedBy : cashierName}',
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                          ),
                          pw.Text('Official Collector', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'May Maa Durga bless you and your family!',
                            style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
                          ),
                          pw.Text(
                            'Digital Chanda Management System',
                            style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey500),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Container(width: 80, height: 0.6, color: PdfColors.grey600),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            cashierName,
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey800),
                          ),
                          pw.Text('Authorized Cashier', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }
}
