import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String colSettings = 'puja_settings';
  static const String colEvents = 'puja_events';
  static const String colBooks = 'chanda_books';
  static const String colSlips = 'chanda_slips';
  static const String colCollectionAccounts = 'collection_accounts';
  static const String colExpenditureAccounts = 'expenditure_accounts';
  static const String colExpenses = 'expenses';
  static const String colAdvances = 'member_advances';
  static const String colInKind = 'in_kind_donations';
  static const String colActivityLogs = 'activity_logs';

  // ==========================================
  // REAL-TIME STREAMS
  // ==========================================

  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamSettings() {
    return _db.collection(colSettings).doc('main_profile').snapshots();
  }

  static Stream<List<PujaEvent>> streamEvents() {
    return _db.collection(colEvents).orderBy('year', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => PujaEvent.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<ChandaBook>> streamBooks() {
    return _db.collection(colBooks).orderBy('bookNumber').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChandaBook.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<ChandaSlip>> streamSlips() {
    return _db.collection(colSlips).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChandaSlip.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<CollectionAccount>> streamCollectionAccounts() {
    return _db.collection(colCollectionAccounts).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CollectionAccount.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<ExpenditureAccount>> streamExpenditureAccounts() {
    return _db.collection(colExpenditureAccounts).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExpenditureAccount.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<ExpenseVoucher>> streamExpenses() {
    return _db.collection(colExpenses).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseVoucher.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<MemberAdvance>> streamAdvances() {
    return _db.collection(colAdvances).orderBy('dateGiven', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MemberAdvance.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<InKindDonation>> streamInKindDonations() {
    return _db.collection(colInKind).orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => InKindDonation.fromMap(doc.data())).toList();
    });
  }

  static Stream<List<AuditActivityLog>> streamActivityLogs({int limit = 300}) {
    return _db
        .collection(colActivityLogs)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => AuditActivityLog.fromMap(doc.data())).toList();
    });
  }

  // ==========================================
  // WRITE & UPDATE OPERATIONS
  // ==========================================

  static Future<void> saveSettings({
    required String pujaName,
    required String cashierName,
    required int currentYear,
    required String presidentName,
    required String secretaryName,
    Map<ExpenseCategory, double> budgets = const {},
  }) async {
    await _db.collection(colSettings).doc('main_profile').set({
      'pujaName': pujaName,
      'cashierName': cashierName,
      'currentYear': currentYear,
      'presidentName': presidentName,
      'secretaryName': secretaryName,
      'budgets': {
        for (final entry in budgets.entries) entry.key.name: entry.value,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveEvent(PujaEvent event) async {
    await _db.collection(colEvents).doc(event.id).set(event.toMap());
  }

  static Future<void> deleteEvent(String id) async {
    await _db.collection(colEvents).doc(id).delete();
  }

  static Future<void> saveBook(ChandaBook book) async {
    await _db.collection(colBooks).doc(book.id).set(book.toMap());
  }

  static Future<void> saveSlipOnly(ChandaSlip slip) async {
    await _db.collection(colSlips).doc(slip.id).set(slip.toMap());
  }

  static Future<void> saveSlip(ChandaSlip slip, [ChandaBook? updatedBook]) async {
    if (updatedBook == null) {
      await saveSlipOnly(slip);
      return;
    }
    final batch = _db.batch();
    final slipRef = _db.collection(colSlips).doc(slip.id);
    final bookRef = _db.collection(colBooks).doc(updatedBook.id);

    batch.set(slipRef, slip.toMap());
    batch.set(bookRef, updatedBook.toMap());

    await batch.commit();
  }

  static Future<void> saveExpense(ExpenseVoucher expense) async {
    await _db.collection(colExpenses).doc(expense.id).set(expense.toMap());
  }

  static Future<void> saveCollectionAccount(CollectionAccount account) async {
    await _db.collection(colCollectionAccounts).doc(account.id).set(account.toMap());
  }

  static Future<void> deleteCollectionAccount(String id) async {
    await _db.collection(colCollectionAccounts).doc(id).delete();
  }

  static Future<void> deleteCollectionAccountCascade(String id, List<String> slipIds) async {
    final batch = _db.batch();
    batch.delete(_db.collection(colCollectionAccounts).doc(id));
    for (final sId in slipIds) {
      batch.delete(_db.collection(colSlips).doc(sId));
    }
    await batch.commit();
  }

  static Future<void> saveExpenditureAccount(ExpenditureAccount account) async {
    await _db.collection(colExpenditureAccounts).doc(account.id).set(account.toMap());
  }

  static Future<void> deleteExpenditureAccount(String id) async {
    await _db.collection(colExpenditureAccounts).doc(id).delete();
  }

  static Future<void> deleteExpenditureAccountCascade(String id, List<String> expenseIds) async {
    final batch = _db.batch();
    batch.delete(_db.collection(colExpenditureAccounts).doc(id));
    for (final eId in expenseIds) {
      batch.delete(_db.collection(colExpenses).doc(eId));
    }
    await batch.commit();
  }

  static Future<void> saveAdvance(MemberAdvance advance) async {
    await _db.collection(colAdvances).doc(advance.id).set(advance.toMap());
  }

  static Future<void> saveInKindDonation(InKindDonation donation) async {
    await _db.collection(colInKind).doc(donation.id).set(donation.toMap());
  }

  static Future<void> settleAdvance(MemberAdvance settledAdvance, ExpenseVoucher voucher) async {
    final batch = _db.batch();
    final advRef = _db.collection(colAdvances).doc(settledAdvance.id);
    final expRef = _db.collection(colExpenses).doc(voucher.id);

    batch.set(advRef, settledAdvance.toMap());
    batch.set(expRef, voucher.toMap());

    await batch.commit();
  }

  static Future<void> deleteBook(String id) async {
    await _db.collection(colBooks).doc(id).delete();
  }

  static Future<void> deleteBookCascade(String id, List<String> slipIds) async {
    final batch = _db.batch();
    batch.delete(_db.collection(colBooks).doc(id));
    for (final sId in slipIds) {
      batch.delete(_db.collection(colSlips).doc(sId));
    }
    await batch.commit();
  }

  static Future<void> deleteSlip(String id) async {
    await _db.collection(colSlips).doc(id).delete();
  }

  static Future<void> deleteExpense(String id) async {
    await _db.collection(colExpenses).doc(id).delete();
  }

  static Future<void> deleteAdvance(String id) async {
    await _db.collection(colAdvances).doc(id).delete();
  }

  static Future<void> deleteInKindDonation(String id) async {
    await _db.collection(colInKind).doc(id).delete();
  }

  static Future<void> saveActivityLog(AuditActivityLog log) async {
    await _db.collection(colActivityLogs).doc(log.id).set(log.toMap());
  }

  static Future<void> deleteActivityLog(String id) async {
    await _db.collection(colActivityLogs).doc(id).delete();
  }
}

