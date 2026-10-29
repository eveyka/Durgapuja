import 'package:flutter/material.dart';

enum PaymentMode { cash, upi, bankTransfer }

extension PaymentModeExt on PaymentMode {
  String get name {
    switch (this) {
      case PaymentMode.cash:
        return 'cash';
      case PaymentMode.upi:
        return 'upi';
      case PaymentMode.bankTransfer:
        return 'bankTransfer';
    }
  }

  static PaymentMode fromString(String? val) {
    switch (val) {
      case 'upi':
        return PaymentMode.upi;
      case 'bankTransfer':
        return PaymentMode.bankTransfer;
      case 'cash':
      default:
        return PaymentMode.cash;
    }
  }
}

enum ExpenseCategory {
  murti,
  pandal,
  lighting,
  soundDhaki,
  pujaSamagri,
  bhogCatering,
  cultural,
  securityMisc
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get name => toString().split('.').last;

  static ExpenseCategory fromString(String? val) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.toString().split('.').last == val,
      orElse: () => ExpenseCategory.securityMisc,
    );
  }

  String get displayName {
    switch (this) {
      case ExpenseCategory.murti:
        return 'Idol & Pratima (Murti)';
      case ExpenseCategory.pandal:
        return 'Pandal & Decoration';
      case ExpenseCategory.lighting:
        return 'Lighting & Generator';
      case ExpenseCategory.soundDhaki:
        return 'Sound & Dhaki Drums';
      case ExpenseCategory.pujaSamagri:
        return 'Puja Rituals & Priest';
      case ExpenseCategory.bhogCatering:
        return 'Bhog & Community Feast';
      case ExpenseCategory.cultural:
        return 'Cultural Events & Programs';
      case ExpenseCategory.securityMisc:
        return 'Permissions & Miscellaneous';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.murti:
        return Icons.auto_awesome;
      case ExpenseCategory.pandal:
        return Icons.roofing;
      case ExpenseCategory.lighting:
        return Icons.tungsten;
      case ExpenseCategory.soundDhaki:
        return Icons.speaker_group;
      case ExpenseCategory.pujaSamagri:
        return Icons.local_florist;
      case ExpenseCategory.bhogCatering:
        return Icons.restaurant;
      case ExpenseCategory.cultural:
        return Icons.theater_comedy;
      case ExpenseCategory.securityMisc:
        return Icons.security;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.murti:
        return const Color(0xFFF59E0B);
      case ExpenseCategory.pandal:
        return const Color(0xFF38BDF8);
      case ExpenseCategory.lighting:
        return const Color(0xFFFBBF24);
      case ExpenseCategory.soundDhaki:
        return const Color(0xFFA855F7);
      case ExpenseCategory.pujaSamagri:
        return const Color(0xFFEC4899);
      case ExpenseCategory.bhogCatering:
        return const Color(0xFF10B981);
      case ExpenseCategory.cultural:
        return const Color(0xFF6366F1);
      case ExpenseCategory.securityMisc:
        return const Color(0xFF64748B);
    }
  }
}

class ChandaBook {
  final String id;
  final int bookNumber;
  final String assignedTo;
  final String? collectorPhone;
  final int startSlip;
  final int endSlip;
  final int totalSlips;
  final int usedSlips;
  final double totalCollected;
  final String status; // 'Active', 'Completed', 'Settled'

  ChandaBook({
    required this.id,
    required this.bookNumber,
    required this.assignedTo,
    this.collectorPhone,
    required this.startSlip,
    required this.endSlip,
    required this.totalSlips,
    this.usedSlips = 0,
    this.totalCollected = 0.0,
    this.status = 'Active',
  });

  ChandaBook copyWith({
    int? bookNumber,
    String? assignedTo,
    String? collectorPhone,
    int? startSlip,
    int? endSlip,
    int? totalSlips,
    int? usedSlips,
    double? totalCollected,
    String? status,
  }) {
    return ChandaBook(
      id: id,
      bookNumber: bookNumber ?? this.bookNumber,
      assignedTo: assignedTo ?? this.assignedTo,
      collectorPhone: collectorPhone ?? this.collectorPhone,
      startSlip: startSlip ?? this.startSlip,
      endSlip: endSlip ?? this.endSlip,
      totalSlips: totalSlips ?? this.totalSlips,
      usedSlips: usedSlips ?? this.usedSlips,
      totalCollected: totalCollected ?? this.totalCollected,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookNumber': bookNumber,
      'assignedTo': assignedTo,
      'collectorPhone': collectorPhone,
      'startSlip': startSlip,
      'endSlip': endSlip,
      'totalSlips': totalSlips,
      'usedSlips': usedSlips,
      'totalCollected': totalCollected,
      'status': status,
    };
  }

