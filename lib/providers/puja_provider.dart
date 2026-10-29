import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class PujaProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  // Puja Metadata
  String pujaName = "Tribeni Shanga Durga Puja 2026";
  String cashierName = "Cashier";
  int currentYear = 2026;
  String presidentName = "President";
  String secretaryName = "General Secretary";

  // Category-wise allocated budgets (empty = not set)
  Map<ExpenseCategory, double> categoryBudgets = {};

  // Live Lists
  List<PujaEvent> _events = [];
  String? _selectedEventId;
  List<ChandaBook> _books = [];
  List<ChandaSlip> _slips = [];
  List<CollectionAccount> _collectionAccounts = [];
  List<ExpenditureAccount> _expenditureAccounts = [];
  List<ExpenseVoucher> _expenses = [];
  List<MemberAdvance> _advances = [];
  List<InKindDonation> _inKindDonations = [];
  List<AuditActivityLog> _activityLogs = [];

  List<PujaEvent> get events => List.unmodifiable(_events);
  String? get selectedEventId => _selectedEventId;

  PujaEvent? get selectedEvent {
    if (_events.isEmpty) return null;
    return _events.firstWhere(
      (e) => e.id == _selectedEventId,
      orElse: () => _events.first,
    );
  }

  List<ChandaBook> get books => List.unmodifiable(_books);
  List<ChandaSlip> get slips => List.unmodifiable(_slips);
  List<CollectionAccount> get collectionAccounts => List.unmodifiable(_collectionAccounts);
  List<ExpenditureAccount> get expenditureAccounts => List.unmodifiable(_expenditureAccounts);

  List<CollectionAccount> get activeEventCollectionAccounts {
    if (_selectedEventId == null) return _collectionAccounts;
    final isFirstEvent = _events.isNotEmpty && _events.first.id == _selectedEventId;
    return _collectionAccounts.where((a) => a.eventId == _selectedEventId || (a.eventId == null && isFirstEvent)).toList();
  }

  List<ExpenditureAccount> get activeEventExpenditureAccounts {
    if (_selectedEventId == null) return _expenditureAccounts;
    final isFirstEvent = _events.isNotEmpty && _events.first.id == _selectedEventId;
    return _expenditureAccounts.where((a) => a.eventId == _selectedEventId || (a.eventId == null && isFirstEvent)).toList();
  }

  List<ExpenseVoucher> get expenses => List.unmodifiable(_expenses);
  List<MemberAdvance> get advances => List.unmodifiable(_advances);
  List<InKindDonation> get inKindDonations => List.unmodifiable(_inKindDonations);
  List<AuditActivityLog> get activityLogs => List.unmodifiable(_activityLogs);

  // Cached aggregates to avoid redundant iterations and allocations during UI build
  List<ChandaSlip>? _cachedActiveEventSlips;
  List<ExpenseVoucher>? _cachedActiveEventExpenses;
  List<MemberAdvance>? _cachedActiveEventAdvances;
  List<ChandaSlip>? _cachedRecentSlips;
  List<ExpenseVoucher>? _cachedRecentExpenses;
  List<String>? _cachedAvailableCollectors;
  List<DonorSummary>? _cachedDonorSummaries;
  double? _cachedTotalIncome;
  double? _cachedTotalExpense;
  double? _cachedTotalCashIncome;
  double? _cachedTotalCashExpense;
  double? _cachedTotalDigitalIncome;
  double? _cachedTotalDigitalExpense;
  double? _cachedTodaysCollection;
  double? _cachedTotalEstimatedInKindValue;
  Map<InKindCategory, List<InKindDonation>>? _cachedInKindByCategory;
  Map<ExpenseCategory, double>? _cachedExpenseByCategory;
  List<DailyCashflow>? _cachedDailyCashflows;

  void _invalidateCaches() {
    _cachedActiveEventSlips = null;
    _cachedActiveEventExpenses = null;
    _cachedActiveEventAdvances = null;
    _cachedRecentSlips = null;
    _cachedRecentExpenses = null;
    _cachedAvailableCollectors = null;
    _cachedDonorSummaries = null;
    _cachedTotalIncome = null;
    _cachedTotalExpense = null;
    _cachedTotalCashIncome = null;
    _cachedTotalCashExpense = null;
    _cachedTotalDigitalIncome = null;
    _cachedTotalDigitalExpense = null;
    _cachedTodaysCollection = null;
    _cachedTotalEstimatedInKindValue = null;
    _cachedInKindByCategory = null;
    _cachedExpenseByCategory = null;
    _cachedDailyCashflows = null;
  }

  @override
  void notifyListeners() {
    _invalidateCaches();
    super.notifyListeners();
  }

  /// Slips filtered for the active event (or all if no event selected)
  List<ChandaSlip> get activeEventSlips {
    if (_cachedActiveEventSlips != null) return _cachedActiveEventSlips!;
    if (_selectedEventId == null) {
      _cachedActiveEventSlips = _slips;
    } else {
      final isFirstEvent = _events.isNotEmpty && _events.first.id == _selectedEventId;
      _cachedActiveEventSlips = _slips.where((s) => s.eventId == _selectedEventId || (s.eventId == null && isFirstEvent)).toList(growable: false);
    }
    return _cachedActiveEventSlips!;
  }

  double get eventTotalCollected {
    double sum = 0.0;
    for (final s in activeEventSlips) {
      if (s.isCash) sum += s.paidAmount;
    }
    return sum;
  }

  double get eventTotalPending {
    double sum = 0.0;
    for (final s in activeEventSlips) {
      if (s.isCash && !s.isFullyPaid) sum += s.pendingAmount;
    }
    return sum;
  }

  double get eventTotalPledged {
    double sum = 0.0;
    for (final s in activeEventSlips) {
      if (s.isCash) sum += s.amount;
    }
    return sum;
  }

  int get eventPaidCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isFullyPaid) count++;
    }
    return count;
  }

  int get eventUnpaidCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isUnpaid) count++;
    }
    return count;
  }

  int get eventPartialCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isPartial) count++;
    }
    return count;
  }

  int get eventCashCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isCash) count++;
    }
    return count;
  }

  int get eventInKindCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isInKind) count++;
    }
    return count;
  }

  int get eventInKindReceivedCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isInKind && s.isFullyPaid) count++;
    }
    return count;
  }

  int get eventInKindPendingCount {
    int count = 0;
    for (final s in activeEventSlips) {
      if (s.isInKind && !s.isFullyPaid) count++;
    }
    return count;
  }

  double get eventTotalInKindEstimatedValue {
    double sum = 0.0;
    for (final s in activeEventSlips) {
      if (s.isInKind) sum += s.amount;
    }
    return sum;
  }

  /// Expenses filtered for the active event (or all if no event selected)
  List<ExpenseVoucher> get activeEventExpenses {
    if (_cachedActiveEventExpenses != null) return _cachedActiveEventExpenses!;
    if (_selectedEventId == null) {
      _cachedActiveEventExpenses = _expenses;
    } else {
      final isFirstEvent = _events.isNotEmpty && _events.first.id == _selectedEventId;
      _cachedActiveEventExpenses = _expenses.where((e) => e.eventId == _selectedEventId || (e.eventId == null && isFirstEvent)).toList(growable: false);
    }
    return _cachedActiveEventExpenses!;
  }

  /// Advances filtered for the active event (or all if no event selected)
  List<MemberAdvance> get activeEventAdvances {
    if (_cachedActiveEventAdvances != null) return _cachedActiveEventAdvances!;
    if (_selectedEventId == null) {
      _cachedActiveEventAdvances = _advances;
    } else {
      final isFirstEvent = _events.isNotEmpty && _events.first.id == _selectedEventId;
      _cachedActiveEventAdvances = _advances.where((a) => a.eventId == _selectedEventId || (a.eventId == null && isFirstEvent)).toList(growable: false);
    }
    return _cachedActiveEventAdvances!;
  }

  double get eventTotalExpense {
    double sum = 0.0;
    for (final exp in activeEventExpenses) {
      sum += exp.amount;
    }
    return sum;
  }

  double get eventTotalPendingAdvance {
    double sum = 0.0;
    for (final a in activeEventAdvances) {
      if (a.status == 'Pending') sum += a.advanceAmount;
    }
    return sum;
  }

  double get eventNetBalance => eventTotalCollected - eventTotalExpense;

  Map<ExpenseCategory, double> get eventExpenseByCategory {
    final map = <ExpenseCategory, double>{};
    for (var cat in ExpenseCategory.values) {
      map[cat] = 0.0;
    }
    for (var exp in activeEventExpenses) {
      map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
    }
    return map;
  }

  // Event-specific calculation helpers for any event ID
  double getEventCollected(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _slips
        .where((s) => s.isCash && (s.eventId == eventId || (s.eventId == null && isFirst)))
        .fold(0.0, (sum, s) => sum + s.paidAmount);
  }

  double getEventExpense(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _expenses
        .where((e) => e.eventId == eventId || (e.eventId == null && isFirst))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double getEventNetBalance(String eventId) {
    return getEventCollected(eventId) - getEventExpense(eventId);
  }

  int getEventDonorCount(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _slips
        .where((s) => s.isCash && (s.eventId == eventId || (s.eventId == null && isFirst)))
        .length;
  }

  int getEventInKindCount(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _slips
        .where((s) => s.isInKind && (s.eventId == eventId || (s.eventId == null && isFirst)))
        .length;
  }

  double getEventPendingAdvance(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _advances
        .where((a) => a.status == 'Pending' && (a.eventId == eventId || (a.eventId == null && isFirst)))
        .fold(0.0, (sum, a) => sum + a.advanceAmount);
  }

  int getEventAdvanceCount(String eventId) {
    final isFirst = _events.isNotEmpty && _events.first.id == eventId;
    return _advances
        .where((a) => a.eventId == eventId || (a.eventId == null && isFirst))
        .length;
  }

  /// Dynamic list of collectors for auto-suggest / quick selection (memoized)
  List<String> get availableCollectors {
    if (_cachedAvailableCollectors != null) return _cachedAvailableCollectors!;
    final Set<String> collectors = {};
    if (cashierName.isNotEmpty && cashierName != 'Cashier') collectors.add(cashierName);
    if (presidentName.isNotEmpty && presidentName != 'President') collectors.add(presidentName);
    if (secretaryName.isNotEmpty && secretaryName != 'General Secretary') collectors.add(secretaryName);

    for (var s in _slips) {
      if (s.collectedBy.trim().isNotEmpty) collectors.add(s.collectedBy.trim());
    }
    for (var b in _books) {
      if (b.assignedTo.trim().isNotEmpty) collectors.add(b.assignedTo.trim());
    }
    _cachedAvailableCollectors = collectors.toList()..sort();
    return _cachedAvailableCollectors!;
  }

  double get totalEstimatedInKindValue {
    if (_cachedTotalEstimatedInKindValue != null) return _cachedTotalEstimatedInKindValue!;
    _cachedTotalEstimatedInKindValue = _inKindDonations.fold<double>(0.0, (double sum, i) => sum + (i.estimatedValue ?? 0.0));
    return _cachedTotalEstimatedInKindValue!;
  }

  Map<InKindCategory, List<InKindDonation>> get inKindByCategory {
    if (_cachedInKindByCategory != null) return _cachedInKindByCategory!;
    final map = <InKindCategory, List<InKindDonation>>{};
    for (var cat in InKindCategory.values) {
      map[cat] = [];
    }
    for (var item in _inKindDonations) {
      map[item.category]?.add(item);
    }
    _cachedInKindByCategory = map;
    return map;
  }

  double get totalPendingAdvance => _advances
      .where((a) => a.status == 'Pending')
      .fold(0.0, (sum, a) => sum + a.advanceAmount);

  // Budget helpers
  double budgetFor(ExpenseCategory cat) => categoryBudgets[cat] ?? 0.0;

  double get totalBudget => categoryBudgets.values.fold(0.0, (a, b) => a + b);

  List<ExpenseCategory> get overBudgetCategories => categoryBudgets.entries
      .where((e) => e.value > 0 && (expenseByCategory[e.key] ?? 0) > e.value)
      .map((e) => e.key)
      .toList();

  // Donor CRM: aggregated per-donor summaries sorted by total donated (memoized)
  List<DonorSummary> get donorSummaries {
    if (_cachedDonorSummaries != null) return _cachedDonorSummaries!;
    final map = <String, List<ChandaSlip>>{};
    for (final s in _slips) {
      final key = s.donorName.trim().toLowerCase();
      if (key.isEmpty) continue;
      (map[key] ??= []).add(s);
    }
    final summaries = map.entries.map((e) {
      final slips = e.value..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return DonorSummary(
        name: slips.first.donorName.trim(),
        totalDonated: slips.fold(0.0, (sum, s) => sum + s.paidAmount),
        donationCount: slips.length,
        lastDonation: slips.first.createdAt,
        slips: slips,
      );
    }).toList();
    summaries.sort((a, b) => b.totalDonated.compareTo(a.totalDonated));
    _cachedDonorSummaries = summaries;
    return summaries;
  }

  /// Recent slips sorted latest first (memoized)
  List<ChandaSlip> get recentSlips {
    if (_cachedRecentSlips != null) return _cachedRecentSlips!;
    _cachedRecentSlips = List<ChandaSlip>.from(_slips)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _cachedRecentSlips!;
  }

  /// Recent expenses sorted latest first (memoized)
  List<ExpenseVoucher> get recentExpenses {
    if (_cachedRecentExpenses != null) return _cachedRecentExpenses!;
    _cachedRecentExpenses = List<ExpenseVoucher>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return _cachedRecentExpenses!;
  }

  // Firestore Subscriptions
  StreamSubscription<User?>? _authSub;
  StreamSubscription? _settingsSub;
  StreamSubscription? _eventsSub;
  StreamSubscription? _booksSub;
  StreamSubscription? _slipsSub;
  StreamSubscription? _collectionAccountsSub;
  StreamSubscription? _expenditureAccountsSub;
  StreamSubscription? _expensesSub;
  StreamSubscription? _advancesSub;
  StreamSubscription? _inKindSub;
  StreamSubscription? _activityLogsSub;

  PujaProvider() {
    _initStorageAndFirestore();
  }

  Future<void> _initStorageAndFirestore() async {
    // 1. Load local cache first for instant startup
    final savedEvents = await StorageService.loadEvents();
    final savedActiveEventId = await StorageService.loadActiveEventId();
    final savedBooks = await StorageService.loadBooks();
    final savedSlips = await StorageService.loadSlips();
    final savedCollectionAccounts = await StorageService.loadCollectionAccounts();
    final savedExpenditureAccounts = await StorageService.loadExpenditureAccounts();
    final savedExpenses = await StorageService.loadExpenses();
    final savedAdvances = await StorageService.loadAdvances();
    final savedInKind = await StorageService.loadInKindDonations();
    final savedLogs = await StorageService.loadActivityLogs();
    final savedSettings = await StorageService.loadSettings();

    if (savedSettings != null) {
      pujaName = savedSettings['pujaName'] ?? pujaName;
      cashierName = savedSettings['cashierName'] ?? cashierName;
      currentYear = savedSettings['currentYear'] ?? currentYear;
      presidentName = savedSettings['presidentName'] ?? presidentName;
      secretaryName = savedSettings['secretaryName'] ?? secretaryName;
      categoryBudgets = _parseBudgets(savedSettings['budgets']);
    }

    if (savedEvents != null && savedEvents.isNotEmpty) {
      _events = savedEvents;
    }
    _selectedEventId = savedActiveEventId ?? (_events.isNotEmpty ? _events.first.id : null);

    // If no events exist, initialize default event
    if (_events.isEmpty) {
      final defaultEvent = PujaEvent(
        id: _uuid.v4(),
        name: 'Durga Puja',
        year: currentYear,
        targetBudget: null,
        status: 'Active',
        createdAt: DateTime.now(),
      );
      _events.add(defaultEvent);
      _selectedEventId = defaultEvent.id;
      FirestoreService.saveEvent(defaultEvent);
      StorageService.saveEvents(_events);
      StorageService.saveActiveEventId(defaultEvent.id);
    }

    if (savedBooks != null) _books = savedBooks;
    if (savedSlips != null) _slips = savedSlips;
    if (savedCollectionAccounts != null) _collectionAccounts = savedCollectionAccounts;
    if (savedExpenditureAccounts != null) _expenditureAccounts = savedExpenditureAccounts;
    if (savedExpenses != null) _expenses = savedExpenses;
    if (savedAdvances != null) _advances = savedAdvances;
    if (savedInKind != null) _inKindDonations = savedInKind;
    if (savedLogs != null) _activityLogs = savedLogs;
    _ensureAdvanceExpenseVouchersSynced();

    notifyListeners();

    // 2. Start Real-time Cloud Firestore synchronization when user is authenticated
    if (FirebaseAuth.instance.currentUser != null) {
      _listenToFirestore();
    }

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _listenToFirestore();
      } else {
        _cancelFirestoreSubscriptions();
      }
    });
  }

  void _cancelFirestoreSubscriptions() {
    _settingsSub?.cancel();
    _eventsSub?.cancel();
    _booksSub?.cancel();
    _slipsSub?.cancel();
    _collectionAccountsSub?.cancel();
    _expenditureAccountsSub?.cancel();
    _expensesSub?.cancel();
    _advancesSub?.cancel();
    _inKindSub?.cancel();
    _activityLogsSub?.cancel();
    _settingsSub = null;
    _eventsSub = null;
    _booksSub = null;
    _slipsSub = null;
    _collectionAccountsSub = null;
    _expenditureAccountsSub = null;
    _expensesSub = null;
    _advancesSub = null;
    _inKindSub = null;
    _activityLogsSub = null;
  }

  void _listenToFirestore() {
    _cancelFirestoreSubscriptions();
    try {
      _settingsSub = FirestoreService.streamSettings().listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          pujaName = data['pujaName'] ?? pujaName;
          cashierName = data['cashierName'] ?? cashierName;
          currentYear = data['currentYear'] ?? currentYear;
          presidentName = data['presidentName'] ?? presidentName;
          secretaryName = data['secretaryName'] ?? secretaryName;
          if (data['budgets'] != null) categoryBudgets = _parseBudgets(data['budgets']);
          StorageService.saveSettings(
            pujaName: pujaName,
            cashierName: cashierName,
            currentYear: currentYear,
            presidentName: presidentName,
            secretaryName: secretaryName,
            budgets: categoryBudgets,
          );
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Firestore settings stream error: $e');
      });

      _eventsSub = FirestoreService.streamEvents().listen((events) {
        if (events.isNotEmpty) {
          _events = events;
          if (_selectedEventId == null || !_events.any((e) => e.id == _selectedEventId)) {
            _selectedEventId = _events.first.id;
            StorageService.saveActiveEventId(_selectedEventId!);
          }
          StorageService.saveEvents(_events);
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Firestore events stream error: $e');
      });

      _booksSub = FirestoreService.streamBooks().listen((books) {
        _books = books;
        StorageService.saveBooks(_books);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore books stream error: $e');
      });

      _slipsSub = FirestoreService.streamSlips().listen((slips) {
        _slips = slips;
        StorageService.saveSlips(_slips);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore slips stream error: $e');
      });

      _collectionAccountsSub = FirestoreService.streamCollectionAccounts().listen((accounts) {
        _collectionAccounts = accounts;
        StorageService.saveCollectionAccounts(_collectionAccounts);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore collection accounts stream error: $e');
      });

      _expenditureAccountsSub = FirestoreService.streamExpenditureAccounts().listen((accounts) {
        _expenditureAccounts = accounts;
        StorageService.saveExpenditureAccounts(_expenditureAccounts);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore expenditure accounts stream error: $e');
      });

      _expensesSub = FirestoreService.streamExpenses().listen((expenses) {
        _expenses = expenses;
        _ensureAdvanceExpenseVouchersSynced();
        StorageService.saveExpenses(_expenses);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore expenses stream error: $e');
      });

      _advancesSub = FirestoreService.streamAdvances().listen((advances) {
        _advances = advances;
        _ensureAdvanceExpenseVouchersSynced();
        StorageService.saveAdvances(_advances);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore advances stream error: $e');
      });

      _inKindSub = FirestoreService.streamInKindDonations().listen((donations) {
        _inKindDonations = donations;
        StorageService.saveInKindDonations(_inKindDonations);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore in-kind donations stream error: $e');
      });

      _activityLogsSub = FirestoreService.streamActivityLogs().listen((logs) {
        _activityLogs = logs;
        StorageService.saveActivityLogs(_activityLogs);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore activity logs stream error: $e');
      });
    } catch (e) {
      debugPrint('Error attaching Firestore listeners: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _cancelFirestoreSubscriptions();
    super.dispose();
  }

  /// Systematic Audit Logging for every created, updated, settled, or deleted action
  Future<void> logActivity({
    required String title,
    required String description,
    required ActivityActionType actionType,
    required ActivityModule module,
    double? amount,
    String? performedBy,
    String? referenceId,
    String? eventId,
    String? eventName,
    Map<String, dynamic>? metadata,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final actor = performedBy?.trim().isNotEmpty == true
        ? performedBy!.trim()
        : (cashierName.trim().isNotEmpty ? cashierName.trim() : (currentUser?.email ?? 'Cashier'));

    final targetEvtId = eventId ?? _selectedEventId;
    final activeEvt = _events.firstWhere(
      (e) => e.id == targetEvtId,
      orElse: () => PujaEvent(id: '', name: 'General Committee', year: currentYear, createdAt: DateTime.now()),
    );

    final log = AuditActivityLog(
      id: _uuid.v4(),
      title: title,
      description: description,
      actionType: actionType,
      module: module,
      amount: amount,
      performedBy: actor,
      timestamp: DateTime.now(),
      eventId: targetEvtId,
      eventName: eventName ?? (activeEvt.id.isNotEmpty ? '${activeEvt.name} ${activeEvt.year}' : null),
      referenceId: referenceId,
      metadata: metadata,
    );

    _activityLogs.insert(0, log);
    if (_activityLogs.length > 500) {
      _activityLogs = _activityLogs.sublist(0, 500);
    }

    FirestoreService.saveActivityLog(log);
    StorageService.saveActivityLogs(_activityLogs);
    notifyListeners();
  }

  void updateCommitteeSettings({
    required String newPujaName,
    required String newCashierName,
    required int newYear,
    required String newPresident,
    required String newSecretary,
  }) {
    pujaName = newPujaName;
    cashierName = newCashierName;
    currentYear = newYear;
    presidentName = newPresident;
    secretaryName = newSecretary;

    // Save to Firestore & Local Storage
    FirestoreService.saveSettings(
      pujaName: pujaName,
      cashierName: cashierName,
      currentYear: currentYear,
      presidentName: presidentName,
      secretaryName: secretaryName,
      budgets: categoryBudgets,
    );

    StorageService.saveSettings(
      pujaName: pujaName,
      cashierName: cashierName,
      currentYear: currentYear,
      presidentName: presidentName,
      secretaryName: secretaryName,
      budgets: categoryBudgets,
    );

    logActivity(
      title: 'Committee Profile Updated',
      description: 'Updated committee profile: $newPujaName ($newYear)',
      actionType: ActivityActionType.update,
      module: ActivityModule.settings,
    );

    notifyListeners();
  }

  void saveBudgets(Map<ExpenseCategory, double> budgets) {
    categoryBudgets = Map.of(budgets);

    FirestoreService.saveSettings(
      pujaName: pujaName,
      cashierName: cashierName,
      currentYear: currentYear,
      presidentName: presidentName,
      secretaryName: secretaryName,
      budgets: categoryBudgets,
    );

    StorageService.saveSettings(
      pujaName: pujaName,
      cashierName: cashierName,
      currentYear: currentYear,
      presidentName: presidentName,
      secretaryName: secretaryName,
      budgets: categoryBudgets,
    );

    logActivity(
      title: 'Budget Allocation Updated',
      description: 'Updated category expenditure budget allocation limits',
      actionType: ActivityActionType.update,
      module: ActivityModule.settings,
    );

    notifyListeners();
  }

  Map<ExpenseCategory, double> _parseBudgets(dynamic raw) {
    final result = <ExpenseCategory, double>{};
    if (raw is Map) {
      for (final cat in ExpenseCategory.values) {
        final value = raw[cat.name];
        final amount = (value as num?)?.toDouble() ?? 0.0;
        if (amount > 0) result[cat] = amount;
      }
    }
    return result;
  }

  /// Helper to verify if an event's financial data is synced to the Total Net Balance
  bool isEventSynced(String? eventId) {
    if (eventId == null) return true; // Unassigned / General committee items are synced by default
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index == -1) return true;
    return _events[index].isSynced;
  }

  // Aggregate Calculations (Memoized for zero-lag 60/120 FPS UI performance)
  double get totalIncome {
    if (_cachedTotalIncome != null) return _cachedTotalIncome!;
    double sum = 0.0;
    for (final s in _slips) {
      if (s.isCash && isEventSynced(s.eventId)) sum += s.paidAmount;
    }
    _cachedTotalIncome = sum;
    return sum;
  }

  double get totalExpense {
    if (_cachedTotalExpense != null) return _cachedTotalExpense!;
    double sum = 0.0;
    for (final exp in _expenses) {
      if (isEventSynced(exp.eventId)) sum += exp.amount;
    }
    _cachedTotalExpense = sum;
    return sum;
  }

  double get netBalance => totalIncome - totalExpense;

  double get totalCashIncome {
    if (_cachedTotalCashIncome != null) return _cachedTotalCashIncome!;
    double sum = 0.0;
    for (final s in _slips) {
      if (s.isCash && s.paymentMode == PaymentMode.cash && isEventSynced(s.eventId)) {
        sum += s.paidAmount;
      }
    }
    _cachedTotalCashIncome = sum;
    return sum;
  }

  double get totalCashExpense {
    if (_cachedTotalCashExpense != null) return _cachedTotalCashExpense!;
    double sum = 0.0;
    for (final exp in _expenses) {
      if (exp.paymentMode == PaymentMode.cash && isEventSynced(exp.eventId)) {
        sum += exp.amount;
      }
    }
    _cachedTotalCashExpense = sum;
    return sum;
  }

  double get cashInHand => (totalCashIncome - totalCashExpense) > 0 ? (totalCashIncome - totalCashExpense) : 0.0;

  double get totalDigitalIncome {
    if (_cachedTotalDigitalIncome != null) return _cachedTotalDigitalIncome!;
    double sum = 0.0;
    for (final s in _slips) {
      if (s.isCash && (s.paymentMode == PaymentMode.upi || s.paymentMode == PaymentMode.bankTransfer) && isEventSynced(s.eventId)) {
        sum += s.paidAmount;
      }
    }
    _cachedTotalDigitalIncome = sum;
    return sum;
  }

  double get totalDigitalExpense {
    if (_cachedTotalDigitalExpense != null) return _cachedTotalDigitalExpense!;
    double sum = 0.0;
    for (final exp in _expenses) {
      if (exp.paymentMode != PaymentMode.cash && isEventSynced(exp.eventId)) {
        sum += exp.amount;
      }
    }
    _cachedTotalDigitalExpense = sum;
    return sum;
  }

  double get bankUpiBalance => (totalDigitalIncome - totalDigitalExpense) > 0 ? (totalDigitalIncome - totalDigitalExpense) : 0.0;

  double get todaysCollection {
    if (_cachedTodaysCollection != null) return _cachedTodaysCollection!;
    final now = DateTime.now();
    double sum = 0.0;
    for (final s in _slips) {
      if (!s.isCash || !isEventSynced(s.eventId)) continue;
      final d = s.paymentDate ?? s.createdAt;
      if (d.year == now.year && d.month == now.month && d.day == now.day) {
        sum += s.paidAmount;
      }
    }
    _cachedTodaysCollection = sum;
    return sum;
  }

  // Category wise expense breakdown (filtered for synced events, memoized)
  Map<ExpenseCategory, double> get expenseByCategory {
    if (_cachedExpenseByCategory != null) return _cachedExpenseByCategory!;
    final map = <ExpenseCategory, double>{};
    for (var cat in ExpenseCategory.values) {
      map[cat] = 0.0;
    }
    for (var exp in _expenses) {
      if (isEventSynced(exp.eventId)) {
        map[exp.category] = (map[exp.category] ?? 0.0) + exp.amount;
      }
    }
    _cachedExpenseByCategory = map;
    return map;
  }

  // Dynamic Cashflows from live data (filtered for synced events, memoized)
  List<DailyCashflow> get dailyCashflows {
    if (_cachedDailyCashflows != null) return _cachedDailyCashflows!;
    final Map<String, DailyCashflow> flowMap = {};
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var d in days) {
      flowMap[d] = DailyCashflow(dayName: d, income: 0, expense: 0);
    }

    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (var s in _slips) {
      if (!s.isCash || !isEventSynced(s.eventId)) continue;
      final d = s.paymentDate ?? s.createdAt;
      final dName = dayNames[d.weekday];
      if (flowMap.containsKey(dName)) {
        flowMap[dName] = DailyCashflow(
          dayName: dName,
          income: flowMap[dName]!.income + s.paidAmount,
          expense: flowMap[dName]!.expense,
        );
      }
    }

    for (var e in _expenses) {
      if (!isEventSynced(e.eventId)) continue;
      final dName = dayNames[e.date.weekday];
      if (flowMap.containsKey(dName)) {
        flowMap[dName] = DailyCashflow(
          dayName: dName,
          income: flowMap[dName]!.income,
          expense: flowMap[dName]!.expense + e.amount,
        );
      }
    }

    _cachedDailyCashflows = flowMap.values.toList(growable: false);
    return _cachedDailyCashflows!;
  }

  // ==========================================
  // EVENT ACTIONS
  // ==========================================

  PujaEvent createEvent({
    required String name,
    required int year,
    double? targetBudget,
    String status = 'Active',
  }) {
    final newEvent = PujaEvent(
      id: _uuid.v4(),
      name: name.trim(),
      year: year,
      targetBudget: targetBudget,
      status: status,
      createdAt: DateTime.now(),
    );
    _events.insert(0, newEvent);
    _selectedEventId = newEvent.id;

    FirestoreService.saveEvent(newEvent);
    StorageService.saveEvents(_events);
    StorageService.saveActiveEventId(newEvent.id);

    logActivity(
      title: 'Festival Event Created',
      description: 'Created festival event "${newEvent.name} (${newEvent.year})"${targetBudget != null ? " with budget ₹${targetBudget.toStringAsFixed(0)}" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.event,
      amount: targetBudget,
      eventId: newEvent.id,
      referenceId: newEvent.id,
    );

    notifyListeners();
    return newEvent;
  }

  void updateEvent({
    required String id,
    required String name,
    required int year,
    double? targetBudget,
    String? status,
  }) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;

    final updated = _events[index].copyWith(
      name: name.trim(),
      year: year,
      targetBudget: targetBudget,
      status: status,
    );
    _events[index] = updated;

    FirestoreService.saveEvent(updated);
    StorageService.saveEvents(_events);

    logActivity(
      title: 'Festival Event Updated',
      description: 'Updated festival "${updated.name} (${updated.year})"',
      actionType: ActivityActionType.update,
      module: ActivityModule.event,
      amount: targetBudget,
      eventId: id,
      referenceId: id,
    );

    notifyListeners();
  }

  void deleteEvent(String id) {
    final target = _events.firstWhere(
      (e) => e.id == id,
      orElse: () => PujaEvent(id: id, name: 'Event', year: currentYear, createdAt: DateTime.now()),
    );
    _events.removeWhere((e) => e.id == id);
    if (_selectedEventId == id) {
      _selectedEventId = _events.isNotEmpty ? _events.first.id : null;
      if (_selectedEventId != null) {
        StorageService.saveActiveEventId(_selectedEventId!);
      }
    }
    FirestoreService.deleteEvent(id);
    StorageService.saveEvents(_events);

    logActivity(
      title: 'Festival Event Deleted',
      description: 'Deleted event "${target.name} (${target.year})"',
      actionType: ActivityActionType.delete,
      module: ActivityModule.event,
      eventId: id,
      referenceId: id,
    );

    notifyListeners();
  }

  void selectEvent(String id) {
    _selectedEventId = id;
    StorageService.saveActiveEventId(id);
    notifyListeners();
  }

  /// Toggles whether an event's financial data is synced to the Total Net Balance
  void toggleEventSync(String id) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final evt = _events[index];
    final nextSyncState = !evt.isSynced;
    final updated = evt.copyWith(
      isSynced: nextSyncState,
      syncedAt: nextSyncState ? DateTime.now() : null,
    );
    _events[index] = updated;

    FirestoreService.saveEvent(updated);
    StorageService.saveEvents(_events);

    logActivity(
      title: 'Festival Sync ${nextSyncState ? "Enabled" : "Disabled"}',
      description: '${nextSyncState ? "Included" : "Excluded"} "${evt.name} (${evt.year})" in Total Net Balance',
      actionType: ActivityActionType.update,
      module: ActivityModule.event,
      eventId: id,
      referenceId: id,
    );

    notifyListeners();
  }

  /// Explicitly sets the sync state of an event to the Total Net Balance
  void setEventSync(String id, bool sync) {
    final index = _events.indexWhere((e) => e.id == id);
    if (index == -1) return;
    final evt = _events[index];
    if (evt.isSynced == sync) return;

    final updated = evt.copyWith(
      isSynced: sync,
      syncedAt: sync ? DateTime.now() : null,
    );
    _events[index] = updated;

    FirestoreService.saveEvent(updated);
    StorageService.saveEvents(_events);

    logActivity(
      title: 'Festival Sync ${sync ? "Enabled" : "Disabled"}',
      description: '${sync ? "Included" : "Excluded"} "${evt.name} (${evt.year})" in Total Net Balance',
      actionType: ActivityActionType.update,
      module: ActivityModule.event,
      eventId: id,
      referenceId: id,
    );

    notifyListeners();
  }

  // ==========================================
  // COLLECTION & EXPENDITURE ACCOUNTS ACTIONS
  // ==========================================

  List<ChandaSlip> getAccountSlips(String accountId) {
    return _slips.where((s) => s.accountId == accountId).toList();
  }

  double getAccountTotalPledged(String accountId) {
    return getAccountSlips(accountId).fold(0.0, (sum, s) => sum + s.amount);
  }

  double getAccountTotalPaid(String accountId) {
    return getAccountSlips(accountId).fold(0.0, (sum, s) => sum + s.paidAmount);
  }

  double getAccountTotalUnpaid(String accountId) {
    return getAccountSlips(accountId).fold(0.0, (sum, s) => sum + s.pendingAmount);
  }

  int getAccountPaidCount(String accountId) {
    return getAccountSlips(accountId).where((s) => s.isFullyPaid).length;
  }

  int getAccountUnpaidCount(String accountId) {
    return getAccountSlips(accountId).where((s) => s.isUnpaid).length;
  }

  int getAccountPartialCount(String accountId) {
    return getAccountSlips(accountId).where((s) => s.isPartial).length;
  }

  List<ExpenseVoucher> getAccountExpenses(String accountId) {
    return _expenses.where((e) => e.accountId == accountId).toList();
  }

  double getAccountTotalSpent(String accountId) {
    return getAccountExpenses(accountId).fold(0.0, (sum, e) => sum + e.amount);
  }

  double getAccountRemainingBudget(ExpenditureAccount account) {
    if (account.allocatedBudget == null) return 0.0;
    return account.allocatedBudget! - getAccountTotalSpent(account.id);
  }

  CollectionAccount addCollectionAccount({
    required String accountName,
    required String areaName,
    String? collectorName,
    String? collectorPhone,
    double? targetAmount,
    int? bookNumber,
    int? startSlip,
    int? endSlip,
    String? eventId,
    String? notes,
  }) {
    final targetEventId = eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);
    final newAccount = CollectionAccount(
      id: _uuid.v4(),
      accountName: accountName.trim(),
      areaName: areaName.trim(),
      collectorName: (collectorName != null && collectorName.trim().isNotEmpty) ? collectorName.trim() : null,
      collectorPhone: (collectorPhone != null && collectorPhone.trim().isNotEmpty) ? collectorPhone.trim() : null,
      targetAmount: targetAmount,
      bookNumber: bookNumber,
      startSlip: startSlip,
      endSlip: endSlip,
      eventId: targetEventId,
      createdAt: DateTime.now(),
      status: 'Active',
      notes: notes?.trim(),
    );

    _collectionAccounts.insert(0, newAccount);
    FirestoreService.saveCollectionAccount(newAccount);
    StorageService.saveCollectionAccounts(_collectionAccounts);

    logActivity(
      title: 'Collection Account Created',
      description: 'Created account "${newAccount.accountName}" for area ${newAccount.areaName}${newAccount.collectorName != null ? " (In-Charge: ${newAccount.collectorName})" : ""}${newAccount.targetAmount != null ? " • Target: ₹${newAccount.targetAmount!.toStringAsFixed(0)}" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.account,
      amount: newAccount.targetAmount,
      eventId: newAccount.eventId,
      referenceId: newAccount.id,
    );

    notifyListeners();
    return newAccount;
  }

  int getNextSuggestedBookNumber() {
    int maxBook = 0;
    for (final acc in _collectionAccounts) {
      if (acc.bookNumber != null && acc.bookNumber! > maxBook) {
        maxBook = acc.bookNumber!;
      }
    }
    for (final b in _books) {
      if (b.bookNumber > maxBook) {
        maxBook = b.bookNumber;
      }
    }
    return maxBook + 1;
  }

  List<int> getUsedSlipNumbersForAccount(String accountId, {int? bookNumber}) {
    final accountSlips = _slips.where((s) {
      if (s.accountId == accountId) return true;
      if (bookNumber != null && s.bookNumber == bookNumber) return true;
      return false;
    }).toList();
    final used = accountSlips.map((s) => s.slipNumber).toSet().toList();
    used.sort();
    return used;
  }

  int getNextAvailableSlipForAccount(CollectionAccount account) {
    final usedSet = getUsedSlipNumbersForAccount(account.id, bookNumber: account.bookNumber).toSet();
    int candidate = account.startSlip ?? 1;
    while (usedSet.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  void updateCollectionAccount(CollectionAccount account) {
    final index = _collectionAccounts.indexWhere((a) => a.id == account.id);
    if (index == -1) return;
    _collectionAccounts[index] = account;
    FirestoreService.saveCollectionAccount(account);
    StorageService.saveCollectionAccounts(_collectionAccounts);

    logActivity(
      title: 'Collection Account Updated',
      description: 'Updated account "${account.accountName}" (Status: ${account.status})',
      actionType: ActivityActionType.update,
      module: ActivityModule.account,
      amount: account.targetAmount,
      eventId: account.eventId,
      referenceId: account.id,
    );

    notifyListeners();
  }

  void deleteCollectionAccount(String accountId) {
    final targetAccount = _collectionAccounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => CollectionAccount(id: accountId, accountName: '', areaName: ''),
    );
    final slipsToDelete = _slips.where((s) => s.accountId == accountId || (targetAccount.accountName.isNotEmpty && s.accountName == targetAccount.accountName)).toList();
    final slipIds = slipsToDelete.map((s) => s.id).toList();

    if (slipIds.isNotEmpty) {
      _slips.removeWhere((s) => slipIds.contains(s.id));
      StorageService.saveSlips(_slips);
    }
    _collectionAccounts.removeWhere((a) => a.id == accountId);

    FirestoreService.deleteCollectionAccountCascade(accountId, slipIds);
    StorageService.saveCollectionAccounts(_collectionAccounts);

    logActivity(
      title: 'Collection Account Deleted',
      description: 'Deleted account "${targetAccount.accountName}" and ${slipIds.length} linked slips',
      actionType: ActivityActionType.delete,
      module: ActivityModule.account,
      eventId: targetAccount.eventId,
      referenceId: accountId,
    );

    notifyListeners();
  }

  ExpenditureAccount addExpenditureAccount({
    required String accountName,
    required ExpenseCategory category,
    String? inChargeName,
    double? allocatedBudget,
    String? eventId,
    String? notes,
  }) {
    final targetEventId = eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);
    final newAccount = ExpenditureAccount(
      id: _uuid.v4(),
      accountName: accountName.trim(),
      category: category,
      inChargeName: (inChargeName != null && inChargeName.trim().isNotEmpty) ? inChargeName.trim() : null,
      allocatedBudget: allocatedBudget,
      eventId: targetEventId,
      createdAt: DateTime.now(),
      status: 'Active',
      notes: notes?.trim(),
    );

    _expenditureAccounts.insert(0, newAccount);
    FirestoreService.saveExpenditureAccount(newAccount);
    StorageService.saveExpenditureAccounts(_expenditureAccounts);

    logActivity(
      title: 'Expenditure Account Created',
      description: 'Created expense account "${newAccount.accountName}" for ${newAccount.category.displayName}${newAccount.allocatedBudget != null ? " (Budget: ₹${newAccount.allocatedBudget!.toStringAsFixed(0)})" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.account,
      amount: newAccount.allocatedBudget,
      eventId: newAccount.eventId,
      referenceId: newAccount.id,
    );

    notifyListeners();
    return newAccount;
  }

  void updateExpenditureAccount(ExpenditureAccount account) {
    final index = _expenditureAccounts.indexWhere((a) => a.id == account.id);
    if (index == -1) return;
    _expenditureAccounts[index] = account;
    FirestoreService.saveExpenditureAccount(account);
    StorageService.saveExpenditureAccounts(_expenditureAccounts);

    logActivity(
      title: 'Expenditure Account Updated',
      description: 'Updated expense account "${account.accountName}" (${account.category.displayName}, Status: ${account.status})',
      actionType: ActivityActionType.update,
      module: ActivityModule.account,
      amount: account.allocatedBudget,
      eventId: account.eventId,
      referenceId: account.id,
    );

    notifyListeners();
  }

  void deleteExpenditureAccount(String accountId) {
    final targetAccount = _expenditureAccounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => ExpenditureAccount(id: accountId, accountName: '', category: ExpenseCategory.securityMisc),
    );
    final vouchersToDelete = _expenses.where((e) => e.accountId == accountId || (targetAccount.accountName.isNotEmpty && e.accountName == targetAccount.accountName)).toList();
    final voucherIds = vouchersToDelete.map((e) => e.id).toList();

    if (voucherIds.isNotEmpty) {
      _expenses.removeWhere((e) => voucherIds.contains(e.id));
      StorageService.saveExpenses(_expenses);
    }
    _expenditureAccounts.removeWhere((a) => a.id == accountId);

    FirestoreService.deleteExpenditureAccountCascade(accountId, voucherIds);
    StorageService.saveExpenditureAccounts(_expenditureAccounts);

    logActivity(
      title: 'Expenditure Account Deleted',
      description: 'Deleted expense account "${targetAccount.accountName}" and ${voucherIds.length} linked vouchers',
      actionType: ActivityActionType.delete,
      module: ActivityModule.account,
      eventId: targetAccount.eventId,
      referenceId: accountId,
    );

    notifyListeners();
  }

  // ==========================================
  // DONATION / CHANDA ACTIONS (Direct Collector + Paid/Unpaid)
  // ==========================================

  ChandaSlip addDonation({
    required String donorName,
    String? phone,
    String? address,
    required double amount,
    double? paidAmount,
    required DonationStatus status,
    required PaymentMode paymentMode,
    required String collectedBy,
    int? slipNumber,
    int? bookNumber,
    DateTime? date,
    String? notes,
    String? dayLabel,
    String? eventId,
    String? accountId,
    String? accountName,
    DonationType donationType = DonationType.cash,
    String? inKindItemName,
    InKindCategory? inKindCategory,
    String? inKindQuantity,
    String? slipPhotoUrl,
  }) {
    final effectiveDate = date ?? DateTime.now();
    final double actualPaid = paidAmount ?? (status == DonationStatus.unpaid ? 0.0 : amount);
    final targetEventId = eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);

    final finalSlipNumber = slipNumber ?? (_slips.length + 1);
    final finalBookNumber = bookNumber ?? 1;

    final newSlip = ChandaSlip(
      id: _uuid.v4(),
      slipNumber: finalSlipNumber,
      bookNumber: finalBookNumber,
      accountId: accountId,
      accountName: accountName,
      donorName: donorName.trim(),
      phone: phone?.trim(),
      address: address?.trim(),
      amount: amount,
      paidAmount: actualPaid,
      status: status,
      paymentMode: paymentMode,
      collectedBy: collectedBy.trim(),
      createdAt: effectiveDate,
      paymentDate: actualPaid > 0 ? effectiveDate : null,
      notes: notes?.trim(),
      dayLabel: dayLabel,
      slipsCount: 1,
      eventId: targetEventId,
      donationType: donationType,
      inKindItemName: inKindItemName?.trim(),
      inKindCategory: inKindCategory,
      inKindQuantity: inKindQuantity?.trim(),
      slipPhotoUrl: slipPhotoUrl,
    );

    _slips.insert(0, newSlip);

    FirestoreService.saveSlipOnly(newSlip);
    StorageService.saveSlips(_slips);

    final statusText = status == DonationStatus.unpaid
        ? " (UNPAID DUE)"
        : (status == DonationStatus.partial ? " (Partial: ₹${actualPaid.toStringAsFixed(0)} Paid)" : " (Full Paid)");
    final inKindText = donationType == DonationType.inKind ? " [Samagri: ${inKindItemName ?? 'Item'}]" : "";

    logActivity(
      title: 'Collection Slip Added',
      description: 'Recorded ₹${amount.toStringAsFixed(0)} from ${donorName.trim()} (Slip #${newSlip.slipNumber}, Book #${newSlip.bookNumber}, ${paymentMode.name.toUpperCase()})$statusText$inKindText',
      actionType: ActivityActionType.create,
      module: ActivityModule.collection,
      amount: amount,
      performedBy: collectedBy,
      eventId: targetEventId,
      referenceId: newSlip.id,
    );

    notifyListeners();
    return newSlip;
  }

  void recordPayment({
    required String slipId,
    required double payingAmount,
    required PaymentMode paymentMode,
    required String collectedBy,
    DateTime? paymentDate,
    String? note,
  }) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final old = _slips[index];
    final newPaid = old.paidAmount + payingAmount;
    final newStatus = newPaid >= old.amount ? DonationStatus.paid : DonationStatus.partial;
    final date = paymentDate ?? DateTime.now();

    final newPayment = SlipPayment(
      id: _uuid.v4(),
      amount: payingAmount,
      date: date,
      paymentMode: paymentMode,
      collectedBy: collectedBy.trim().isNotEmpty ? collectedBy.trim() : old.collectedBy,
      note: note?.trim().isNotEmpty == true ? note!.trim() : 'Due Collection Payment',
    );

    final updatedPayments = List<SlipPayment>.from(old.payments)..add(newPayment);

    final updated = old.copyWith(
      paidAmount: newPaid > old.amount ? old.amount : newPaid,
      status: newStatus,
      paymentMode: paymentMode,
      collectedBy: collectedBy.trim().isNotEmpty ? collectedBy.trim() : old.collectedBy,
      paymentDate: date,
      payments: updatedPayments,
    );

    _slips[index] = updated;

    FirestoreService.saveSlipOnly(updated);
    StorageService.saveSlips(_slips);

    final remaining = (old.amount - updated.paidAmount);
    logActivity(
      title: 'Due Payment Collected',
      description: 'Collected ₹${payingAmount.toStringAsFixed(0)} from ${old.donorName} (Slip #${old.slipNumber}) via ${paymentMode.name.toUpperCase()}${remaining > 0 ? " • Remaining Due: ₹${remaining.toStringAsFixed(0)}" : " • Fully Cleared!"}',
      actionType: ActivityActionType.payment,
      module: ActivityModule.due,
      amount: payingAmount,
      performedBy: collectedBy,
      eventId: old.eventId,
      referenceId: slipId,
    );

    notifyListeners();
  }

  void updateSlipPayment({
    required String slipId,
    required String paymentId,
    required double amount,
    required DateTime date,
    required PaymentMode paymentMode,
    required String collectedBy,
    String? note,
  }) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final old = _slips[index];
    final pIdx = old.payments.indexWhere((p) => p.id == paymentId);
    if (pIdx == -1) return;

    final updatedPayment = old.payments[pIdx].copyWith(
      amount: amount,
      date: date,
      paymentMode: paymentMode,
      collectedBy: collectedBy.trim().isNotEmpty ? collectedBy.trim() : old.payments[pIdx].collectedBy,
      note: note?.trim(),
    );

    final updatedPayments = List<SlipPayment>.from(old.payments)..[pIdx] = updatedPayment;

    // Recalculate total paid
    final newPaid = updatedPayments.fold(0.0, (acc, p) => acc + p.amount);
    final newStatus = newPaid >= old.amount
        ? DonationStatus.paid
        : (newPaid > 0 ? DonationStatus.partial : DonationStatus.unpaid);

    final updated = old.copyWith(
      paidAmount: newPaid > old.amount ? old.amount : newPaid,
      status: newStatus,
      paymentMode: updatedPayments.isNotEmpty ? updatedPayments.last.paymentMode : old.paymentMode,
      collectedBy: updatedPayments.isNotEmpty ? updatedPayments.last.collectedBy : old.collectedBy,
      paymentDate: updatedPayments.isNotEmpty ? updatedPayments.last.date : null,
      payments: updatedPayments,
    );

    _slips[index] = updated;

    FirestoreService.saveSlipOnly(updated);
    StorageService.saveSlips(_slips);

    logActivity(
      title: 'Due Payment Updated',
      description: 'Updated payment of ₹${amount.toStringAsFixed(0)} for Slip #${old.slipNumber} (${old.donorName})',
      actionType: ActivityActionType.update,
      module: ActivityModule.due,
      amount: amount,
      performedBy: collectedBy,
      eventId: old.eventId,
      referenceId: slipId,
    );

    notifyListeners();
  }

  void deleteSlipPayment({
    required String slipId,
    required String paymentId,
  }) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final old = _slips[index];
    final targetPayment = old.payments.firstWhere((p) => p.id == paymentId, orElse: () => SlipPayment(id: '', amount: 0, date: DateTime.now()));
    final updatedPayments = List<SlipPayment>.from(old.payments)
      ..removeWhere((p) => p.id == paymentId);

    // Recalculate total paid
    final newPaid = updatedPayments.fold(0.0, (acc, p) => acc + p.amount);
    final newStatus = newPaid >= old.amount
        ? DonationStatus.paid
        : (newPaid > 0 ? DonationStatus.partial : DonationStatus.unpaid);

    final updated = old.copyWith(
      paidAmount: newPaid > old.amount ? old.amount : newPaid,
      status: newStatus,
      paymentMode: updatedPayments.isNotEmpty ? updatedPayments.last.paymentMode : old.paymentMode,
      collectedBy: updatedPayments.isNotEmpty ? updatedPayments.last.collectedBy : old.collectedBy,
      paymentDate: updatedPayments.isNotEmpty ? updatedPayments.last.date : null,
      payments: updatedPayments,
    );

    _slips[index] = updated;

    FirestoreService.saveSlipOnly(updated);
    StorageService.saveSlips(_slips);

    logActivity(
      title: 'Due Payment Removed',
      description: 'Deleted payment installment of ₹${targetPayment.amount.toStringAsFixed(0)} from Slip #${old.slipNumber} (${old.donorName})',
      actionType: ActivityActionType.delete,
      module: ActivityModule.due,
      amount: targetPayment.amount,
      eventId: old.eventId,
      referenceId: slipId,
    );

    notifyListeners();
  }

  void updateDonation({
    required String id,
    required String donorName,
    String? phone,
    String? address,
    required double amount,
    required double paidAmount,
    required DonationStatus status,
    required PaymentMode paymentMode,
    required String collectedBy,
    int? slipNumber,
    int? bookNumber,
    DateTime? date,
    String? notes,
    String? dayLabel,
    String? eventId,
    DonationType donationType = DonationType.cash,
    String? inKindItemName,
    InKindCategory? inKindCategory,
    String? inKindQuantity,
    String? slipPhotoUrl,
    bool clearSlipPhoto = false,
  }) {
    final index = _slips.indexWhere((s) => s.id == id);
    if (index == -1) return;

    final old = _slips[index];

    List<SlipPayment>? updatedPayments;
    if (old.payments.length <= 1) {
      if (paidAmount > 0) {
        updatedPayments = [
          SlipPayment(
            id: old.payments.isNotEmpty ? old.payments.first.id : '${old.id}_init',
            amount: paidAmount,
            date: date ?? old.paymentDate ?? old.createdAt,
            paymentMode: paymentMode,
            collectedBy: collectedBy.trim(),
            note: old.payments.isNotEmpty ? old.payments.first.note : 'Chanda Payment',
          )
        ];
      } else {
        updatedPayments = const [];
      }
    }

    final updated = old.copyWith(
      donorName: donorName.trim(),
      phone: phone?.trim(),
      address: address?.trim(),
      amount: amount,
      paidAmount: paidAmount,
      status: status,
      paymentMode: paymentMode,
      collectedBy: collectedBy.trim(),
      slipNumber: slipNumber ?? old.slipNumber,
      bookNumber: bookNumber ?? old.bookNumber,
      createdAt: date ?? old.createdAt,
      paymentDate: paidAmount > 0 ? (old.paymentDate ?? DateTime.now()) : null,
      notes: notes?.trim(),
      dayLabel: dayLabel,
      eventId: eventId ?? old.eventId,
      donationType: donationType,
      inKindItemName: inKindItemName?.trim(),
      inKindCategory: inKindCategory,
      inKindQuantity: inKindQuantity?.trim(),
      slipPhotoUrl: clearSlipPhoto ? null : (slipPhotoUrl ?? old.slipPhotoUrl),
      payments: updatedPayments ?? old.payments,
    );

    _slips[index] = updated;

    FirestoreService.saveSlipOnly(updated);
    StorageService.saveSlips(_slips);

    logActivity(
      title: 'Collection Slip Updated',
      description: 'Updated Slip #${updated.slipNumber} for ${donorName.trim()} (₹${amount.toStringAsFixed(0)}, Paid: ₹${paidAmount.toStringAsFixed(0)})',
      actionType: ActivityActionType.update,
      module: ActivityModule.collection,
      amount: amount,
      performedBy: collectedBy,
      eventId: updated.eventId,
      referenceId: id,
    );

    notifyListeners();
  }

  void deleteDonation(String id) {
    final index = _slips.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final target = _slips[index];

    _slips.removeAt(index);
    FirestoreService.deleteSlip(id);
    StorageService.saveSlips(_slips);

    logActivity(
      title: 'Collection Slip Deleted',
      description: 'Deleted collection record of ${target.donorName} (Slip #${target.slipNumber}, ₹${target.amount.toStringAsFixed(0)})',
      actionType: ActivityActionType.delete,
      module: ActivityModule.collection,
      amount: target.amount,
      eventId: target.eventId,
      referenceId: id,
    );

    notifyListeners();
  }

  void updateSlipReceiptPhoto({
    required String slipId,
    String? photoUrl,
  }) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final old = _slips[index];
    final updated = old.copyWith(
      slipPhotoUrl: photoUrl,
      clearSlipPhoto: photoUrl == null || photoUrl.isEmpty,
    );

    _slips[index] = updated;

    FirestoreService.saveSlipOnly(updated);
    StorageService.saveSlips(_slips);

    notifyListeners();
  }

  // ==========================================
  // ACTIONS (Real-time Firestore & Cache)
  // ==========================================

  ChandaSlip addChandaSlip({
    required int bookNumber,
    required String donorName,
    String? phone,
    String? address,
    required double amount,
    required PaymentMode paymentMode,
    required String collectedBy,
    String? notes,
    String? dayLabel,
    int slipsCount = 1,
    String? slipPhotoUrl,
    int? customSlipNumber,
  }) {
    final bookIndex = _books.indexWhere((b) => b.bookNumber == bookNumber);
    int nextSlipNo = customSlipNumber ?? 1;
    ChandaBook? updatedBook;

    if (bookIndex != -1) {
      final currentBook = _books[bookIndex];
      if (customSlipNumber == null) {
        nextSlipNo = currentBook.startSlip + currentBook.usedSlips;
      }
      updatedBook = currentBook.copyWith(
        usedSlips: currentBook.usedSlips + slipsCount,
        totalCollected: currentBook.totalCollected + amount,
      );
      _books[bookIndex] = updatedBook;
    } else {
      updatedBook = ChandaBook(
        id: _uuid.v4(),
        bookNumber: bookNumber,
        assignedTo: collectedBy,
        startSlip: 1,
        endSlip: 100,
        totalSlips: 100,
        usedSlips: slipsCount,
        totalCollected: amount,
      );
      _books.add(updatedBook);
    }

    final newSlip = ChandaSlip(
      id: _uuid.v4(),
      slipNumber: nextSlipNo,
      bookNumber: bookNumber,
      donorName: donorName,
      phone: phone,
      address: address,
      amount: amount,
      paymentMode: paymentMode,
      collectedBy: collectedBy,
      createdAt: DateTime.now(),
      notes: notes,
      dayLabel: dayLabel,
      slipsCount: slipsCount,
      eventId: _selectedEventId,
      slipPhotoUrl: slipPhotoUrl,
    );

    _slips.insert(0, newSlip);

    // Save to Firestore & local cache
    FirestoreService.saveSlip(newSlip, updatedBook);
    StorageService.saveSlips(_slips);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Collection Slip Added',
      description: 'Added slip #${newSlip.slipNumber} for ${donorName.trim()} in Book #$bookNumber (₹${amount.toStringAsFixed(0)}, ${paymentMode.name.toUpperCase()})',
      actionType: ActivityActionType.create,
      module: ActivityModule.collection,
      amount: amount,
      performedBy: collectedBy,
      eventId: newSlip.eventId,
      referenceId: newSlip.id,
    );

    notifyListeners();
    return newSlip;
  }

  ChandaSlip addBookDailyCollection({
    required int bookNumber,
    required String dayLabel,
    required double amount,
    int slipsCount = 1,
    required PaymentMode paymentMode,
    required String collectedBy,
    String? areaOrNotes,
    DateTime? customDate,
  }) {
    final bookIndex = _books.indexWhere((b) => b.bookNumber == bookNumber);
    int nextSlipNo = 1;
    ChandaBook? updatedBook;

    final date = customDate ?? DateTime.now();

    if (bookIndex != -1) {
      final currentBook = _books[bookIndex];
      nextSlipNo = currentBook.startSlip + currentBook.usedSlips;
      updatedBook = currentBook.copyWith(
        usedSlips: currentBook.usedSlips + slipsCount,
        totalCollected: currentBook.totalCollected + amount,
      );
      _books[bookIndex] = updatedBook;
    } else {
      updatedBook = ChandaBook(
        id: _uuid.v4(),
        bookNumber: bookNumber,
        assignedTo: collectedBy,
        startSlip: 1,
        endSlip: 100,
        totalSlips: 100,
        usedSlips: slipsCount,
        totalCollected: amount,
      );
      _books.add(updatedBook);
    }

    final String displayName = areaOrNotes != null && areaOrNotes.trim().isNotEmpty
        ? areaOrNotes.trim()
        : 'Book #$bookNumber ($dayLabel)';

    final newEntry = ChandaSlip(
      id: _uuid.v4(),
      slipNumber: nextSlipNo,
      bookNumber: bookNumber,
      donorName: displayName,
      phone: null,
      address: areaOrNotes,
      amount: amount,
      paymentMode: paymentMode,
      collectedBy: collectedBy,
      createdAt: date,
      notes: '$dayLabel Collection',
      dayLabel: dayLabel,
      slipsCount: slipsCount,
      eventId: _selectedEventId,
    );

    _slips.insert(0, newEntry);

    FirestoreService.saveSlip(newEntry, updatedBook);
    StorageService.saveSlips(_slips);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Daily Collection Added',
      description: 'Recorded daily collection of ₹${amount.toStringAsFixed(0)} for Book #$bookNumber ($dayLabel, $slipsCount slips) by $collectedBy',
      actionType: ActivityActionType.create,
      module: ActivityModule.collection,
      amount: amount,
      performedBy: collectedBy,
      eventId: newEntry.eventId,
      referenceId: newEntry.id,
    );

    notifyListeners();
    return newEntry;
  }

  void addInKindDonation({
    required String donorName,
    String? phone,
    required String itemName,
    required InKindCategory category,
    required String quantity,
    double? estimatedValue,
    required String receivedBy,
    String? notes,
    DateTime? date,
  }) {
    final item = InKindDonation(
      id: _uuid.v4(),
      donorName: donorName,
      phone: phone,
      itemName: itemName,
      category: category,
      quantity: quantity,
      estimatedValue: estimatedValue,
      receivedBy: receivedBy,
      date: date ?? DateTime.now(),
      notes: notes,
    );

    _inKindDonations.insert(0, item);

    FirestoreService.saveInKindDonation(item);
    StorageService.saveInKindDonations(_inKindDonations);

    logActivity(
      title: 'Samagri Donation Received',
      description: 'Received $quantity of $itemName (${category.displayName}) from ${donorName.trim()}${estimatedValue != null ? " • Est. Value: ₹${estimatedValue.toStringAsFixed(0)}" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.inKind,
      amount: estimatedValue,
      performedBy: receivedBy,
      referenceId: item.id,
    );

    notifyListeners();
  }

  void updateInKindDonation({
    required String id,
    required String donorName,
    String? phone,
    required String itemName,
    required InKindCategory category,
    required String quantity,
    double? estimatedValue,
    required String receivedBy,
    String? notes,
  }) {
    final index = _inKindDonations.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final old = _inKindDonations[index];
    final updated = InKindDonation(
      id: old.id,
      donorName: donorName,
      phone: phone,
      itemName: itemName,
      category: category,
      quantity: quantity,
      estimatedValue: estimatedValue,
      receivedBy: receivedBy,
      date: old.date,
      notes: notes,
    );

    _inKindDonations[index] = updated;

    FirestoreService.saveInKindDonation(updated);
    StorageService.saveInKindDonations(_inKindDonations);

    logActivity(
      title: 'Samagri Donation Updated',
      description: 'Updated in-kind item "$itemName" ($quantity) from ${donorName.trim()}',
      actionType: ActivityActionType.update,
      module: ActivityModule.inKind,
      amount: estimatedValue,
      performedBy: receivedBy,
      referenceId: id,
    );

    notifyListeners();
  }

  void deleteInKindDonation(String id) {
    final index = _inKindDonations.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = _inKindDonations[index];

    _inKindDonations.removeAt(index);

    FirestoreService.deleteInKindDonation(id);
    StorageService.saveInKindDonations(_inKindDonations);

    logActivity(
      title: 'Samagri Donation Deleted',
      description: 'Deleted in-kind entry "$item.itemName" ($item.quantity) from ${item.donorName}',
      actionType: ActivityActionType.delete,
      module: ActivityModule.inKind,
      amount: item.estimatedValue,
      referenceId: id,
    );

    notifyListeners();
  }

  // Generates a collision-safe sequential voucher number (max existing + 1)
  String _nextVoucherNo() {
    int max = 0;
    final pattern = RegExp(r'^V-(\d+)$');
    for (final e in _expenses) {
      final match = pattern.firstMatch(e.voucherNo);
      if (match != null) {
        final n = int.tryParse(match.group(1)!);
        if (n != null && n > max) max = n;
      }
    }
    return 'V-${(max + 1).toString().padLeft(3, '0')}';
  }

  void addExpense({
    required String payeeName,
    required ExpenseCategory category,
    required double amount,
    required PaymentMode paymentMode,
    required String paidBy,
    String? description,
    String? eventId,
    String? accountId,
    String? accountName,
    DateTime? date,
    String? receiptPhotoUrl,
  }) {
    final targetEventId = eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);
    final newVoucher = ExpenseVoucher(
      id: _uuid.v4(),
      voucherNo: _nextVoucherNo(),
      payeeName: payeeName,
      category: category,
      amount: amount,
      paymentMode: paymentMode,
      paidBy: paidBy,
      date: date ?? DateTime.now(),
      description: description,
      eventId: targetEventId,
      accountId: accountId,
      accountName: accountName,
      receiptPhotoUrl: receiptPhotoUrl,
    );

    _expenses.insert(0, newVoucher);

    // Save to Firestore & local cache
    FirestoreService.saveExpense(newVoucher);
    StorageService.saveExpenses(_expenses);

    logActivity(
      title: 'Expense Voucher Created',
      description: 'Recorded voucher ${newVoucher.voucherNo} of ₹${amount.toStringAsFixed(0)} to ${payeeName.trim()} for ${category.displayName} (${paymentMode.name.toUpperCase()})',
      actionType: ActivityActionType.create,
      module: ActivityModule.expense,
      amount: amount,
      performedBy: paidBy,
      eventId: targetEventId,
      referenceId: newVoucher.id,
    );

    notifyListeners();
  }

  void updateExpense({
    required String expenseId,
    required String payeeName,
    required ExpenseCategory category,
    required double amount,
    required PaymentMode paymentMode,
    required String paidBy,
    String? description,
    String? eventId,
    String? accountId,
    String? accountName,
    DateTime? date,
    String? receiptPhotoUrl,
    bool clearReceiptPhoto = false,
  }) {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final old = _expenses[index];
    final updated = old.copyWith(
      payeeName: payeeName,
      category: category,
      amount: amount,
      paymentMode: paymentMode,
      paidBy: paidBy,
      date: date ?? old.date,
      description: description,
      eventId: eventId ?? old.eventId,
      accountId: accountId ?? old.accountId,
      accountName: accountName ?? old.accountName,
      receiptPhotoUrl: receiptPhotoUrl,
      clearReceiptPhoto: clearReceiptPhoto,
    );

    _expenses[index] = updated;

    FirestoreService.saveExpense(updated);
    StorageService.saveExpenses(_expenses);

    logActivity(
      title: 'Expense Voucher Updated',
      description: 'Updated voucher ${old.voucherNo} (₹${amount.toStringAsFixed(0)}, Payee: ${payeeName.trim()}, Category: ${category.displayName})',
      actionType: ActivityActionType.update,
      module: ActivityModule.expense,
      amount: amount,
      performedBy: paidBy,
      eventId: updated.eventId,
      referenceId: expenseId,
    );

    notifyListeners();
  }

  void updateExpenseReceiptPhoto({
    required String expenseId,
    String? photoUrl,
  }) {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;

    final old = _expenses[index];
    final updated = old.copyWith(
      receiptPhotoUrl: photoUrl,
      clearReceiptPhoto: photoUrl == null || photoUrl.isEmpty,
    );

    _expenses[index] = updated;

    FirestoreService.saveExpense(updated);
    StorageService.saveExpenses(_expenses);

    notifyListeners();
  }

  void updateAdvanceReceiptPhoto({
    required String advanceId,
    String? photoUrl,
  }) {
    final index = _advances.indexWhere((a) => a.id == advanceId);
    if (index == -1) return;

    final old = _advances[index];
    final updated = old.copyWith(
      receiptPhotoUrl: photoUrl,
      clearReceiptPhoto: photoUrl == null || photoUrl.isEmpty,
    );

    _advances[index] = updated;

    FirestoreService.saveAdvance(updated);
    StorageService.saveAdvances(_advances);

    notifyListeners();
  }

  void deleteExpense(String id) {
    final expIndex = _expenses.indexWhere((e) => e.id == id);
    if (expIndex == -1) return;

    final exp = _expenses[expIndex];
    _expenses.removeAt(expIndex);

    // If linked to an advance installment, sync the advance ledger too!
    if (exp.advanceId != null && exp.installmentId != null) {
      final advIndex = _advances.indexWhere((a) => a.id == exp.advanceId);
      if (advIndex != -1) {
        final adv = _advances[advIndex];
        final updatedInstallments = adv.installments.where((i) => i.id != exp.installmentId).toList();
        final newTotalAdvance = updatedInstallments.fold<double>(0.0, (sum, i) => sum + i.amount);
        final updatedAdv = adv.copyWith(
          advanceAmount: newTotalAdvance,
          installments: updatedInstallments,
        );
        _advances[advIndex] = updatedAdv;
        FirestoreService.saveAdvance(updatedAdv);
        StorageService.saveAdvances(_advances);
      }
    }

    FirestoreService.deleteExpense(id);
    StorageService.saveExpenses(_expenses);

    logActivity(
      title: 'Expense Voucher Deleted',
      description: 'Deleted voucher ${exp.voucherNo} of ₹${exp.amount.toStringAsFixed(0)} (Payee: ${exp.payeeName}, ${exp.category.displayName})',
      actionType: ActivityActionType.delete,
      module: ActivityModule.expense,
      amount: exp.amount,
      eventId: exp.eventId,
      referenceId: id,
    );

    notifyListeners();
  }

  void addBook({
    required int bookNumber,
    required String assignedTo,
    String? collectorPhone,
    required int startSlip,
    required int endSlip,
  }) {
    final newBook = ChandaBook(
      id: _uuid.v4(),
      bookNumber: bookNumber,
      assignedTo: assignedTo,
      collectorPhone: collectorPhone,
      startSlip: startSlip,
      endSlip: endSlip,
      totalSlips: (endSlip - startSlip) + 1,
      usedSlips: 0,
      totalCollected: 0.0,
      status: 'Active',
    );

    _books.add(newBook);

    FirestoreService.saveBook(newBook);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Chanda Book Added',
      description: 'Assigned Book #$bookNumber to $assignedTo (Slips: $startSlip - $endSlip)',
      actionType: ActivityActionType.create,
      module: ActivityModule.book,
      performedBy: assignedTo,
      referenceId: newBook.id,
    );

    notifyListeners();
  }

  void updateBook({
    required String id,
    required int bookNumber,
    required String assignedTo,
    String? collectorPhone,
    required int startSlip,
    required int endSlip,
    String? status,
  }) {
    final index = _books.indexWhere((b) => b.id == id);
    if (index == -1) return;

    final old = _books[index];
    final totalSlips = (endSlip - startSlip) + 1;
    final updated = old.copyWith(
      bookNumber: bookNumber,
      assignedTo: assignedTo,
      collectorPhone: collectorPhone,
      startSlip: startSlip,
      endSlip: endSlip,
      totalSlips: totalSlips > 0 ? totalSlips : old.totalSlips,
      status: status ?? old.status,
    );

    _books[index] = updated;

    FirestoreService.saveBook(updated);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Chanda Book Updated',
      description: 'Updated Book #$bookNumber (Assigned to: $assignedTo, Status: ${updated.status})',
      actionType: ActivityActionType.update,
      module: ActivityModule.book,
      performedBy: assignedTo,
      referenceId: id,
    );

    notifyListeners();
  }

  void deleteBook(String id) {
    final bookIndex = _books.indexWhere((b) => b.id == id);
    final book = bookIndex != -1 ? _books[bookIndex] : null;
    int? bookNum = book?.bookNumber;
    final slipsToDelete = bookNum != null ? _slips.where((s) => s.bookNumber == bookNum).toList() : <ChandaSlip>[];
    final slipIds = slipsToDelete.map((s) => s.id).toList();

    if (slipIds.isNotEmpty) {
      _slips.removeWhere((s) => slipIds.contains(s.id));
      StorageService.saveSlips(_slips);
    }
    _books.removeWhere((b) => b.id == id);

    FirestoreService.deleteBookCascade(id, slipIds);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Chanda Book Deleted',
      description: 'Deleted Book #${book?.bookNumber ?? ""} (Assigned to: ${book?.assignedTo ?? ""}) and ${slipIds.length} linked slips',
      actionType: ActivityActionType.delete,
      module: ActivityModule.book,
      referenceId: id,
    );

    notifyListeners();
  }

  void _ensureAdvanceExpenseVouchersSynced() {
    bool hasChanges = false;
    for (final adv in _advances) {
      if (adv.status == 'Pending') {
        for (int i = 0; i < adv.installments.length; i++) {
          final inst = adv.installments[i];
          final exists = _expenses.any((e) =>
              e.installmentId == inst.id ||
              (e.advanceId == adv.id && e.amount == inst.amount));
          if (!exists) {
            final voucher = ExpenseVoucher(
              id: _uuid.v4(),
              voucherNo: _nextVoucherNo(),
              payeeName: adv.installments.length > 1
                  ? '${adv.memberName} (Advance #${i + 1})'
                  : '${adv.memberName} (Advance)',
              category: adv.category,
              amount: inst.amount,
              paymentMode: inst.paymentMode,
              paidBy: inst.recordedBy ?? cashierName,
              date: inst.date,
              description: inst.note.isNotEmpty
                  ? inst.note
                  : (adv.purpose.isNotEmpty ? 'Advance: ${adv.purpose}' : 'Advance Payment'),
              eventId: adv.eventId,
              advanceId: adv.id,
              installmentId: inst.id,
            );
            _expenses.insert(0, voucher);
            FirestoreService.saveExpense(voucher);
            hasChanges = true;
          }
        }
      }
    }
    if (hasChanges) {
      StorageService.saveExpenses(_expenses);
    }
  }

  void giveAdvance({
    required String memberName,
    required double amount,
    double? originalAmount,
    required ExpenseCategory category,
    required PaymentMode paymentMode,
    required String purpose,
    String? eventId,
    DateTime? date,
    List<AdvanceInstallment>? installments,
    String? receiptPhotoUrl,
  }) {
    final targetEventId = eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);
    final now = date ?? DateTime.now();

    final initInstallments = installments ??
        (amount > 0
            ? [
                AdvanceInstallment(
                  id: _uuid.v4(),
                  amount: amount,
                  date: now,
                  paymentMode: paymentMode,
                  note: purpose.isNotEmpty ? purpose : 'Initial Advance',
                  recordedBy: cashierName,
                ),
              ]
            : <AdvanceInstallment>[]);

    final isContractComplete = (originalAmount != null && originalAmount > 0 && amount >= originalAmount);

    final newAdvance = MemberAdvance(
      id: _uuid.v4(),
      memberName: memberName,
      advanceAmount: amount,
      originalAmount: (originalAmount != null && originalAmount > 0) ? originalAmount : null,
      category: category,
      paymentMode: paymentMode,
      purpose: purpose,
      dateGiven: now,
      status: isContractComplete ? 'Settled' : 'Pending',
      actualSpent: isContractComplete ? amount : null,
      dateSettled: isContractComplete ? now : null,
      billDetails: isContractComplete ? 'Contract completed in full upfront payment' : null,
      receiptPhotoUrl: receiptPhotoUrl,
      eventId: targetEventId,
      installments: initInstallments,
    );

    _advances.insert(0, newAdvance);

    // If money was paid (amount > 0), record an ExpenseVoucher transaction in _expenses!
    if (amount > 0 && initInstallments.isNotEmpty) {
      final initialVoucher = ExpenseVoucher(
        id: _uuid.v4(),
        voucherNo: _nextVoucherNo(),
        payeeName: '$memberName (Advance)',
        category: category,
        amount: amount,
        paymentMode: paymentMode,
        paidBy: cashierName,
        date: now,
        description: purpose.isNotEmpty ? 'Advance: $purpose' : 'Advance Payment',
        eventId: targetEventId,
        advanceId: newAdvance.id,
        installmentId: initInstallments.first.id,
        receiptPhotoUrl: receiptPhotoUrl,
      );
      _expenses.insert(0, initialVoucher);
      FirestoreService.saveExpense(initialVoucher);
      StorageService.saveExpenses(_expenses);
    }

    FirestoreService.saveAdvance(newAdvance);
    StorageService.saveAdvances(_advances);

    logActivity(
      title: 'Advance / Khata Issued',
      description: 'Issued advance of ₹${amount.toStringAsFixed(0)} to ${memberName.trim()} for ${purpose.trim()} (${category.displayName}, ${paymentMode.name.toUpperCase()})${originalAmount != null ? " • Contract: ₹${originalAmount.toStringAsFixed(0)}" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.advance,
      amount: amount,
      eventId: targetEventId,
      referenceId: newAdvance.id,
    );

    notifyListeners();
  }

  void addAdvanceInstallment({
    required String advanceId,
    required double amount,
    required PaymentMode paymentMode,
    String? note,
    DateTime? date,
    String? recordedBy,
  }) {
    final index = _advances.indexWhere((a) => a.id == advanceId);
    if (index == -1) return;

    final adv = _advances[index];
    final now = date ?? DateTime.now();
    final newInstallment = AdvanceInstallment(
      id: _uuid.v4(),
      amount: amount,
      date: now,
      paymentMode: paymentMode,
      note: note ?? 'Advance installment',
      recordedBy: recordedBy ?? cashierName,
    );

    final updatedInstallments = List<AdvanceInstallment>.from(adv.installments)..add(newInstallment);
    final newTotalAdvance = updatedInstallments.fold<double>(0.0, (sum, i) => sum + i.amount);

    final isContractComplete = adv.hasContract && newTotalAdvance >= (adv.originalAmount ?? double.infinity);

    final updated = adv.copyWith(
      advanceAmount: newTotalAdvance,
      installments: updatedInstallments,
      status: isContractComplete ? 'Settled' : adv.status,
      actualSpent: isContractComplete ? newTotalAdvance : adv.actualSpent,
      dateSettled: isContractComplete ? (adv.dateSettled ?? now) : adv.dateSettled,
      billDetails: isContractComplete && adv.billDetails == null
          ? 'Contract completed - 100% paid in installments'
          : adv.billDetails,
    );

    _advances[index] = updated;

    // Record the installment as an ExpenseVoucher transaction in _expenses!
    final installmentVoucher = ExpenseVoucher(
      id: _uuid.v4(),
      voucherNo: _nextVoucherNo(),
      payeeName: '${adv.memberName} (Advance #${updatedInstallments.length})',
      category: adv.category,
      amount: amount,
      paymentMode: paymentMode,
      paidBy: recordedBy ?? cashierName,
      date: now,
      description: (note != null && note.trim().isNotEmpty)
          ? note.trim()
          : 'Advance installment #${updatedInstallments.length} for ${adv.memberName} (${adv.purpose})',
      eventId: adv.eventId,
      advanceId: adv.id,
      installmentId: newInstallment.id,
    );

    _expenses.insert(0, installmentVoucher);
    FirestoreService.saveExpense(installmentVoucher);
    StorageService.saveExpenses(_expenses);

    FirestoreService.saveAdvance(updated);
    StorageService.saveAdvances(_advances);

    logActivity(
      title: 'Advance Installment Paid',
      description: 'Paid advance installment #${updatedInstallments.length} of ₹${amount.toStringAsFixed(0)} to ${adv.memberName} (Total: ₹${newTotalAdvance.toStringAsFixed(0)})${isContractComplete ? " • Contract Completed!" : ""}',
      actionType: ActivityActionType.create,
      module: ActivityModule.advance,
      amount: amount,
      performedBy: recordedBy ?? cashierName,
      eventId: adv.eventId,
      referenceId: advanceId,
    );

    notifyListeners();
  }

  void deleteAdvanceInstallment({
    required String advanceId,
    required String installmentId,
  }) {
    final index = _advances.indexWhere((a) => a.id == advanceId);
    if (index == -1) return;

    final adv = _advances[index];
    final targetInst = adv.installments.firstWhere((i) => i.id == installmentId, orElse: () => AdvanceInstallment(id: '', amount: 0, date: DateTime.now()));
    final updatedInstallments = adv.installments.where((i) => i.id != installmentId).toList();
    final newTotalAdvance = updatedInstallments.fold<double>(0.0, (sum, i) => sum + i.amount);

    final isStillComplete = adv.hasContract && newTotalAdvance >= (adv.originalAmount ?? double.infinity);
    final wasAutoSettled = adv.hasContract && adv.status == 'Settled' && !isStillComplete;

    final updated = adv.copyWith(
      advanceAmount: newTotalAdvance,
      installments: updatedInstallments,
      status: wasAutoSettled ? 'Pending' : adv.status,
      actualSpent: wasAutoSettled ? null : adv.actualSpent,
      dateSettled: wasAutoSettled ? null : adv.dateSettled,
      clearActualSpent: wasAutoSettled,
      clearDateSettled: wasAutoSettled,
    );

    _advances[index] = updated;

    // Delete corresponding ExpenseVoucher
    final expIndex = _expenses.indexWhere((e) => e.installmentId == installmentId);
    if (expIndex != -1) {
      final expId = _expenses[expIndex].id;
      _expenses.removeAt(expIndex);
      FirestoreService.deleteExpense(expId);
      StorageService.saveExpenses(_expenses);
    }

    FirestoreService.saveAdvance(updated);
    StorageService.saveAdvances(_advances);

    logActivity(
      title: 'Advance Installment Deleted',
      description: 'Removed installment of ₹${targetInst.amount.toStringAsFixed(0)} from ${adv.memberName}\'s advance ledger',
      actionType: ActivityActionType.delete,
      module: ActivityModule.advance,
      amount: targetInst.amount,
      eventId: adv.eventId,
      referenceId: advanceId,
    );

    notifyListeners();
  }

  void editAdvanceInstallment({
    required String advanceId,
    required String installmentId,
    required double newAmount,
    required PaymentMode newPaymentMode,
    required DateTime newDate,
    required String newNote,
  }) {
    final index = _advances.indexWhere((a) => a.id == advanceId);
    if (index == -1) return;

    final adv = _advances[index];
    final updatedInstallments = adv.installments.map((inst) {
      if (inst.id == installmentId) {
        return inst.copyWith(
          amount: newAmount,
          paymentMode: newPaymentMode,
          date: newDate,
          note: newNote,
        );
      }
      return inst;
    }).toList();

    final newTotalAdvance = updatedInstallments.fold<double>(0.0, (sum, i) => sum + i.amount);
    final isContractComplete = adv.hasContract && newTotalAdvance >= (adv.originalAmount ?? double.infinity);
    final wasAutoSettled = adv.hasContract && adv.status == 'Settled' && !isContractComplete;

    final updated = adv.copyWith(
      advanceAmount: newTotalAdvance,
      installments: updatedInstallments,
      status: isContractComplete ? 'Settled' : (wasAutoSettled ? 'Pending' : adv.status),
      actualSpent: isContractComplete ? newTotalAdvance : (wasAutoSettled ? null : adv.actualSpent),
      dateSettled: isContractComplete ? (adv.dateSettled ?? newDate) : (wasAutoSettled ? null : adv.dateSettled),
      clearActualSpent: wasAutoSettled,
      clearDateSettled: wasAutoSettled,
    );

    _advances[index] = updated;

    // Sync matching ExpenseVoucher
    final expIndex = _expenses.indexWhere((e) =>
        e.installmentId == installmentId ||
        (e.advanceId == advanceId &&
            e.amount == adv.installments.firstWhere((i) => i.id == installmentId, orElse: () => adv.installments.first).amount));
    if (expIndex != -1) {
      final oldExp = _expenses[expIndex];
      final updatedExp = oldExp.copyWith(
        amount: newAmount,
        paymentMode: newPaymentMode,
        date: newDate,
        description: newNote.isNotEmpty ? newNote : oldExp.description,
        installmentId: installmentId,
      );
      _expenses[expIndex] = updatedExp;
      FirestoreService.saveExpense(updatedExp);
      StorageService.saveExpenses(_expenses);
    }

    FirestoreService.saveAdvance(updated);
    StorageService.saveAdvances(_advances);

    logActivity(
      title: 'Advance Installment Updated',
      description: 'Updated installment to ₹${newAmount.toStringAsFixed(0)} for ${adv.memberName} (${newPaymentMode.name.toUpperCase()})',
      actionType: ActivityActionType.update,
      module: ActivityModule.advance,
      amount: newAmount,
      eventId: adv.eventId,
      referenceId: advanceId,
    );

    notifyListeners();
  }

  void updateAdvance({
    required String id,
    required String memberName,
    required double amount,
    double? originalAmount,
    required ExpenseCategory category,
    required PaymentMode paymentMode,
    required String purpose,
    DateTime? dateGiven,
    String? eventId,
    List<AdvanceInstallment>? installments,
    String? receiptPhotoUrl,
    bool clearReceiptPhoto = false,
  }) {
    final index = _advances.indexWhere((a) => a.id == id);
    if (index == -1) return;

    final old = _advances[index];
    final isContractComplete = (originalAmount != null && originalAmount > 0 && amount >= originalAmount);

    final updated = old.copyWith(
      memberName: memberName,
      advanceAmount: amount,
      originalAmount: originalAmount,
      category: category,
      paymentMode: paymentMode,
      purpose: purpose,
      dateGiven: dateGiven ?? old.dateGiven,
      status: isContractComplete ? 'Settled' : old.status,
      actualSpent: isContractComplete ? amount : old.actualSpent,
      dateSettled: isContractComplete ? (old.dateSettled ?? DateTime.now()) : old.dateSettled,
      eventId: eventId ?? old.eventId,
      installments: installments ?? old.installments,
      receiptPhotoUrl: receiptPhotoUrl,
      clearReceiptPhoto: clearReceiptPhoto,
    );

    _advances[index] = updated;

    // Also update category and eventId on any linked expense vouchers
    for (int i = 0; i < _expenses.length; i++) {
      if (_expenses[i].advanceId == id) {
        final oldExp = _expenses[i];
        final updatedExp = oldExp.copyWith(
          category: category,
          eventId: eventId ?? oldExp.eventId,
        );
        _expenses[i] = updatedExp;
        FirestoreService.saveExpense(updatedExp);
      }
    }
    StorageService.saveExpenses(_expenses);

    FirestoreService.saveAdvance(updated);
    StorageService.saveAdvances(_advances);

    logActivity(
      title: 'Advance Record Updated',
      description: 'Updated advance for ${memberName.trim()} (₹${amount.toStringAsFixed(0)}, Category: ${category.displayName})',
      actionType: ActivityActionType.update,
      module: ActivityModule.advance,
      amount: amount,
      eventId: updated.eventId,
      referenceId: id,
    );

    notifyListeners();
  }

  void settleAdvance({
    required String advanceId,
    required double actualSpent,
    PaymentMode? settlementPaymentMode,
    String? billDetails,
    DateTime? settlementDate,
    String? receiptPhotoUrl,
  }) {
    final index = _advances.indexWhere((a) => a.id == advanceId);
    if (index == -1) return;

    final adv = _advances[index];
    final settleTime = settlementDate ?? DateTime.now();
    final returnAmount = actualSpent < adv.advanceAmount ? (adv.advanceAmount - actualSpent) : 0.0;
    final extraClaimAmount = actualSpent > adv.advanceAmount ? (actualSpent - adv.advanceAmount) : 0.0;
    final finalPaymentMode = settlementPaymentMode ?? adv.paymentMode;

    String? settlementInstId;
    final updatedInstallments = List<AdvanceInstallment>.from(adv.installments);
    if (extraClaimAmount > 0) {
      settlementInstId = _uuid.v4();
      updatedInstallments.add(
        AdvanceInstallment(
          id: settlementInstId,
          amount: extraClaimAmount,
          date: settleTime,
          paymentMode: finalPaymentMode,
          note: billDetails != null && billDetails.trim().isNotEmpty
              ? 'Final Settlement: ${billDetails.trim()}'
              : 'Final Settlement Balance Payment',
          recordedBy: cashierName,
        ),
      );
    }

    final newTotalAdvance = updatedInstallments.fold<double>(0.0, (sum, i) => sum + i.amount);
    final effectiveEventId = adv.eventId ?? _selectedEventId ?? (_events.isNotEmpty ? _events.first.id : null);

    final updatedAdv = adv.copyWith(
      status: 'Settled',
      advanceAmount: newTotalAdvance > 0 ? newTotalAdvance : actualSpent,
      actualSpent: actualSpent,
      returnAmount: returnAmount,
      extraClaimAmount: extraClaimAmount,
      dateSettled: settleTime,
      billDetails: billDetails,
      installments: updatedInstallments,
      eventId: effectiveEventId,
      receiptPhotoUrl: receiptPhotoUrl ?? adv.receiptPhotoUrl,
    );

    _advances[index] = updatedAdv;

    // Check existing expense vouchers for this advance
    final existingVouchersForAdv = _expenses.where((e) => e.advanceId == adv.id).toList();

    final notes = [
      if (billDetails != null && billDetails.trim().isNotEmpty) billDetails.trim(),
      'Advance Paid: ₹${adv.advanceAmount.toStringAsFixed(0)}',
      if (returnAmount > 0) 'Cash Returned to Cashier: ₹${returnAmount.toStringAsFixed(0)}',
      if (extraClaimAmount > 0) 'Final Settlement Payment: ₹${extraClaimAmount.toStringAsFixed(0)}',
    ].join(' • ');

    if (existingVouchersForAdv.isNotEmpty) {
      // Prior installments are already recorded in _expenses.
      // If extra balance was paid at settlement, record ONLY that extra payment in _expenses!
      if (extraClaimAmount > 0 && settlementInstId != null) {
        final settlementVoucher = ExpenseVoucher(
          id: _uuid.v4(),
          voucherNo: _nextVoucherNo(),
          payeeName: '${adv.memberName} (Final Settlement)',
          category: adv.category,
          amount: extraClaimAmount,
          paymentMode: finalPaymentMode,
          paidBy: cashierName,
          date: settleTime,
          description: notes,
          eventId: effectiveEventId,
          advanceId: adv.id,
          installmentId: settlementInstId,
          receiptPhotoUrl: receiptPhotoUrl ?? adv.receiptPhotoUrl,
        );
        _expenses.insert(0, settlementVoucher);
        FirestoreService.saveExpense(settlementVoucher);
      }
    } else {
      // Legacy advance with no prior vouchers in _expenses: record full actualSpent
      final newVoucher = ExpenseVoucher(
        id: _uuid.v4(),
        voucherNo: _nextVoucherNo(),
        payeeName: '${adv.memberName} (Advance Settled)',
        category: adv.category,
        amount: actualSpent,
        paymentMode: finalPaymentMode,
        paidBy: cashierName,
        date: settleTime,
        description: notes,
        eventId: effectiveEventId,
        advanceId: adv.id,
        receiptPhotoUrl: receiptPhotoUrl ?? adv.receiptPhotoUrl,
      );
      _expenses.insert(0, newVoucher);
      FirestoreService.saveExpense(newVoucher);
    }

    FirestoreService.saveAdvance(updatedAdv);
    StorageService.saveAdvances(_advances);
    StorageService.saveExpenses(_expenses);

    logActivity(
      title: 'Advance Settled & Cleared',
      description: 'Settled advance for ${adv.memberName}: Actual Spent ₹${actualSpent.toStringAsFixed(0)}${returnAmount > 0 ? " • Cash Refunded: ₹${returnAmount.toStringAsFixed(0)}" : ""}${extraClaimAmount > 0 ? " • Extra Paid: ₹${extraClaimAmount.toStringAsFixed(0)}" : ""}',
      actionType: ActivityActionType.settle,
      module: ActivityModule.advance,
      amount: actualSpent,
      eventId: effectiveEventId,
      referenceId: advanceId,
    );

    notifyListeners();
  }

  void deleteAdvance(String id) {
    final advIndex = _advances.indexWhere((a) => a.id == id);
    if (advIndex == -1) return;
    final adv = _advances[advIndex];

    _advances.removeAt(advIndex);

    // Also delete any expense vouchers associated with this advance
    final toDelete = _expenses.where((e) => e.advanceId == id).toList();
    for (final exp in toDelete) {
      FirestoreService.deleteExpense(exp.id);
    }
    _expenses.removeWhere((e) => e.advanceId == id);

    FirestoreService.deleteAdvance(id);
    StorageService.saveAdvances(_advances);
    StorageService.saveExpenses(_expenses);

    logActivity(
      title: 'Advance Record Deleted',
      description: 'Deleted advance record of ${adv.memberName} (₹${adv.advanceAmount.toStringAsFixed(0)})',
      actionType: ActivityActionType.delete,
      module: ActivityModule.advance,
      amount: adv.advanceAmount,
      eventId: adv.eventId,
      referenceId: id,
    );

    notifyListeners();
  }

  void updateChandaSlip({
    required String slipId,
    required String donorName,
    String? phone,
    String? address,
    required double amount,
    required PaymentMode paymentMode,
    String? collectedBy,
    String? notes,
    String? dayLabel,
    int slipsCount = 1,
    int? slipNumber,
    int? bookNumber,
  }) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final old = _slips[index];
    final finalSlipNo = slipNumber ?? old.slipNumber;
    final finalBookNo = bookNumber ?? old.bookNumber;

    final updated = old.copyWith(
      slipNumber: finalSlipNo,
      bookNumber: finalBookNo,
      donorName: donorName,
      phone: phone,
      address: address,
      amount: amount,
      paidAmount: old.isFullyPaid ? amount : (old.paidAmount > amount ? amount : old.paidAmount),
      paymentMode: paymentMode,
      collectedBy: collectedBy ?? old.collectedBy,
      notes: notes,
      dayLabel: dayLabel ?? old.dayLabel,
      slipsCount: slipsCount,
    );

    _slips[index] = updated;

    // Adjust the parent book's collected total and slips count
    final bookIndex = _books.indexWhere((b) => b.bookNumber == finalBookNo);
    ChandaBook bookToSave;
    if (bookIndex != -1) {
      final book = _books[bookIndex];
      final newTotal = book.totalCollected + (amount - old.amount);
      final newUsedSlips = book.usedSlips + (slipsCount - old.slipsCount);
      _books[bookIndex] = book.copyWith(
        totalCollected: newTotal < 0 ? 0.0 : newTotal,
        usedSlips: newUsedSlips < 0 ? 0 : newUsedSlips,
      );
      bookToSave = _books[bookIndex];
    } else {
      bookToSave = _createFallbackBook(updated);
      _books.add(bookToSave);
    }

    FirestoreService.saveSlip(updated, bookToSave);
    StorageService.saveSlips(_slips);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Collection Slip Updated',
      description: 'Updated Slip #$finalSlipNo for ${donorName.trim()} in Book #$finalBookNo (₹${amount.toStringAsFixed(0)})',
      actionType: ActivityActionType.update,
      module: ActivityModule.collection,
      amount: amount,
      performedBy: collectedBy ?? old.collectedBy,
      eventId: updated.eventId,
      referenceId: slipId,
    );

    notifyListeners();
  }

  ChandaBook _createFallbackBook(ChandaSlip slip) {
    return ChandaBook(
      id: _uuid.v4(),
      bookNumber: slip.bookNumber,
      assignedTo: slip.collectedBy,
      startSlip: 1,
      endSlip: 100,
      totalSlips: 100,
      usedSlips: slip.slipsCount,
      totalCollected: slip.amount,
    );
  }

  void deleteChandaSlip(String slipId) {
    final index = _slips.indexWhere((s) => s.id == slipId);
    if (index == -1) return;

    final slip = _slips[index];
    _slips.removeAt(index);

    // Reflect removal in the parent book totals
    final bookIndex = _books.indexWhere((b) => b.bookNumber == slip.bookNumber);
    if (bookIndex != -1) {
      final book = _books[bookIndex];
      final newUsed = book.usedSlips >= slip.slipsCount ? (book.usedSlips - slip.slipsCount) : 0;
      final newTotal = book.totalCollected - slip.amount;
      _books[bookIndex] = book.copyWith(
        usedSlips: newUsed,
        totalCollected: newTotal < 0 ? 0.0 : newTotal,
      );
      FirestoreService.saveBook(_books[bookIndex]);
    }

    FirestoreService.deleteSlip(slip.id);
    StorageService.saveSlips(_slips);
    StorageService.saveBooks(_books);

    logActivity(
      title: 'Collection Slip Deleted',
      description: 'Deleted slip #${slip.slipNumber} of ${slip.donorName} (₹${slip.amount.toStringAsFixed(0)})',
      actionType: ActivityActionType.delete,
      module: ActivityModule.collection,
      amount: slip.amount,
      eventId: slip.eventId,
      referenceId: slipId,
    );

    notifyListeners();
  }
}
