import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';

enum DesktopDensity { compact, standard, comfortable }

enum QuickEntryType { chanda, expense, advance }

class DesktopController extends ChangeNotifier {
  // Sidebar & Navigation
  bool _isSidebarCollapsed = false;
  int _activeTabIndex = 0;

  // Split-pane Master-Detail Inspector
  String? _selectedTransactionId;
  String? _selectedTransactionType; // 'donation', 'expense', 'advance'
  bool _isInspectorOpen = false;

  // Data Grid Settings
  DesktopDensity _density = DesktopDensity.standard;
  String _searchQuery = '';
  String _paymentFilter = 'All'; // 'All', 'Cash', 'Online/UPI', 'Bank'
  String _categoryFilter = 'All';
  String _sortColumn = 'date';
  bool _sortAscending = false;

  // Bulk Selection
  final Set<String> _selectedItemIds = {};

  // Fast POS Quick Entry Terminal Modal
  bool _isQuickEntryOpen = false;
  QuickEntryType _quickEntryType = QuickEntryType.chanda;

  // Search Focus Node
  final FocusNode searchFocusNode = FocusNode();

  // Getters
  bool get isSidebarCollapsed => _isSidebarCollapsed;
  int get activeTabIndex => _activeTabIndex;
  String? get selectedTransactionId => _selectedTransactionId;
  String? get selectedTransactionType => _selectedTransactionType;
  bool get isInspectorOpen => _isInspectorOpen;
  DesktopDensity get density => _density;
  String get searchQuery => _searchQuery;
  String get paymentFilter => _paymentFilter;
  String get categoryFilter => _categoryFilter;
  String get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;
  Set<String> get selectedItemIds => Set.unmodifiable(_selectedItemIds);
  bool get isQuickEntryOpen => _isQuickEntryOpen;
  QuickEntryType get quickEntryType => _quickEntryType;
  int get selectedCount => _selectedItemIds.length;

  double get rowHeight {
    switch (_density) {
      case DesktopDensity.compact:
        return 40.0;
      case DesktopDensity.standard:
        return 52.0;
      case DesktopDensity.comfortable:
        return 64.0;
    }
  }

  // Sidebar Controls
  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool collapsed) {
    _isSidebarCollapsed = collapsed;
    notifyListeners();
  }

  void setTab(int index) {
    _activeTabIndex = index;
    _selectedItemIds.clear();
    notifyListeners();
  }

  // Density
  void setDensity(DesktopDensity newDensity) {
    _density = newDensity;
    notifyListeners();
  }

  // Search & Filters
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    searchFocusNode.unfocus();
    notifyListeners();
  }

  void focusSearch() {
    searchFocusNode.requestFocus();
  }

  void setPaymentFilter(String filter) {
    _paymentFilter = filter;
    notifyListeners();
  }

  void setCategoryFilter(String filter) {
    _categoryFilter = filter;
    notifyListeners();
  }

  void setSorting(String column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = false; // default to descending on new column
    }
    notifyListeners();
  }

  // Master Detail Selection
  void selectTransaction(String id, String type) {
    if (_selectedTransactionId == id && _isInspectorOpen) {
      // Toggle off if already selected
      _isInspectorOpen = false;
      _selectedTransactionId = null;
      _selectedTransactionType = null;
    } else {
      _selectedTransactionId = id;
      _selectedTransactionType = type;
      _isInspectorOpen = true;
    }
    notifyListeners();
  }

  void closeInspector() {
    _isInspectorOpen = false;
    _selectedTransactionId = null;
    _selectedTransactionType = null;
    notifyListeners();
  }

  // Bulk Selection
  void toggleItemSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void selectAllItems(Iterable<String> ids) {
    _selectedItemIds.addAll(ids);
    notifyListeners();
  }

  void clearAllSelections() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  bool isItemSelected(String id) => _selectedItemIds.contains(id);

  // Quick POS Terminal Entry
  void openQuickEntry(QuickEntryType type) {
    _quickEntryType = type;
    _isQuickEntryOpen = true;
    notifyListeners();
  }

  void closeQuickEntry() {
    _isQuickEntryOpen = false;
    notifyListeners();
  }

  // Export Selected Transactions to CSV
  Future<void> exportSelectedToCSV(BuildContext context, PujaProvider provider) async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final buffer = StringBuffer();
    buffer.writeln('Type,ID/Number,Title/Payee,Category/Book,Payment Mode,Amount,Date,Status,Notes');

    final slips = provider.slips.where((s) => _selectedItemIds.contains(s.id));
    for (final s in slips) {
      buffer.writeln(
        'Donation,"${s.slipNumber}","${s.donorName}","Book ${s.bookNumber}","${s.paymentMode.name}","${s.amount}","${dateFormat.format(s.createdAt)}","${s.isFullyPaid ? "Paid" : "Due"}","${s.notes ?? ""}"',
      );
    }

    final expenses = provider.expenses.where((e) => _selectedItemIds.contains(e.id));
    for (final e in expenses) {
      buffer.writeln(
        'Expense,"${e.voucherNo}","${e.payeeName}","${e.category.displayName}","${e.paymentMode.name}","${e.amount}","${dateFormat.format(e.date)}","Approved","${e.description ?? ""}"',
      );
    }

    final advances = provider.advances.where((a) => _selectedItemIds.contains(a.id));
    for (final a in advances) {
      buffer.writeln(
        'Advance,"${a.id}","${a.memberName}","${a.category.displayName}","${a.paymentMode.name}","${a.advanceAmount}","${dateFormat.format(a.dateGiven)}","${a.status}","${a.purpose}"',
      );
    }

    final csvString = buffer.toString();
    await Clipboard.setData(ClipboardData(text: csvString));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
              const SizedBox(width: 10),
              Text(
                '${_selectedItemIds.length} items copied to clipboard in CSV format!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    super.dispose();
  }
}