  factory ChandaBook.fromMap(Map<String, dynamic> map) {
    return ChandaBook(
      id: map['id'] ?? '',
      bookNumber: map['bookNumber'] ?? 1,
      assignedTo: map['assignedTo'] ?? '',
      collectorPhone: map['collectorPhone'],
      startSlip: map['startSlip'] ?? 1,
      endSlip: map['endSlip'] ?? 100,
      totalSlips: map['totalSlips'] ?? 100,
      usedSlips: map['usedSlips'] ?? 0,
      totalCollected: (map['totalCollected'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
    );
  }
}

class CollectionAccount {
  final String id;
  final String accountName;
  final String areaName;
  final String? collectorName;
  final String? collectorPhone;
  final double? targetAmount;
  final int? bookNumber;
  final int? startSlip;
  final int? endSlip;
  final String? eventId;
  final DateTime createdAt;
  final String status; // 'Active', 'Closed'
  final String? notes;

  CollectionAccount({
    required this.id,
    required this.accountName,
    required this.areaName,
    this.collectorName,
    this.collectorPhone,
    this.targetAmount,
    this.bookNumber,
    this.startSlip,
    this.endSlip,
    this.eventId,
    DateTime? createdAt,
    this.status = 'Active',
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalSlipsCount => (startSlip != null && endSlip != null && endSlip! >= startSlip!)
      ? (endSlip! - startSlip! + 1)
      : 0;

  String get bookSlipRangeText {
    if (bookNumber == null) return '';
    if (startSlip != null && endSlip != null) {
      return 'Book #$bookNumber (SL: $startSlip - $endSlip)';
    }
    return 'Book #$bookNumber';
  }

  CollectionAccount copyWith({
    String? accountName,
    String? areaName,
    String? collectorName,
    String? collectorPhone,
    double? targetAmount,
    int? bookNumber,
    int? startSlip,
    int? endSlip,
    String? eventId,
    DateTime? createdAt,
    String? status,
    String? notes,
    bool clearCollector = false,
  }) {
    return CollectionAccount(
      id: id,
      accountName: accountName ?? this.accountName,
      areaName: areaName ?? this.areaName,
      collectorName: clearCollector ? null : (collectorName ?? this.collectorName),
      collectorPhone: clearCollector ? null : (collectorPhone ?? this.collectorPhone),
      targetAmount: targetAmount ?? this.targetAmount,
      bookNumber: bookNumber ?? this.bookNumber,
      startSlip: startSlip ?? this.startSlip,
      endSlip: endSlip ?? this.endSlip,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountName': accountName,
      'areaName': areaName,
      'collectorName': collectorName,
      'collectorPhone': collectorPhone,
      'targetAmount': targetAmount,
      'bookNumber': bookNumber,
      'startSlip': startSlip,
      'endSlip': endSlip,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory CollectionAccount.fromMap(Map<String, dynamic> map) {
    return CollectionAccount(
      id: map['id'] ?? '',
      accountName: map['accountName'] ?? '',
      areaName: map['areaName'] ?? '',
      collectorName: map['collectorName'],
      collectorPhone: map['collectorPhone'],
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      bookNumber: (map['bookNumber'] as num?)?.toInt(),
      startSlip: (map['startSlip'] as num?)?.toInt(),
      endSlip: (map['endSlip'] as num?)?.toInt(),
      eventId: map['eventId'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Active',
      notes: map['notes'],
    );
  }
}

class ExpenditureAccount {
  final String id;
  final String accountName;
  final ExpenseCategory category;
  final String? inChargeName;
  final double? allocatedBudget;
  final String? eventId;
  final DateTime createdAt;
  final String status; // 'Active', 'Closed'
  final String? notes;

  ExpenditureAccount({
    required this.id,
    required this.accountName,
    required this.category,
    this.inChargeName,
    this.allocatedBudget,
    this.eventId,
    DateTime? createdAt,
    this.status = 'Active',
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  ExpenditureAccount copyWith({
    String? accountName,
    ExpenseCategory? category,
    String? inChargeName,
    double? allocatedBudget,
    String? eventId,
    DateTime? createdAt,
    String? status,
    String? notes,
  }) {
    return ExpenditureAccount(
      id: id,
      accountName: accountName ?? this.accountName,
      category: category ?? this.category,
      inChargeName: inChargeName ?? this.inChargeName,
      allocatedBudget: allocatedBudget ?? this.allocatedBudget,
      eventId: eventId ?? this.eventId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountName': accountName,
      'category': category.name,
      'inChargeName': inChargeName,
      'allocatedBudget': allocatedBudget,
      'eventId': eventId,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory ExpenditureAccount.fromMap(Map<String, dynamic> map) {
    return ExpenditureAccount(
      id: map['id'] ?? '',
      accountName: map['accountName'] ?? '',
      category: ExpenseCategoryExt.fromString(map['category']),
      inChargeName: map['inChargeName'],
      allocatedBudget: (map['allocatedBudget'] as num?)?.toDouble(),
      eventId: map['eventId'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Active',
      notes: map['notes'],
    );
  }
}

enum DonationStatus { paid, unpaid, partial }

extension DonationStatusExt on DonationStatus {
  String get name {
    switch (this) {
      case DonationStatus.paid:
        return 'paid';
      case DonationStatus.unpaid:
        return 'unpaid';
      case DonationStatus.partial:
        return 'partial';
    }
  }

  static DonationStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'unpaid':
        return DonationStatus.unpaid;
      case 'partial':
        return DonationStatus.partial;
      case 'paid':
      default:
        return DonationStatus.paid;
    }
  }

  String get displayName {
    switch (this) {
      case DonationStatus.paid:
        return 'Full Paid';
      case DonationStatus.unpaid:
        return 'Unpaid (Pending)';
      case DonationStatus.partial:
        return 'Partially Paid';
    }
  }

  Color get color {
    switch (this) {
      case DonationStatus.paid:
        return const Color(0xFF10B981);
      case DonationStatus.unpaid:
        return const Color(0xFFEF4444);
      case DonationStatus.partial:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case DonationStatus.paid:
        return Icons.check_circle_rounded;
      case DonationStatus.unpaid:
        return Icons.hourglass_top_rounded;
      case DonationStatus.partial:
        return Icons.pie_chart_rounded;
    }
  }
}

class PujaEvent {
  final String id;
  final String name; // e.g. "Durga Puja", "Lakshmi Puja", "Kali Puja", "Saraswati Puja"
  final int year;
  final double? targetBudget;
  final String status; // 'Active', 'Completed', 'Upcoming'
  final bool isSynced; // If true, included in Total Net Balance. If false, local to event only.
  final DateTime? syncedAt;
  final DateTime createdAt;

  PujaEvent({
    required this.id,
    required this.name,
    required this.year,
    this.targetBudget,
    this.status = 'Active',
    this.isSynced = false,
    this.syncedAt,
    required this.createdAt,
  });

  String get title => '$name $year';

  PujaEvent copyWith({
    String? name,
    int? year,
    double? targetBudget,
    String? status,
    bool? isSynced,
    DateTime? syncedAt,
  }) {
    return PujaEvent(
      id: id,
      name: name ?? this.name,
      year: year ?? this.year,
      targetBudget: targetBudget ?? this.targetBudget,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      syncedAt: syncedAt ?? this.syncedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'targetBudget': targetBudget,
      'status': status,
      'isSynced': isSynced,
      'syncedAt': syncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PujaEvent.fromMap(Map<String, dynamic> map) {
    return PujaEvent(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Durga Puja',
      year: (map['year'] as num?)?.toInt() ?? 2026,
      targetBudget: (map['targetBudget'] as num?)?.toDouble(),
      status: map['status'] ?? 'Active',
      isSynced: map['isSynced'] == true,
      syncedAt: map['syncedAt'] != null ? DateTime.tryParse(map['syncedAt']) : null,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

enum DonationType { cash, inKind }

extension DonationTypeExt on DonationType {
  String get name => toString().split('.').last;

  static DonationType fromString(String? val) {
    if (val == 'inKind') return DonationType.inKind;
    return DonationType.cash;
  }

  String get displayName {
    switch (this) {
      case DonationType.cash:
        return 'Cash / Online';
      case DonationType.inKind:
        return 'In-Kind / Samagri';
    }
  }

  IconData get icon {
    switch (this) {
      case DonationType.cash:
        return Icons.payments_rounded;
      case DonationType.inKind:
        return Icons.inventory_2_rounded;
    }
  }
}

class SlipPayment {
  final String id;
  final double amount;
  final DateTime date;
  final PaymentMode paymentMode;
  final String collectedBy;
  final String? note;

  SlipPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.paymentMode = PaymentMode.cash,
    this.collectedBy = '',
    this.note,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'paymentMode': paymentMode.name,
    'collectedBy': collectedBy,
    'note': note,
  };

  factory SlipPayment.fromMap(Map<String, dynamic> map) {
    return SlipPayment(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      paymentMode: PaymentModeExt.fromString(map['paymentMode']),
      collectedBy: map['collectedBy'] ?? '',
      note: map['note'],
    );
  }

  SlipPayment copyWith({
    String? id,
    double? amount,
    DateTime? date,
    PaymentMode? paymentMode,
    String? collectedBy,
    String? note,
  }) {
    return SlipPayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      collectedBy: collectedBy ?? this.collectedBy,
      note: note ?? this.note,
    );
  }
}

class ChandaSlip {
  final String id;
  final int slipNumber;
  final int bookNumber;
  final String donorName;
  final String? phone;
  final String? address;
  final double amount;
  final double paidAmount;
  final DonationStatus status;
  final PaymentMode paymentMode;
  final String collectedBy;
  final DateTime createdAt;
  final DateTime? paymentDate;
  final String? notes;
  final String? dayLabel; // e.g. 'Day 1', 'Day 2', 'Maha Saptami'
  final int slipsCount;   // Number of slips represented by this entry (default 1)
  final String? eventId;
  final String? accountId;
  final String? accountName;
  final DonationType donationType;
  final String? inKindItemName;
  final InKindCategory? inKindCategory;
  final String? inKindQuantity;
  final String? slipPhotoUrl;
  final List<SlipPayment> payments;

  ChandaSlip({
    required this.id,
    required this.slipNumber,
    this.bookNumber = 1,
    this.accountId,
    this.accountName,
    required this.donorName,
    this.phone,
    this.address,
    required this.amount,
    double? paidAmount,
    this.status = DonationStatus.paid,
    required this.paymentMode,
    required this.collectedBy,
    required this.createdAt,
    this.paymentDate,
    this.notes,
    this.dayLabel,
    this.slipsCount = 1,
    this.eventId,
    this.donationType = DonationType.cash,
    this.inKindItemName,
    this.inKindCategory,
    this.inKindQuantity,
    this.slipPhotoUrl,
    List<SlipPayment>? payments,
  }) : paidAmount = paidAmount ?? (status == DonationStatus.unpaid ? 0.0 : amount),
       payments = payments != null && payments.isNotEmpty
           ? payments
           : ((paidAmount ?? (status == DonationStatus.unpaid ? 0.0 : amount)) > 0
               ? [
                   SlipPayment(
                     id: '${id}_init',
                     amount: paidAmount ?? (status == DonationStatus.unpaid ? 0.0 : amount),
                     date: paymentDate ?? createdAt,
                     paymentMode: paymentMode,
                     collectedBy: collectedBy,
                     note: 'Initial Chanda Payment',
                   ),
                 ]
               : const []);

  bool get isCash => donationType == DonationType.cash;
  bool get isInKind => donationType == DonationType.inKind;

  double get pendingAmount => (amount - paidAmount) > 0 ? (amount - paidAmount) : 0.0;
  bool get isFullyPaid => status == DonationStatus.paid || paidAmount >= amount;
  bool get isUnpaid => status == DonationStatus.unpaid || paidAmount <= 0.0;
  bool get isPartial => status == DonationStatus.partial || (paidAmount > 0.0 && paidAmount < amount);

  ChandaSlip copyWith({
    int? slipNumber,
    int? bookNumber,
    String? accountId,
    String? accountName,
    String? donorName,
    String? phone,
    String? address,
    double? amount,
    double? paidAmount,
    DonationStatus? status,
    PaymentMode? paymentMode,
    String? collectedBy,
    DateTime? createdAt,
    DateTime? paymentDate,
    String? notes,
    String? dayLabel,
    int? slipsCount,
    String? eventId,
    DonationType? donationType,
    String? inKindItemName,
    InKindCategory? inKindCategory,
    String? inKindQuantity,
    String? slipPhotoUrl,
    bool clearSlipPhoto = false,
    List<SlipPayment>? payments,
  }) {
    return ChandaSlip(
      id: id,
      slipNumber: slipNumber ?? this.slipNumber,
      bookNumber: bookNumber ?? this.bookNumber,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      donorName: donorName ?? this.donorName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      collectedBy: collectedBy ?? this.collectedBy,
      createdAt: createdAt ?? this.createdAt,
      paymentDate: paymentDate ?? this.paymentDate,
      notes: notes ?? this.notes,
      dayLabel: dayLabel ?? this.dayLabel,
      slipsCount: slipsCount ?? this.slipsCount,
      eventId: eventId ?? this.eventId,
      donationType: donationType ?? this.donationType,
      inKindItemName: inKindItemName ?? this.inKindItemName,
      inKindCategory: inKindCategory ?? this.inKindCategory,
      inKindQuantity: inKindQuantity ?? this.inKindQuantity,
      slipPhotoUrl: clearSlipPhoto ? null : (slipPhotoUrl ?? this.slipPhotoUrl),
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slipNumber': slipNumber,
      'bookNumber': bookNumber,
      'accountId': accountId,
      'accountName': accountName,
      'donorName': donorName,
      'phone': phone,
      'address': address,
      'amount': amount,
      'paidAmount': paidAmount,
      'status': status.name,
      'paymentMode': paymentMode.name,
      'collectedBy': collectedBy,
      'createdAt': createdAt.toIso8601String(),
      'paymentDate': paymentDate?.toIso8601String(),
      'notes': notes,
      'dayLabel': dayLabel,
      'slipsCount': slipsCount,
      'eventId': eventId,
      'donationType': donationType.name,
      'inKindItemName': inKindItemName,
      'inKindCategory': inKindCategory?.name,
      'inKindQuantity': inKindQuantity,
      'slipPhotoUrl': slipPhotoUrl,
      'payments': payments.map((p) => p.toMap()).toList(),
    };
  }

  factory ChandaSlip.fromMap(Map<String, dynamic> map) {
    final amt = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final status = DonationStatusExt.fromString(map['status']);
    final pAmt = map['paidAmount'] != null
        ? (map['paidAmount'] as num).toDouble()
        : (status == DonationStatus.unpaid ? 0.0 : amt);

    return ChandaSlip(
      id: map['id'] ?? '',
      slipNumber: map['slipNumber'] ?? 1,
      bookNumber: map['bookNumber'] ?? 1,
      accountId: map['accountId'],
      accountName: map['accountName'],
      donorName: map['donorName'] ?? '',
      phone: map['phone'],
      address: map['address'],
      amount: amt,
      paidAmount: pAmt,
      status: status,
      paymentMode: PaymentModeExt.fromString(map['paymentMode']),
      collectedBy: map['collectedBy'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      paymentDate: map['paymentDate'] != null ? DateTime.tryParse(map['paymentDate']) : null,
      notes: map['notes'],
      dayLabel: map['dayLabel'],
      slipsCount: map['slipsCount'] ?? 1,
      eventId: map['eventId'],
      donationType: DonationTypeExt.fromString(map['donationType']),
      inKindItemName: map['inKindItemName'],
      inKindCategory: map['inKindCategory'] != null ? InKindCategoryExt.fromString(map['inKindCategory']) : null,
      inKindQuantity: map['inKindQuantity'],
      slipPhotoUrl: map['slipPhotoUrl'] ?? map['receiptPhotoUrl'],
      payments: map['payments'] != null
          ? (map['payments'] as List)
              .map((p) => SlipPayment.fromMap(Map<String, dynamic>.from(p)))
              .toList()
          : null,
    );
  }
}

class ExpenseVoucher {
  final String id;
  final String voucherNo;
  final String payeeName;
  final ExpenseCategory category;
  final double amount;
  final PaymentMode paymentMode;
  final String paidBy;
  final DateTime date;
  final String? receiptPhotoUrl;
  final String? description;
  final String? eventId;
  final String? accountId;
  final String? accountName;
  final String? advanceId;
  final String? installmentId;

  ExpenseVoucher({
    required this.id,
    required this.voucherNo,
    required this.payeeName,
    required this.category,
    required this.amount,
    required this.paymentMode,
    required this.paidBy,
    required this.date,
    this.receiptPhotoUrl,
    this.description,
    this.eventId,
    this.accountId,
    this.accountName,
    this.advanceId,
    this.installmentId,
  });

  bool get isAdvance => advanceId != null;

  ExpenseVoucher copyWith({
    String? voucherNo,
    String? payeeName,
    ExpenseCategory? category,
    double? amount,
    PaymentMode? paymentMode,
    String? paidBy,
    DateTime? date,
    String? receiptPhotoUrl,
    String? description,
    String? eventId,
    String? accountId,
    String? accountName,
    String? advanceId,
    String? installmentId,
    bool clearReceiptPhoto = false,
  }) {
    return ExpenseVoucher(
      id: id,
      voucherNo: voucherNo ?? this.voucherNo,
      payeeName: payeeName ?? this.payeeName,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      receiptPhotoUrl: clearReceiptPhoto ? null : (receiptPhotoUrl ?? this.receiptPhotoUrl),
      description: description ?? this.description,
      eventId: eventId ?? this.eventId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      advanceId: advanceId ?? this.advanceId,
      installmentId: installmentId ?? this.installmentId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherNo': voucherNo,
      'payeeName': payeeName,
      'category': category.name,
      'amount': amount,
      'paymentMode': paymentMode.name,
      'paidBy': paidBy,
      'date': date.toIso8601String(),
      'receiptPhotoUrl': receiptPhotoUrl,
      'description': description,
      'eventId': eventId,
      'accountId': accountId,
      'accountName': accountName,
      'advanceId': advanceId,
      'installmentId': installmentId,
    };
  }

  factory ExpenseVoucher.fromMap(Map<String, dynamic> map) {
    return ExpenseVoucher(
      id: map['id'] ?? '',
      voucherNo: map['voucherNo'] ?? '',
      payeeName: map['payeeName'] ?? '',
      category: ExpenseCategoryExt.fromString(map['category']),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: PaymentModeExt.fromString(map['paymentMode']),
      paidBy: map['paidBy'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      receiptPhotoUrl: map['receiptPhotoUrl'],
      description: map['description'],
      eventId: map['eventId'],
      accountId: map['accountId'],
      accountName: map['accountName'],
      advanceId: map['advanceId'],
      installmentId: map['installmentId'],
    );
  }
}

class DailyCashflow {
  final String dayName;
  final double income;
  final double expense;

  DailyCashflow({
    required this.dayName,
    required this.income,
    required this.expense,
  });
}

class DonorSummary {
  final String name;
  final double totalDonated;
  final int donationCount;
  final DateTime lastDonation;
  final List<ChandaSlip> slips;

  DonorSummary({
    required this.name,
    required this.totalDonated,
    required this.donationCount,
    required this.lastDonation,
    required this.slips,
  });
}

class AdvanceInstallment {
  final String id;
  final double amount;
  final DateTime date;
  final PaymentMode paymentMode;
  final String note;
  final String? recordedBy;

  AdvanceInstallment({
    required this.id,
    required this.amount,
    required this.date,
    this.paymentMode = PaymentMode.cash,
    this.note = '',
    this.recordedBy,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'paymentMode': paymentMode.name,
    'note': note,
    'recordedBy': recordedBy,
  };

  factory AdvanceInstallment.fromMap(Map<String, dynamic> map) {
    return AdvanceInstallment(
      id: map['id'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      paymentMode: PaymentModeExt.fromString(map['paymentMode']),
      note: map['note'] ?? '',
      recordedBy: map['recordedBy'],
    );
  }
  AdvanceInstallment copyWith({
    String? id,
    double? amount,
    DateTime? date,
    PaymentMode? paymentMode,
    String? note,
    String? recordedBy,
  }) {
    return AdvanceInstallment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      note: note ?? this.note,
      recordedBy: recordedBy ?? this.recordedBy,
    );
  }
}

class MemberAdvance {
  final String id;
  final String memberName;
  final double advanceAmount;
  final double? originalAmount; // Original contract / agreed total deal amount
  final ExpenseCategory category;
  final PaymentMode paymentMode;
  final String purpose;
  final DateTime dateGiven;
  final String status; // 'Pending', 'Settled'
  final double? actualSpent;
  final double? returnAmount; // Cash refunded back to cashier
  final double? extraClaimAmount; // Extra paid out to member
  final DateTime? dateSettled;
  final String? billDetails;
  final String? receiptPhotoUrl;
  final String? eventId;
  final List<AdvanceInstallment> installments;

  MemberAdvance({
    required this.id,
    required this.memberName,
    required this.advanceAmount,
    this.originalAmount,
    required this.category,
    required this.paymentMode,
    required this.purpose,
    required this.dateGiven,
    this.status = 'Pending',
    this.actualSpent,
    this.returnAmount,
    this.extraClaimAmount,
    this.dateSettled,
    this.billDetails,
    this.receiptPhotoUrl,
    this.eventId,
    List<AdvanceInstallment>? installments,
  }) : installments = installments != null && installments.isNotEmpty
            ? installments
            : (advanceAmount > 0
                ? [
                    AdvanceInstallment(
                      id: id,
                      amount: advanceAmount,
                      date: dateGiven,
                      paymentMode: paymentMode,
                      note: purpose.isNotEmpty ? purpose : 'Initial Advance',
                    )
                  ]
                : const []);

  double get effectiveOriginalAmount =>
      (originalAmount != null && originalAmount! > 0) ? originalAmount! : advanceAmount;

  double get remainingDue {
    if (status == 'Settled') return 0.0;
    final diff = effectiveOriginalAmount - advanceAmount;
    return diff > 0 ? diff : 0.0;
  }

  double get paidPercentage {
    if (status == 'Settled') return 1.0;
    if (effectiveOriginalAmount <= 0) return 1.0;
    return (advanceAmount / effectiveOriginalAmount).clamp(0.0, 1.0);
  }

  bool get hasContract => originalAmount != null && originalAmount! > 0;

  MemberAdvance copyWith({
    String? memberName,
    double? advanceAmount,
    double? originalAmount,
    ExpenseCategory? category,
    PaymentMode? paymentMode,
    String? purpose,
    DateTime? dateGiven,
    String? status,
    double? actualSpent,
    double? returnAmount,
    double? extraClaimAmount,
    DateTime? dateSettled,
    String? billDetails,
    String? receiptPhotoUrl,
    String? eventId,
    List<AdvanceInstallment>? installments,
    bool clearActualSpent = false,
    bool clearDateSettled = false,
    bool clearReceiptPhoto = false,
  }) {
    return MemberAdvance(
      id: id,
      memberName: memberName ?? this.memberName,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      originalAmount: originalAmount ?? this.originalAmount,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      purpose: purpose ?? this.purpose,
      dateGiven: dateGiven ?? this.dateGiven,
      status: status ?? this.status,
      actualSpent: clearActualSpent ? null : (actualSpent ?? this.actualSpent),
      returnAmount: returnAmount ?? this.returnAmount,
      extraClaimAmount: extraClaimAmount ?? this.extraClaimAmount,
      dateSettled: clearDateSettled ? null : (dateSettled ?? this.dateSettled),
      billDetails: billDetails ?? this.billDetails,
      receiptPhotoUrl: clearReceiptPhoto ? null : (receiptPhotoUrl ?? this.receiptPhotoUrl),
      eventId: eventId ?? this.eventId,
      installments: installments ?? this.installments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'memberName': memberName,
      'advanceAmount': advanceAmount,
      'originalAmount': originalAmount,
      'category': category.name,
      'paymentMode': paymentMode.name,
      'purpose': purpose,
      'dateGiven': dateGiven.toIso8601String(),
      'status': status,
      'actualSpent': actualSpent,
      'returnAmount': returnAmount,
      'extraClaimAmount': extraClaimAmount,
      'dateSettled': dateSettled?.toIso8601String(),
      'billDetails': billDetails,
      'receiptPhotoUrl': receiptPhotoUrl,
      'eventId': eventId,
      'installments': installments.map((i) => i.toMap()).toList(),
    };
  }

  factory MemberAdvance.fromMap(Map<String, dynamic> map) {
    final advAmt = (map['advanceAmount'] as num?)?.toDouble() ?? 0.0;
    final parsedInstallments = (map['installments'] as List<dynamic>?)
        ?.map((item) => AdvanceInstallment.fromMap(item as Map<String, dynamic>))
        .toList();

    return MemberAdvance(
      id: map['id'] ?? '',
      memberName: map['memberName'] ?? '',
      advanceAmount: advAmt,
      originalAmount: (map['originalAmount'] as num?)?.toDouble(),
      category: ExpenseCategoryExt.fromString(map['category']),
      paymentMode: PaymentModeExt.fromString(map['paymentMode']),
      purpose: map['purpose'] ?? '',
      dateGiven: DateTime.tryParse(map['dateGiven'] ?? '') ?? DateTime.now(),
      status: map['status'] ?? 'Pending',
      actualSpent: (map['actualSpent'] as num?)?.toDouble(),
      returnAmount: (map['returnAmount'] as num?)?.toDouble(),
      extraClaimAmount: (map['extraClaimAmount'] as num?)?.toDouble(),
      dateSettled: map['dateSettled'] != null ? DateTime.tryParse(map['dateSettled']) : null,
      billDetails: map['billDetails'],
      receiptPhotoUrl: map['receiptPhotoUrl'],
      eventId: map['eventId'],
      installments: parsedInstallments,
    );
  }
}

enum InKindCategory {
  bhogGroceries,
  pujaSamagri,
  murtiDressOrnaments,
  decorLighting,
  other,
}

extension InKindCategoryExt on InKindCategory {
  String get name => toString().split('.').last;

  static InKindCategory fromString(String? val) {
    return InKindCategory.values.firstWhere(
      (e) => e.toString().split('.').last == val,
      orElse: () => InKindCategory.other,
    );
  }

  String get displayName {
    switch (this) {
      case InKindCategory.bhogGroceries:
        return 'Bhog & Groceries (Rice, Oil, Ghee, Sweets)';
      case InKindCategory.pujaSamagri:
        return 'Puja Rituals & Flowers (Lotus, Incense, Thali)';
      case InKindCategory.murtiDressOrnaments:
        return 'Idol Attire & Ornaments (Saree, Mukut, Jewelry)';
      case InKindCategory.decorLighting:
        return 'Pandal, Sound & Fuel (Diesel, Lighting)';
      case InKindCategory.other:
        return 'Other Goods & Supplies';
    }
  }

  IconData get icon {
    switch (this) {
      case InKindCategory.bhogGroceries:
        return Icons.restaurant_menu;
      case InKindCategory.pujaSamagri:
        return Icons.local_florist;
      case InKindCategory.murtiDressOrnaments:
        return Icons.checkroom;
      case InKindCategory.decorLighting:
        return Icons.tungsten;
      case InKindCategory.other:
        return Icons.inventory_2;
    }
  }

  Color get color {
    switch (this) {
      case InKindCategory.bhogGroceries:
        return const Color(0xFF10B981);
      case InKindCategory.pujaSamagri:
        return const Color(0xFFEC4899);
      case InKindCategory.murtiDressOrnaments:
        return const Color(0xFFF59E0B);
      case InKindCategory.decorLighting:
        return const Color(0xFF38BDF8);
      case InKindCategory.other:
        return const Color(0xFFA855F7);
    }
  }
}

class InKindDonation {
  final String id;
  final String donorName;
  final String? phone;
  final String itemName;
  final InKindCategory category;
  final String quantity;
  final double? estimatedValue;
  final String receivedBy;
  final DateTime date;
  final String? notes;

  InKindDonation({
    required this.id,
    required this.donorName,
    this.phone,
    required this.itemName,
    required this.category,
    required this.quantity,
    this.estimatedValue,
    required this.receivedBy,
    required this.date,
    this.notes,
  });

  InKindDonation copyWith({
    String? donorName,
    String? phone,
    String? itemName,
    InKindCategory? category,
    String? quantity,
    double? estimatedValue,
    String? receivedBy,
    DateTime? date,
    String? notes,
  }) {
    return InKindDonation(
      id: id,
      donorName: donorName ?? this.donorName,
      phone: phone ?? this.phone,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      receivedBy: receivedBy ?? this.receivedBy,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'donorName': donorName,
      'phone': phone,
      'itemName': itemName,
      'category': category.name,
      'quantity': quantity,
      'estimatedValue': estimatedValue,
      'receivedBy': receivedBy,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory InKindDonation.fromMap(Map<String, dynamic> map) {
    return InKindDonation(
      id: map['id'] ?? '',
      donorName: map['donorName'] ?? '',
      phone: map['phone'],
      itemName: map['itemName'] ?? '',
      category: InKindCategoryExt.fromString(map['category']),
      quantity: map['quantity'] ?? '',
      estimatedValue: (map['estimatedValue'] as num?)?.toDouble(),
      receivedBy: map['receivedBy'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'],
    );
  }
}

enum ActivityActionType {
  create,
  update,
  delete,
  settle,
  payment,
}

extension ActivityActionTypeExt on ActivityActionType {
  String get name => toString().split('.').last;

  static ActivityActionType fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'update':
        return ActivityActionType.update;
      case 'delete':
        return ActivityActionType.delete;
      case 'settle':
        return ActivityActionType.settle;
      case 'payment':
        return ActivityActionType.payment;
      case 'create':
      default:
        return ActivityActionType.create;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityActionType.create:
        return 'Created';
      case ActivityActionType.update:
        return 'Updated';
      case ActivityActionType.delete:
        return 'Deleted';
      case ActivityActionType.settle:
        return 'Settled';
      case ActivityActionType.payment:
        return 'Payment';
    }
  }

  Color get color {
    switch (this) {
      case ActivityActionType.create:
        return const Color(0xFF10B981);
      case ActivityActionType.update:
        return const Color(0xFF38BDF8);
      case ActivityActionType.delete:
        return const Color(0xFFEF4444);
      case ActivityActionType.settle:
        return const Color(0xFFA855F7);
      case ActivityActionType.payment:
        return const Color(0xFFF59E0B);
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityActionType.create:
        return Icons.add_circle_outline_rounded;
      case ActivityActionType.update:
        return Icons.edit_note_rounded;
      case ActivityActionType.delete:
        return Icons.delete_outline_rounded;
      case ActivityActionType.settle:
        return Icons.task_alt_rounded;
      case ActivityActionType.payment:
        return Icons.payments_rounded;
    }
  }
}

enum ActivityModule {
  account,
  collection,
  due,
  expense,
  advance,
  event,
  inKind,
  book,
  settings,
}

extension ActivityModuleExt on ActivityModule {
  String get name => toString().split('.').last;

  static ActivityModule fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'collection':
        return ActivityModule.collection;
      case 'due':
        return ActivityModule.due;
      case 'expense':
        return ActivityModule.expense;
      case 'advance':
        return ActivityModule.advance;
      case 'event':
        return ActivityModule.event;
      case 'inkind':
        return ActivityModule.inKind;
      case 'book':
        return ActivityModule.book;
      case 'settings':
        return ActivityModule.settings;
      case 'account':
      default:
        return ActivityModule.account;
    }
  }

  String get displayName {
    switch (this) {
      case ActivityModule.account:
        return 'Account';
      case ActivityModule.collection:
        return 'Collection (Chanda)';
      case ActivityModule.due:
        return 'Due / Pending';
      case ActivityModule.expense:
        return 'Expense Voucher';
      case ActivityModule.advance:
        return 'Advance / Khata';
      case ActivityModule.event:
        return 'Festival Event';
      case ActivityModule.inKind:
        return 'Samagri (In-Kind)';
      case ActivityModule.book:
        return 'Chanda Book';
      case ActivityModule.settings:
        return 'Committee Settings';
    }
  }

  Color get color {
    switch (this) {
      case ActivityModule.account:
        return const Color(0xFF3B82F6);
      case ActivityModule.collection:
        return const Color(0xFF10B981);
      case ActivityModule.due:
        return const Color(0xFFF59E0B);
      case ActivityModule.expense:
        return const Color(0xFFF43F5E);
      case ActivityModule.advance:
        return const Color(0xFFA855F7);
      case ActivityModule.event:
        return const Color(0xFF06B6D4);
      case ActivityModule.inKind:
        return const Color(0xFF14B8A6);
      case ActivityModule.book:
        return const Color(0xFFEC4899);
      case ActivityModule.settings:
        return const Color(0xFF64748B);
    }
  }

  IconData get icon {
    switch (this) {
      case ActivityModule.account:
        return Icons.account_balance_rounded;
      case ActivityModule.collection:
        return Icons.receipt_long_rounded;
      case ActivityModule.due:
        return Icons.pending_actions_rounded;
      case ActivityModule.expense:
        return Icons.receipt_rounded;
      case ActivityModule.advance:
        return Icons.handshake_rounded;
      case ActivityModule.event:
        return Icons.festival_rounded;
      case ActivityModule.inKind:
        return Icons.inventory_2_rounded;
      case ActivityModule.book:
        return Icons.menu_book_rounded;
      case ActivityModule.settings:
        return Icons.settings_suggest_rounded;
    }
  }
}

class AuditActivityLog {
  final String id;
  final String title;
  final String description;
  final ActivityActionType actionType;
  final ActivityModule module;
  final double? amount;
  final String performedBy;
  final DateTime timestamp;
  final String? eventId;
  final String? eventName;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  AuditActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.actionType,
    required this.module,
    this.amount,
    required this.performedBy,
    required this.timestamp,
    this.eventId,
    this.eventName,
    this.referenceId,
    this.metadata,
  });

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year}';
    }
  }

  String get formattedDate {
    final h = timestamp.hour % 12 == 0 ? 12 : timestamp.hour % 12;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final ampm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}, $h:$m $ampm';
  }

  Color get color => module.color;
  IconData get icon => module.icon;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'actionType': actionType.name,
      'module': module.name,
      'amount': amount,
      'performedBy': performedBy,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
      'eventName': eventName,
      'referenceId': referenceId,
      'metadata': metadata,
    };
  }

  factory AuditActivityLog.fromMap(Map<String, dynamic> map) {
    return AuditActivityLog(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      actionType: ActivityActionTypeExt.fromString(map['actionType']),
      module: ActivityModuleExt.fromString(map['module']),
      amount: (map['amount'] as num?)?.toDouble(),
      performedBy: map['performedBy'] ?? 'Cashier',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      eventId: map['eventId'],
      eventName: map['eventName'],
      referenceId: map['referenceId'],
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  AuditActivityLog copyWith({
    String? id,
    String? title,
    String? description,
    ActivityActionType? actionType,
    ActivityModule? module,
    double? amount,
    String? performedBy,
    DateTime? timestamp,
    String? eventId,
    String? eventName,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) {
    return AuditActivityLog(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      actionType: actionType ?? this.actionType,
      module: module ?? this.module,
      amount: amount ?? this.amount,
      performedBy: performedBy ?? this.performedBy,
      timestamp: timestamp ?? this.timestamp,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
    );
  }
}


