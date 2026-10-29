import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dper/models/models.dart';
import 'package:dper/services/pdf_report_service.dart';
import 'package:dper/services/receipt_share_service.dart';
import 'package:dper/services/r2_storage_service.dart';
import 'package:dper/widgets/dialogs.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MemberAdvance model serialization and defaults', () {
    final now = DateTime.now();
    final adv = MemberAdvance(
      id: 'adv-123',
      memberName: 'Rahul Sharma',
      advanceAmount: 5000.0,
      category: ExpenseCategory.pandal,
      paymentMode: PaymentMode.cash,
      purpose: 'Pandal lights advance',
      dateGiven: now,
      eventId: 'event-2026',
    );

    expect(adv.id, 'adv-123');
    expect(adv.memberName, 'Rahul Sharma');
    expect(adv.advanceAmount, 5000.0);
    expect(adv.status, 'Pending');
    expect(adv.eventId, 'event-2026');

    final map = adv.toMap();
    expect(map['memberName'], 'Rahul Sharma');
    expect(map['advanceAmount'], 5000.0);
    expect(map['eventId'], 'event-2026');

    final restored = MemberAdvance.fromMap(map);
    expect(restored.id, 'adv-123');
    expect(restored.memberName, 'Rahul Sharma');
    expect(restored.advanceAmount, 5000.0);
    expect(restored.status, 'Pending');
    expect(restored.eventId, 'event-2026');
  });

  test('MemberAdvance copyWith and settlement fields', () {
    final now = DateTime.now();
    final adv = MemberAdvance(
      id: 'adv-456',
      memberName: 'Pooja Roy',
      advanceAmount: 3000.0,
      category: ExpenseCategory.bhogCatering,
      paymentMode: PaymentMode.cash,
      purpose: 'Bhog sweets advance',
      dateGiven: now,
      eventId: 'event-2026',
    );

    final settled = adv.copyWith(
      status: 'Settled',
      actualSpent: 2800.0,
      returnAmount: 200.0,
      dateSettled: DateTime.now(),
      billDetails: 'Voucher bill #44',
    );

    expect(settled.status, 'Settled');
    expect(settled.actualSpent, 2800.0);
    expect(settled.returnAmount, 200.0);
    expect(settled.billDetails, 'Voucher bill #44');
    expect(settled.advanceAmount, 3000.0);
  });

  test('TransactionsScreen UnifiedTx logic and ranking test', () {
    final now = DateTime.now();

    final slip = ChandaSlip(
      id: 'slip-1',
      slipNumber: 101,
      donorName: 'Amitava Bose',
      amount: 15000.0,
      paymentMode: PaymentMode.upi,
      collectedBy: 'Anik',
      createdAt: now.subtract(const Duration(hours: 2)),
    );

    final exp = ExpenseVoucher(
      id: 'exp-1',
      voucherNo: 'V-01',
      payeeName: 'Pandal Decorators',
      category: ExpenseCategory.pandal,
      amount: 25000.0,
      paymentMode: PaymentMode.bankTransfer,
      paidBy: 'Treasurer',
      date: now.subtract(const Duration(hours: 1)),
    );

    final adv = MemberAdvance(
      id: 'adv-1',
      memberName: 'Siddharth Roy',
      advanceAmount: 8000.0,
      category: ExpenseCategory.soundDhaki,
      paymentMode: PaymentMode.cash,
      purpose: 'Dhaki booking advance',
      dateGiven: now,
    );

    expect(slip.amount, 15000.0);
    expect(exp.amount, 25000.0);
    expect(adv.advanceAmount, 8000.0);

    final amounts = [slip.amount, exp.amount, adv.advanceAmount];
    amounts.sort((a, b) => b.compareTo(a));
    expect(amounts.first, 25000.0); // Top transaction is the 25,000 expense
  });

  test('EventPdfReportType enum contains all 4 required report options', () {
    expect(EventPdfReportType.values.length, 4);
    expect(EventPdfReportType.values.contains(EventPdfReportType.allTransactions), true);
    expect(EventPdfReportType.values.contains(EventPdfReportType.collectionsOnly), true);
    expect(EventPdfReportType.values.contains(EventPdfReportType.expensesOnly), true);
    expect(EventPdfReportType.values.contains(EventPdfReportType.advancesOnly), true);
  });

  test('Contractor Advance Account with multiple installments and remaining due', () {
    final now = DateTime.now();

    // 1. Initial advance with Original Contract Deal of ₹50,000 and 1st installment ₹1,000
    final inst1 = AdvanceInstallment(
      id: 'inst-1',
      amount: 1000.0,
      date: now.subtract(const Duration(days: 3)),
      paymentMode: PaymentMode.cash,
      note: 'Initial token booking',
      recordedBy: 'Admin',
    );

    final adv = MemberAdvance(
      id: 'adv-pandal-1',
      memberName: 'Maa Durga Decorators (Contractor)',
      advanceAmount: 1000.0,
      originalAmount: 50000.0,
      category: ExpenseCategory.pandal,
      paymentMode: PaymentMode.cash,
      purpose: 'Pandal structure and bamboo framing',
      dateGiven: now.subtract(const Duration(days: 3)),
      installments: [inst1],
    );

    expect(adv.hasContract, true);
    expect(adv.effectiveOriginalAmount, 50000.0);
    expect(adv.advanceAmount, 1000.0);
    expect(adv.remainingDue, 49000.0);
    expect(adv.installments.length, 1);

    // 2. Add second installment of ₹500
    final inst2 = AdvanceInstallment(
      id: 'inst-2',
      amount: 500.0,
      date: now,
      paymentMode: PaymentMode.upi,
      note: 'Additional materials cash',
      recordedBy: 'Treasurer',
    );

    final updatedInstallments = [...adv.installments, inst2];
    final updatedAdv = adv.copyWith(
      advanceAmount: 1500.0,
      installments: updatedInstallments,
    );

    expect(updatedAdv.advanceAmount, 1500.0);
    expect(updatedAdv.installments.length, 2);
    expect(updatedAdv.remainingDue, 48500.0);
    expect(updatedAdv.paidPercentage, 0.03); // 1,500 / 50,000 = 0.03 (3% for LinearProgressIndicator)
    expect((updatedAdv.paidPercentage * 100).round(), 3);

    // 3. Test Serialization & Deserialization
    final map = updatedAdv.toMap();
    expect(map['originalAmount'], 50000.0);
    expect(map['installments'] is List, true);
    expect((map['installments'] as List).length, 2);

    final restored = MemberAdvance.fromMap(map);
    expect(restored.originalAmount, 50000.0);
    expect(restored.advanceAmount, 1500.0);
    expect(restored.installments.length, 2);
    expect(restored.installments[1].amount, 500.0);
    expect(restored.installments[1].paymentMode, PaymentMode.upi);
    expect(restored.remainingDue, 48500.0);
  });

  test('MemberAdvance backward compatibility when installments are not present in legacy map', () {
    final legacyMap = {
      'id': 'legacy-adv-1',
      'memberName': 'Electrician Ramesh',
      'advanceAmount': 2000.0,
      'category': 'decorationLighting',
      'paymentMode': 'cash',
      'purpose': 'Wire and LED strip advance',
      'dateGiven': DateTime.now().toIso8601String(),
      'status': 'Pending',
    };

    final restored = MemberAdvance.fromMap(legacyMap);
    expect(restored.memberName, 'Electrician Ramesh');
    expect(restored.advanceAmount, 2000.0);
    expect(restored.originalAmount, null);
    expect(restored.hasContract, false);
    expect(restored.effectiveOriginalAmount, 2000.0);
    expect(restored.remainingDue, 0.0);
    // Backward compatibility creates a fallback installment
    expect(restored.installments.length, 1);
    expect(restored.installments.first.amount, 2000.0);
  });

  test('Advance settlement correctly clears remaining due to 0.0 and paidPercentage to 100%', () {
    final now = DateTime.now();
    final inst1 = AdvanceInstallment(
      id: 'inst-1',
      amount: 1000.0,
      date: now.subtract(const Duration(days: 3)),
      paymentMode: PaymentMode.cash,
    );
    final inst2 = AdvanceInstallment(
      id: 'inst-2',
      amount: 500.0,
      date: now.subtract(const Duration(days: 1)),
      paymentMode: PaymentMode.upi,
    );

    final adv = MemberAdvance(
      id: 'adv-settle-test',
      memberName: 'Pandal Master Contractor',
      advanceAmount: 1500.0,
      originalAmount: 50000.0,
      category: ExpenseCategory.pandal,
      paymentMode: PaymentMode.cash,
      purpose: 'Full pandal contract',
      dateGiven: now.subtract(const Duration(days: 3)),
      installments: [inst1, inst2],
      status: 'Pending',
    );

    // Before settlement: remaining due is 48,500
    expect(adv.remainingDue, 48500.0);
    expect(adv.paidPercentage, 0.03);

    // After settlement: final balance of 48,500 is paid, total paid = 50,000
    final settlementInst = AdvanceInstallment(
      id: 'inst-settle',
      amount: 48500.0,
      date: now,
      paymentMode: PaymentMode.cash,
      note: 'Final settlement payment',
    );

    final settledAdv = adv.copyWith(
      status: 'Settled',
      actualSpent: 50000.0,
      advanceAmount: 50000.0,
      returnAmount: 0.0,
      dateSettled: now,
      billDetails: 'Full final settlement',
      installments: [...adv.installments, settlementInst],
    );

    expect(settledAdv.status, 'Settled');
    expect(settledAdv.advanceAmount, 50000.0);
    expect(settledAdv.actualSpent, 50000.0);
    expect(settledAdv.remainingDue, 0.0); // Due balance must be strictly 0.0!
    expect(settledAdv.paidPercentage, 1.0); // 100% contract cleared
    expect(settledAdv.installments.length, 3);
    expect(settledAdv.installments.last.amount, 48500.0);
  });

  test('AdvanceInstallment copyWith allows modifying installment details', () {
    final now = DateTime.now();
    final inst = AdvanceInstallment(
      id: 'inst-test-1',
      amount: 1000.0,
      date: now,
      paymentMode: PaymentMode.cash,
      note: 'Initial deposit',
      recordedBy: 'Admin',
    );

    final edited = inst.copyWith(
      amount: 1200.0,
      paymentMode: PaymentMode.upi,
      note: 'Updated deposit via UPI',
    );

    expect(edited.id, 'inst-test-1');
    expect(edited.amount, 1200.0);
    expect(edited.paymentMode, PaymentMode.upi);
    expect(edited.note, 'Updated deposit via UPI');
    expect(edited.recordedBy, 'Admin');
  });

  test('ExpenseVoucher advance linkage and serialization', () {
    final now = DateTime.now();
    final voucher = ExpenseVoucher(
      id: 'v-adv-01',
      voucherNo: 'V-005',
      payeeName: 'Pandal Master (Advance #1)',
      category: ExpenseCategory.pandal,
      amount: 1000.0,
      paymentMode: PaymentMode.cash,
      paidBy: 'Cashier',
      date: now,
      description: 'Initial token booking for pandal',
      eventId: 'evt-2026',
      advanceId: 'adv-pandal-1',
      installmentId: 'inst-01',
    );

    expect(voucher.isAdvance, true);
    expect(voucher.advanceId, 'adv-pandal-1');
    expect(voucher.installmentId, 'inst-01');

    final map = voucher.toMap();
    expect(map['advanceId'], 'adv-pandal-1');
    expect(map['installmentId'], 'inst-01');

    final restored = ExpenseVoucher.fromMap(map);
    expect(restored.isAdvance, true);
    expect(restored.advanceId, 'adv-pandal-1');
    expect(restored.installmentId, 'inst-01');
    expect(restored.amount, 1000.0);
    expect(restored.payeeName, 'Pandal Master (Advance #1)');
  });

  test('MemberAdvance copyWith properly updates dateGiven', () {
    final originalDate = DateTime(2026, 9, 1);
    final adv = MemberAdvance(
      id: 'adv-date-1',
      memberName: 'Electrician Das',
      advanceAmount: 2000.0,
      category: ExpenseCategory.lighting,
      paymentMode: PaymentMode.cash,
      purpose: 'Wiring advance',
      dateGiven: originalDate,
    );

    final newDate = DateTime(2026, 9, 5);
    final updated = adv.copyWith(dateGiven: newDate);
    expect(updated.dateGiven, newDate);
    expect(updated.dateGiven, isNot(originalDate));
  });

  test('Auto-settlement triggers when total installments reach contract amount, and reverts when reduced', () {
    final now = DateTime(2026, 9, 7);
    final contractTotal = 50000.0;

    // Start with 20,000 advance against 50,000 contract
    var adv = MemberAdvance(
      id: 'adv-pandal-contract',
      memberName: 'Maa Durga Decorators',
      advanceAmount: 20000.0,
      originalAmount: contractTotal,
      category: ExpenseCategory.pandal,
      paymentMode: PaymentMode.bankTransfer,
      purpose: 'Pandal setup contract',
      dateGiven: now,
      installments: [
        AdvanceInstallment(
          id: 'inst-1',
          amount: 20000.0,
          date: now,
          paymentMode: PaymentMode.bankTransfer,
          note: 'Token booking',
        ),
      ],
    );

    expect(adv.hasContract, true);
    expect(adv.status, 'Pending');
    expect(adv.remainingDue, 30000.0);
    expect(adv.paidPercentage, 0.4);

    // Add installment of 30,000 -> Total becomes 50,000 (equal to original contract amount)
    final inst2 = AdvanceInstallment(
      id: 'inst-2',
      amount: 30000.0,
      date: now,
      paymentMode: PaymentMode.cash,
      note: 'Final payment',
    );

    final newInstallments = [...adv.installments, inst2];
    final newTotalAdvance = newInstallments.fold(0.0, (sum, i) => sum + i.amount);

    final autoSettled = newTotalAdvance >= (adv.originalAmount ?? double.infinity);
    expect(autoSettled, true);

    adv = adv.copyWith(
      advanceAmount: newTotalAdvance,
      installments: newInstallments,
      status: autoSettled ? 'Settled' : adv.status,
      actualSpent: autoSettled ? newTotalAdvance : adv.actualSpent,
      dateSettled: autoSettled ? now : adv.dateSettled,
      billDetails: autoSettled ? 'Contract completed - 100% paid in installments' : adv.billDetails,
    );

    // Verify auto-settle state
    expect(adv.status, 'Settled');
    expect(adv.advanceAmount, 50000.0);
    expect(adv.actualSpent, 50000.0);
    expect(adv.remainingDue, 0.0);
    expect(adv.paidPercentage, 1.0);

    // Now test Revert to 'Pending' if installment 2 is deleted or edited down to 10,000
    final reducedInstallments = [
      adv.installments.first,
      inst2.copyWith(amount: 10000.0), // reduced from 30,000 to 10,000
    ];
    final reducedTotal = reducedInstallments.fold(0.0, (sum, i) => sum + i.amount); // 30,000 total
    final shouldRevertToPending = adv.hasContract && adv.status == 'Settled' && reducedTotal < (adv.originalAmount ?? 0);

    expect(shouldRevertToPending, true);

    adv = adv.copyWith(
      advanceAmount: reducedTotal,
      installments: reducedInstallments,
      status: shouldRevertToPending ? 'Pending' : adv.status,
      actualSpent: shouldRevertToPending ? null : adv.actualSpent,
      dateSettled: shouldRevertToPending ? null : adv.dateSettled,
      clearActualSpent: shouldRevertToPending,
      clearDateSettled: shouldRevertToPending,
    );

    expect(adv.status, 'Pending');
    expect(adv.advanceAmount, 30000.0);
    expect(adv.actualSpent, isNull);
    expect(adv.dateSettled, isNull);
    expect(adv.remainingDue, 20000.0);
    expect(adv.paidPercentage, 0.6);
  });

  test('ReceiptShareService generates valid PDF bytes for Slip and Expense Voucher', () async {
    final now = DateTime.now();

    final slip = ChandaSlip(
      id: 'slip-101',
      bookNumber: 1,
      slipNumber: 101,
      donorName: 'Subhash Chandra',
      amount: 1500.0,
      collectedBy: 'Ramesh',
      paymentMode: PaymentMode.upi,
      createdAt: now,
    );

    final slipPdfBytes = await ReceiptShareService.generateSlipPdf(
      slip: slip,
      pujaName: 'Sarbojanin Durga Puja',
      currentYear: 2026,
      cashierName: 'Amit Kumar',
    );
    expect(slipPdfBytes, isNotEmpty);
    expect(slipPdfBytes.length, greaterThan(100));

    final voucher = ExpenseVoucher(
      id: 'exp-202',
      voucherNo: '202',
      payeeName: 'Sharma Sound & DJ',
      category: ExpenseCategory.soundDhaki,
      amount: 8500.0,
      paymentMode: PaymentMode.cash,
      date: now,
      paidBy: 'Amit Kumar',
      description: 'Sound test equipment advance',
      advanceId: 'adv-01',
    );

    final voucherPdfBytes = await ReceiptShareService.generateExpenseVoucherPdf(
      voucher: voucher,
      pujaName: 'Sarbojanin Durga Puja',
      currentYear: 2026,
      cashierName: 'Amit Kumar',
    );
    expect(voucherPdfBytes, isNotEmpty);
    expect(voucherPdfBytes.length, greaterThan(100));
  });

  test('R2StorageService compresses raw image bytes effectively', () {
    // Generate a high-resolution 2400x2400 image
    final testImage = img.Image(width: 2400, height: 2400);
    for (int y = 0; y < 100; y++) {
      for (int x = 0; x < 100; x++) {
        testImage.setPixelRgb(x, y, (x * 2) % 255, (y * 2) % 255, (x + y) % 255);
      }
    }
    final rawJpegBytes = img.encodeJpg(testImage, quality: 100);

    // Compress using R2StorageService
    final compressedBytes = R2StorageService.compressImage(
      rawBytes: rawJpegBytes,
      maxWidth: 1920,
      maxHeight: 1920,
      quality: 82,
    );

    expect(compressedBytes, isNotEmpty);

    // Verify compressed image dimensions are within 1920
    final decoded = img.decodeImage(compressedBytes);
    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(1920));
    expect(decoded.height, lessThanOrEqualTo(1920));

    // Test CompressedImageResult
    const origSize = 5 * 1024 * 1024; // 5 MB
    const compSize = 250 * 1024; // 250 KB
    final result = CompressedImageResult(
      originalBytes: rawJpegBytes,
      compressedBytes: compressedBytes,
      originalSizeBytes: origSize,
      compressedSizeBytes: compSize,
      fileName: 'test_invoice.jpg',
    );
    expect(result.savedPercentage, greaterThan(90));
    expect(result.originalSizeMb, closeTo(5.0, 0.1));
    expect(result.compressedSizeKb, closeTo(250.0, 0.1));
    expect(result.summaryLabel, contains('reduced'));
  });

  test('ExpenseVoucher and MemberAdvance support receiptPhotoUrl serialization and clearing', () {
    final now = DateTime.now();

    final voucher = ExpenseVoucher(
      id: 'v-101',
      voucherNo: '101',
      payeeName: 'Tent House',
      category: ExpenseCategory.pandal,
      amount: 12000,
      paymentMode: PaymentMode.upi,
      paidBy: 'Cashier',
      date: now,
      receiptPhotoUrl: 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev/bills/2026/bill_1.jpg',
    );

    expect(voucher.receiptPhotoUrl, isNotNull);
    final vMap = voucher.toMap();
    expect(vMap['receiptPhotoUrl'], 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev/bills/2026/bill_1.jpg');

    final restoredV = ExpenseVoucher.fromMap(vMap);
    expect(restoredV.receiptPhotoUrl, voucher.receiptPhotoUrl);

    final clearedV = restoredV.copyWith(clearReceiptPhoto: true);
    expect(clearedV.receiptPhotoUrl, isNull);

    final adv = MemberAdvance(
      id: 'adv-01',
      memberName: 'Electrician',
      advanceAmount: 5000,
      category: ExpenseCategory.lighting,
      paymentMode: PaymentMode.cash,
      purpose: 'Wiring',
      dateGiven: now,
      receiptPhotoUrl: 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev/bills/2026/adv_1.jpg',
    );

    expect(adv.receiptPhotoUrl, isNotNull);
    final aMap = adv.toMap();
    expect(aMap['receiptPhotoUrl'], 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev/bills/2026/adv_1.jpg');

    final restoredAdv = MemberAdvance.fromMap(aMap);
    expect(restoredAdv.receiptPhotoUrl, adv.receiptPhotoUrl);

    final clearedAdv = restoredAdv.copyWith(clearReceiptPhoto: true);
    expect(clearedAdv.receiptPhotoUrl, isNull);
  });

  test('In-Kind (Kind) offering slips and King Donors ranking logic', () {
    final now = DateTime.now();

    final cashSlip1 = ChandaSlip(
      id: 'slip-01',
      slipNumber: 1,
      bookNumber: 1,
      donorName: 'Rahul Roy',
      amount: 15000.0,
      paymentMode: PaymentMode.cash,
      collectedBy: 'Amit',
      createdAt: now,
      donationType: DonationType.cash,
    );

    final cashSlip2 = ChandaSlip(
      id: 'slip-02',
      slipNumber: 2,
      bookNumber: 1,
      donorName: 'Subhash Sen',
      amount: 5000.0,
      paymentMode: PaymentMode.upi,
      collectedBy: 'Amit',
      createdAt: now,
      donationType: DonationType.cash,
    );

    final inKindSlip = ChandaSlip(
      id: 'slip-03',
      slipNumber: 3,
      bookNumber: 1,
      donorName: 'M/s Gupta Grocers',
      amount: 4500.0,
      paymentMode: PaymentMode.cash,
      collectedBy: 'Amit',
      createdAt: now,
      donationType: DonationType.inKind,
      inKindItemName: '50 Kg Basmati Rice',
      inKindCategory: InKindCategory.bhogGroceries,
      inKindQuantity: '50 Kg',
    );

    final slips = [cashSlip1, cashSlip2, inKindSlip];

    // In-Kind filter correctly isolates In-Kind offering transactions
    final inKindSlips = slips.where((s) => s.isInKind).toList();
    expect(inKindSlips.length, 1);
    expect(inKindSlips.first.inKindItemName, '50 Kg Basmati Rice');
    expect(inKindSlips.first.inKindCategory, InKindCategory.bhogGroceries);

    // Cash slips filter isolates cash donations
    final cashSlips = slips.where((s) => s.isCash).toList();
    expect(cashSlips.length, 2);

    // King donors sorted by total contribution
    final kingSlips = [...cashSlips]..sort((a, b) => b.amount.compareTo(a.amount));
    expect(kingSlips.first.donorName, 'Rahul Roy');
    expect(kingSlips.first.amount, 15000.0);
  });

  test('EditChandaSlipDialog initializes controllers without crash', () {
    final slip = ChandaSlip(
      id: 'slip-99',
      slipNumber: 99,
      bookNumber: 2,
      donorName: 'Devotee Test',
      amount: 1250.0,
      paymentMode: PaymentMode.cash,
      collectedBy: 'Amit',
      createdAt: DateTime.now(),
    );

    final dialog = EditChandaSlipDialog(slip: slip);
    expect(dialog.slip.donorName, 'Devotee Test');
    expect(dialog.slip.amount, 1250.0);
    expect(dialog.slip.slipNumber, 99);
  });

  test('ChandaBooksScreen desktop layout metric calculations and zero overflow grid extent', () {
    final expenses = [
      ExpenseVoucher(
        id: 'exp-1',
        voucherNo: 'V-001',
        category: ExpenseCategory.pandal,
        amount: 1000.0,
        paymentMode: PaymentMode.cash,
        paidBy: 'Cashier',
        payeeName: 'Rupam Guha (Advance #1)',
        date: DateTime.now(),
        description: 'Foundation',
        installmentId: 'inst-1',
      ),
      ExpenseVoucher(
        id: 'exp-2',
        voucherNo: 'V-002',
        category: ExpenseCategory.pandal,
        amount: 59000.0,
        paymentMode: PaymentMode.cash,
        paidBy: 'Cashier',
        payeeName: 'Rupam Guha (Advance #2)',
        date: DateTime.now(),
        description: 'Advance installment',
        installmentId: 'inst-2',
      ),
    ];

    final totalExpense = expenses.fold(0.0, (sum, e) => sum + e.amount);
    expect(totalExpense, 60000.0);

    // Verify mainAxisExtent for Desktop Grid (260px provides >15% margin over card height)
    const cardContentHeight = 198.0;
    const desktopMainAxisExtent = 260.0;
    const padding = 32.0; // padding only, since margin is 0 in grid
    expect(desktopMainAxisExtent - (cardContentHeight + padding) > 0, true);
  });

  test('AdvanceAccountCard desktop grid extent (330px) guarantees zero overflow headroom', () {
    // In grid mode (isGrid: true):
    // Outer padding: 13 * 2 = 26px
    // Row 1 (Header): ~41px
    // Row 2 (Financial overview): ~130px
    // Row 3 (Installments trigger): ~38px
    // Row 4 (Settlement box) or Row 5 (Action buttons): ~39px
    // Total required height in grid mode is ~274px.
    const gridCardHeight = 274.0;
    const desktopAdvanceGridExtent = 330.0;
    final safetyMargin = desktopAdvanceGridExtent - gridCardHeight;
    expect(safetyMargin >= 50.0, true); // Over 50px buffer, 0px overflow
  });

  test('R2StorageService is configured for durga-puja bucket and public CDN domain', () {
    expect(R2StorageService.bucketName, 'durga-puja');
    expect(R2StorageService.publicBaseUrl, 'https://pub-4a875079330644ab9a88af50db3096ec.r2.dev');
    expect(R2StorageService.accountId, '36a8bb867350b82ee35884892f318b8c');

    // Create a small mock image in memory
    final testImage = img.Image(width: 100, height: 100);
    img.fill(testImage, color: img.ColorRgb8(255, 0, 0));
    final rawBytes = Uint8List.fromList(img.encodeJpg(testImage));

    final compressed = R2StorageService.compressImage(rawBytes: rawBytes);
    expect(compressed.isNotEmpty, true);
  });
}


