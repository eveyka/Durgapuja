import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const String _keyEvents = 'dper_live_v2_events';
  static const String _keyActiveEventId = 'dper_live_v2_active_event_id';
  static const String _keyBooks = 'dper_live_v2_books';
  static const String _keySlips = 'dper_live_v2_slips';
  static const String _keyCollectionAccounts = 'dper_live_v2_collection_accounts';
  static const String _keyExpenditureAccounts = 'dper_live_v2_expenditure_accounts';
  static const String _keyExpenses = 'dper_live_v2_expenses';
  static const String _keyAdvances = 'dper_live_v2_advances';
  static const String _keyInKind = 'dper_live_v2_in_kind';
  static const String _keyActivityLogs = 'dper_live_v2_activity_logs';
  static const String _keySettings = 'dper_live_v2_settings';

  static Future<void> saveEvents(List<PujaEvent> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = events.map((e) => e.toMap()).toList();
    await prefs.setString(_keyEvents, jsonEncode(jsonList));
  }

  static Future<List<PujaEvent>?> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyEvents);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => PujaEvent.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActiveEventId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveEventId, id);
  }

  static Future<String?> loadActiveEventId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveEventId);
  }

  static Future<void> saveBooks(List<ChandaBook> books) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = books.map((b) => b.toMap()).toList();
    await prefs.setString(_keyBooks, jsonEncode(jsonList));
  }

  static Future<List<ChandaBook>?> loadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyBooks);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => ChandaBook.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSlips(List<ChandaSlip> slips) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = slips.map((s) => s.toMap()).toList();
    await prefs.setString(_keySlips, jsonEncode(jsonList));
  }

  static Future<List<ChandaSlip>?> loadSlips() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySlips);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => ChandaSlip.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveCollectionAccounts(List<CollectionAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = accounts.map((a) => a.toMap()).toList();
    await prefs.setString(_keyCollectionAccounts, jsonEncode(jsonList));
  }

  static Future<List<CollectionAccount>?> loadCollectionAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyCollectionAccounts);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => CollectionAccount.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveExpenditureAccounts(List<ExpenditureAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = accounts.map((a) => a.toMap()).toList();
    await prefs.setString(_keyExpenditureAccounts, jsonEncode(jsonList));
  }

  static Future<List<ExpenditureAccount>?> loadExpenditureAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyExpenditureAccounts);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => ExpenditureAccount.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveExpenses(List<ExpenseVoucher> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = expenses.map((e) => e.toMap()).toList();
    await prefs.setString(_keyExpenses, jsonEncode(jsonList));
  }

  static Future<List<ExpenseVoucher>?> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyExpenses);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => ExpenseVoucher.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveAdvances(List<MemberAdvance> advances) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = advances.map((a) => a.toMap()).toList();
    await prefs.setString(_keyAdvances, jsonEncode(jsonList));
  }

  static Future<List<MemberAdvance>?> loadAdvances() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyAdvances);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => MemberAdvance.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveInKindDonations(List<InKindDonation> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toMap()).toList();
    await prefs.setString(_keyInKind, jsonEncode(jsonList));
  }

  static Future<List<InKindDonation>?> loadInKindDonations() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyInKind);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => InKindDonation.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveSettings({
    required String pujaName,
    required String cashierName,
    required int currentYear,
    required String presidentName,
    required String secretaryName,
    Map<ExpenseCategory, double> budgets = const {},
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'pujaName': pujaName,
      'cashierName': cashierName,
      'currentYear': currentYear,
      'presidentName': presidentName,
      'secretaryName': secretaryName,
      'budgets': {
        for (final entry in budgets.entries) entry.key.name: entry.value,
      },
    };
    await prefs.setString(_keySettings, jsonEncode(map));
  }

  static Future<Map<String, dynamic>?> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySettings);
    if (str == null || str.isEmpty) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveActivityLogs(List<AuditActivityLog> logs) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = logs.map((l) => l.toMap()).toList();
    await prefs.setString(_keyActivityLogs, jsonEncode(jsonList));
  }

  static Future<List<AuditActivityLog>?> loadActivityLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyActivityLogs);
    if (str == null || str.isEmpty) return null;
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((m) => AuditActivityLog.fromMap(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}
