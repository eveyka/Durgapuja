import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _searchQuery = '';
  ActivityModule? _selectedModule;
  ActivityActionType? _selectedActionType;
  String _timeFilter = 'all'; // 'all', 'today', 'yesterday', 'week', 'month'
  DateTime? _customSelectedDate;
  bool _sortAscending = false;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AuditActivityLog> _filterLogs(List<AuditActivityLog> logs) {
    final now = DateTime.now();

    return logs.where((log) {
      // 1. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = log.title.toLowerCase().contains(query);
        final matchDesc = log.description.toLowerCase().contains(query);
        final matchActor = log.performedBy.toLowerCase().contains(query);
        final matchEvent = (log.eventName ?? '').toLowerCase().contains(query);
        final matchAmount = log.amount != null && log.amount.toString().contains(query);
        if (!matchTitle && !matchDesc && !matchActor && !matchEvent && !matchAmount) {
          return false;
        }
      }

      // 2. Module Filter
      if (_selectedModule != null && log.module != _selectedModule) {
        return false;
      }

      // 3. Action Type Filter
      if (_selectedActionType != null && log.actionType != _selectedActionType) {
        return false;
      }

      // 4. Time Filter
      final logDate = log.timestamp;
      if (_customSelectedDate != null) {
        if (logDate.year != _customSelectedDate!.year ||
            logDate.month != _customSelectedDate!.month ||
            logDate.day != _customSelectedDate!.day) {
          return false;
        }
      } else {
        switch (_timeFilter) {
          case 'today':
            if (logDate.year != now.year || logDate.month != now.month || logDate.day != now.day) {
              return false;
            }
            break;
          case 'yesterday':
            final yesterday = now.subtract(const Duration(days: 1));
            if (logDate.year != yesterday.year || logDate.month != yesterday.month || logDate.day != yesterday.day) {
              return false;
            }
            break;
          case 'week':
            final weekAgo = now.subtract(const Duration(days: 7));
            if (logDate.isBefore(weekAgo)) {
              return false;
            }
            break;
          case 'month':
            final monthAgo = now.subtract(const Duration(days: 30));
            if (logDate.isBefore(monthAgo)) {
              return false;
            }
            break;
          case 'all':
          default:
            break;
        }
      }

      return true;
    }).toList()
      ..sort((a, b) => _sortAscending
          ? a.timestamp.compareTo(b.timestamp)
          : b.timestamp.compareTo(a.timestamp));
  }

  void _copyFilteredLogsAsCSV(List<AuditActivityLog> logs) {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No activity logs found to export.'),
          backgroundColor: AppTheme.dangerRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Title,Action,Module,Amount,Actor,Event,Description');

    final df = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final log in logs) {
      final amt = log.amount != null ? '₹${log.amount!.toStringAsFixed(0)}' : '-';
      final evt = log.eventName ?? 'General';
      final safeDesc = log.description.replaceAll('"', '""');
      buffer.writeln(
        '"${df.format(log.timestamp)}","${log.title}","${log.actionType.displayName}","${log.module.displayName}","$amt","${log.performedBy}","$evt","$safeDesc"',
      );
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
            const SizedBox(width: 10),
            Text(
              '${logs.length} activity records copied to clipboard in CSV format!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final allLogs = provider.activityLogs;
    final filteredLogs = _filterLogs(allLogs);

    return ResponsiveLayout(
      mobile: _buildMobileHistory(context, provider, allLogs, filteredLogs),
      desktop: _buildDesktopHistory(context, provider, allLogs, filteredLogs),
    );
  }

  // ==========================================
  // MOBILE VIEW
  // ==========================================
  Widget _buildMobileHistory(
    BuildContext context,
    PujaProvider provider,
    List<AuditActivityLog> allLogs,
    List<AuditActivityLog> filteredLogs,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xF50A1128),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: AppTheme.goldAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Recent History',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
            onPressed: () => _copyFilteredLogsAsCSV(filteredLogs),
          ),
          IconButton(
            tooltip: 'Sort order',
            icon: Icon(
              _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () => setState(() => _sortAscending = !_sortAscending),
          ),
        ],
      ),
      body: Column(
        children: [
          // KPI Metric Bar
          _buildMobileKpiRow(allLogs, filteredLogs),

          // Search & Filter Bar
          _buildMobileFilterSection(),

          // Timeline Log List
          Expanded(
            child: filteredLogs.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final log = filteredLogs[idx];
                      return _buildActivityCard(context, log, isMobile: true);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKpiRow(List<AuditActivityLog> allLogs, List<AuditActivityLog> filteredLogs) {
    final today = DateTime.now();
    final todayCount = allLogs.where((l) =>
        l.timestamp.year == today.year &&
        l.timestamp.month == today.month &&
        l.timestamp.day == today.day).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        border: Border(bottom: BorderSide(color: AppTheme.glassBorderLight.withAlpha(40))),
      ),
      child: Row(
        children: [
          _buildMiniKpiBadge('Total Records', '${allLogs.length}', AppTheme.primaryBlue),
          const SizedBox(width: 8),
          _buildMiniKpiBadge("Today's Actions", '$todayCount', AppTheme.goldAccent),
          const SizedBox(width: 8),
          _buildMiniKpiBadge('Filtered', '${filteredLogs.length}', AppTheme.successGreen),
        ],
      ),
    );
  }

  Widget _buildMiniKpiBadge(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(160), fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0x140F172A),
        border: Border(bottom: BorderSide(color: AppTheme.glassBorderLight.withAlpha(30))),
      ),
      child: Column(
        children: [
          // Search Input
          SizedBox(
            height: 38,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 12.5, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search donor, member, account, voucher, slip...',
                hintStyle: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(130)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white60),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.white70),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: const Color(0x1F1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.2)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Scrollable Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Module Filter Dropdown Chip
                _buildFilterDropdownChip<ActivityModule?>(
                  label: _selectedModule == null ? 'All Modules' : _selectedModule!.displayName,
                  icon: _selectedModule?.icon ?? Icons.category_rounded,
                  color: _selectedModule?.color ?? AppTheme.primaryBlue,
                  isActive: _selectedModule != null,
                  onTap: () => _showModuleSelectSheet(context),
                  onClear: _selectedModule != null ? () => setState(() => _selectedModule = null) : null,
                ),
                const SizedBox(width: 8),

                // Action Filter Chip
                _buildFilterDropdownChip<ActivityActionType?>(
                  label: _selectedActionType == null ? 'All Actions' : _selectedActionType!.displayName,
                  icon: _selectedActionType?.icon ?? Icons.flash_on_rounded,
                  color: _selectedActionType?.color ?? AppTheme.goldAccent,
                  isActive: _selectedActionType != null,
                  onTap: () => _showActionTypeSelectSheet(context),
                  onClear: _selectedActionType != null ? () => setState(() => _selectedActionType = null) : null,
                ),
                const SizedBox(width: 8),

                // Time Filter Chip
                _buildFilterDropdownChip<String>(
                  label: _customSelectedDate != null
                      ? DateFormat('dd MMM yyyy').format(_customSelectedDate!)
                      : _getTimeFilterLabel(_timeFilter),
                  icon: Icons.calendar_today_rounded,
                  color: AppTheme.deepAccent,
                  isActive: _timeFilter != 'all' || _customSelectedDate != null,
                  onTap: () => _showTimeFilterSheet(context),
                  onClear: (_timeFilter != 'all' || _customSelectedDate != null)
                      ? () => setState(() {
                            _timeFilter = 'all';
                            _customSelectedDate = null;
                          })
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP VIEW
  // ==========================================
  Widget _buildDesktopHistory(
    BuildContext context,
    PujaProvider provider,
    List<AuditActivityLog> allLogs,
    List<AuditActivityLog> filteredLogs,
  ) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final today = DateTime.now();

    final todayLogs = allLogs.where((l) =>
        l.timestamp.year == today.year &&
        l.timestamp.month == today.month &&
        l.timestamp.day == today.day).toList();

    double totalVolume = 0.0;
    for (final l in filteredLogs) {
      if (l.amount != null) totalVolume += l.amount!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.deepAccent]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryBlue.withAlpha(80), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Trail & Recent Activity History',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.3),
                    ),
                    Text(
                      'Comprehensive systematic timeline of all Accounts, Collections, Dues, Advances, and Expenses',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.glassBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.download_rounded, size: 16, color: AppTheme.primaryBlue),
                label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _copyFilteredLogsAsCSV(filteredLogs),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Desktop Top KPI Metric Cards Grid
          Row(
            children: [
              _buildDesktopStatCard(
                title: 'Total Tracked Actions',
                value: '${allLogs.length}',
                subtitle: 'Full historical audit trail',
                icon: Icons.receipt_long_rounded,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 16),
              _buildDesktopStatCard(
                title: "Today's Logged Actions",
                value: '${todayLogs.length}',
                subtitle: 'Active modifications today',
                icon: Icons.today_rounded,
                color: AppTheme.goldAccent,
              ),
              const SizedBox(width: 16),
              _buildDesktopStatCard(
                title: 'Filtered Records',
                value: '${filteredLogs.length}',
                subtitle: '${allLogs.length - filteredLogs.length} filtered out',
                icon: Icons.filter_alt_rounded,
                color: AppTheme.successGreen,
              ),
              const SizedBox(width: 16),
              _buildDesktopStatCard(
                title: 'Tracked Volume',
                value: currency.format(totalVolume),
                subtitle: 'Financial movement in filtered logs',
                icon: Icons.account_balance_wallet_rounded,
                color: AppTheme.deepAccent,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Systematic Desktop Filter Toolbar Card
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          style: const TextStyle(fontSize: 12.5, color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search by title, description, donor, payee, slip#, voucher#, cashier...',
                            hintStyle: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(130)),
                            prefixIcon: const Icon(Icons.search_rounded, size: 17, color: Colors.white60),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.white70),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                            filled: true,
                            fillColor: const Color(0x1F1E293B),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.2)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Module Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ActivityModule?>(
                          value: _selectedModule,
                          dropdownColor: const Color(0xFF0F172A),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60, size: 18),
                          hint: const Row(
                            children: [
                              Icon(Icons.category_rounded, size: 15, color: Colors.white60),
                              SizedBox(width: 6),
                              Text('All Modules', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Modules', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            ...ActivityModule.values.map((mod) => DropdownMenuItem(
                                  value: mod,
                                  child: Row(
                                    children: [
                                      Icon(mod.icon, size: 14, color: mod.color),
                                      const SizedBox(width: 8),
                                      Text(mod.displayName, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (val) => setState(() => _selectedModule = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Action Type Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ActivityActionType?>(
                          value: _selectedActionType,
                          dropdownColor: const Color(0xFF0F172A),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60, size: 18),
                          hint: const Row(
                            children: [
                              Icon(Icons.flash_on_rounded, size: 15, color: Colors.white60),
                              SizedBox(width: 6),
                              Text('All Actions', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            ...ActivityActionType.values.map((act) => DropdownMenuItem(
                                  value: act,
                                  child: Row(
                                    children: [
                                      Icon(act.icon, size: 14, color: act.color),
                                      const SizedBox(width: 8),
                                      Text(act.displayName, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                )),
                          ],
                          onChanged: (val) => setState(() => _selectedActionType = val),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Time Filter Dropdown
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x1F1E293B),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _customSelectedDate != null ? 'custom' : _timeFilter,
                          dropdownColor: const Color(0xFF0F172A),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white60, size: 18),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All Time', style: TextStyle(fontSize: 12))),
                            const DropdownMenuItem(value: 'today', child: Text('Today Only', style: TextStyle(fontSize: 12))),
                            const DropdownMenuItem(value: 'yesterday', child: Text('Yesterday', style: TextStyle(fontSize: 12))),
                            const DropdownMenuItem(value: 'week', child: Text('Last 7 Days', style: TextStyle(fontSize: 12))),
                            const DropdownMenuItem(value: 'month', child: Text('Last 30 Days', style: TextStyle(fontSize: 12))),
                            if (_customSelectedDate != null)
                              DropdownMenuItem(
                                value: 'custom',
                                child: Text('Custom: ${DateFormat("dd MMM yyyy").format(_customSelectedDate!)}', style: const TextStyle(fontSize: 12)),
                              ),
                          ],
                          onChanged: (val) {
                            if (val != null && val != 'custom') {
                              setState(() {
                                _timeFilter = val;
                                _customSelectedDate = null;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Custom Date Picker Icon
                    IconButton(
                      tooltip: 'Select Custom Date',
                      icon: Icon(
                        Icons.date_range_rounded,
                        color: _customSelectedDate != null ? AppTheme.goldAccent : Colors.white70,
                        size: 20,
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _customSelectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppTheme.primaryBlue,
                                  surface: Color(0xFF0F172A),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _customSelectedDate = picked;
                            _timeFilter = 'custom';
                          });
                        }
                      },
                    ),

                    // Clear Filters Button
                    if (_selectedModule != null || _selectedActionType != null || _timeFilter != 'all' || _customSelectedDate != null || _searchQuery.isNotEmpty)
                      IconButton(
                        tooltip: 'Reset Filters',
                        icon: const Icon(Icons.filter_alt_off_rounded, color: AppTheme.dangerRose, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedModule = null;
                            _selectedActionType = null;
                            _timeFilter = 'all';
                            _customSelectedDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Desktop Timeline Feed
          if (filteredLogs.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final log = filteredLogs[idx];
                return _buildActivityCard(context, log, isMobile: false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xF50A1128),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.glassBorderLight.withAlpha(60)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(90), blurRadius: 12, offset: const Offset(2, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withAlpha(70)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(160), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(120)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SHARED TIMELINE CARD
  // ==========================================
  Widget _buildActivityCard(BuildContext context, AuditActivityLog log, {required bool isMobile}) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showActivityDetailsDialog(context, log),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: const Color(0xF50A1128),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: log.color.withAlpha(50),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 8,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge with Glow
              Container(
                width: isMobile ? 38 : 44,
                height: isMobile ? 38 : 44,
                decoration: BoxDecoration(
                  color: log.color.withAlpha(25),
                  shape: BoxShape.circle,
                  border: Border.all(color: log.color.withAlpha(90), width: 1.2),
                ),
                child: Icon(log.icon, color: log.color, size: isMobile ? 18 : 22),
              ),
              const SizedBox(width: 12),

              // Middle Description & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Title + Action Tag + Time
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  log.title,
                                  style: TextStyle(
                                    fontSize: isMobile ? 13.5 : 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildActionBadge(log.actionType),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Time Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            log.timeAgo,
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color: Colors.white.withAlpha(160),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Description text
                    Text(
                      log.description,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: Colors.white.withAlpha(200),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Bottom Metadata Row: Module Pill, Performed By, Amount
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Module Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: log.module.color.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: log.module.color.withAlpha(80), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(log.module.icon, size: 11, color: log.module.color),
                              const SizedBox(width: 4),
                              Text(
                                log.module.displayName,
                                style: TextStyle(fontSize: 10, color: log.module.color, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        // Actor
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_rounded, size: 12, color: Colors.white.withAlpha(140)),
                            const SizedBox(width: 4),
                            Text(
                              log.performedBy,
                              style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(160)),
                            ),
                          ],
                        ),

                        // Event Name
                        if (log.eventName != null && log.eventName!.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.festival_rounded, size: 12, color: AppTheme.goldAccent.withAlpha(160)),
                              const SizedBox(width: 4),
                              Text(
                                log.eventName!,
                                style: TextStyle(fontSize: 10.5, color: AppTheme.goldAccent.withAlpha(180)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount Badge on the Right (if present)
              if (log.amount != null && log.amount! > 0) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency.format(log.amount),
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w900,
                        color: log.actionType == ActivityActionType.delete
                            ? AppTheme.dangerRose
                            : (log.module == ActivityModule.expense ? AppTheme.dangerRose : AppTheme.successGreen),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.actionType == ActivityActionType.delete ? 'REMOVED' : 'AMOUNT',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white.withAlpha(100)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBadge(ActivityActionType action) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: action.color.withAlpha(25),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: action.color.withAlpha(90), width: 0.8),
      ),
      child: Text(
        action.displayName.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: action.color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildFilterDropdownChip<T>({
    required String label,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(35) : const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? color.withAlpha(120) : AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: isActive ? color : Colors.white70),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: const Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded, size: 36, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Activity Logs Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedModule != null || _selectedActionType != null || _timeFilter != 'all'
                  ? 'Try modifying your search or clearing active filters.'
                  : 'All recorded operations, collections, and updates will automatically appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(140)),
            ),
            if (_selectedModule != null || _selectedActionType != null || _timeFilter != 'all' || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: AppTheme.goldAccent),
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Reset All Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedModule = null;
                    _selectedActionType = null;
                    _timeFilter = 'all';
                    _customSelectedDate = null;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeFilterLabel(String key) {
    switch (key) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'week':
        return 'Last 7 Days';
      case 'month':
        return 'Last 30 Days';
      case 'all':
      default:
        return 'All Time';
    }
  }

  void _showModuleSelectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('Filter By Module', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded, color: Colors.white70),
                title: const Text('All Modules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: _selectedModule == null ? const Icon(Icons.check_rounded, color: AppTheme.primaryBlue) : null,
                onTap: () {
                  setState(() => _selectedModule = null);
                  Navigator.pop(ctx);
                },
              ),
              ...ActivityModule.values.map((mod) => ListTile(
                    leading: Icon(mod.icon, color: mod.color),
                    title: Text(mod.displayName, style: const TextStyle(color: Colors.white)),
                    trailing: _selectedModule == mod ? Icon(Icons.check_rounded, color: mod.color) : null,
                    onTap: () {
                      setState(() => _selectedModule = mod);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showActionTypeSelectSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('Filter By Action Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.all_inclusive_rounded, color: Colors.white70),
                title: const Text('All Actions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                trailing: _selectedActionType == null ? const Icon(Icons.check_rounded, color: AppTheme.goldAccent) : null,
                onTap: () {
                  setState(() => _selectedActionType = null);
                  Navigator.pop(ctx);
                },
              ),
              ...ActivityActionType.values.map((act) => ListTile(
                    leading: Icon(act.icon, color: act.color),
                    title: Text(act.displayName, style: const TextStyle(color: Colors.white)),
                    trailing: _selectedActionType == act ? Icon(Icons.check_rounded, color: act.color) : null,
                    onTap: () {
                      setState(() => _selectedActionType = act);
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showTimeFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        final options = [
          {'key': 'all', 'label': 'All Time'},
          {'key': 'today', 'label': 'Today Only'},
          {'key': 'yesterday', 'label': 'Yesterday'},
          {'key': 'week', 'label': 'Last 7 Days'},
          {'key': 'month', 'label': 'Last 30 Days'},
        ];

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text('Filter By Time Period', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const Divider(color: Colors.white10),
              ...options.map((opt) => ListTile(
                    leading: const Icon(Icons.calendar_month_rounded, color: Colors.white70),
                    title: Text(opt['label']!, style: const TextStyle(color: Colors.white)),
                    trailing: (_timeFilter == opt['key'] && _customSelectedDate == null)
                        ? const Icon(Icons.check_rounded, color: AppTheme.primaryBlue)
                        : null,
                    onTap: () {
                      setState(() {
                        _timeFilter = opt['key']!;
                        _customSelectedDate = null;
                      });
                      Navigator.pop(ctx);
                    },
                  )),
              ListTile(
                leading: const Icon(Icons.date_range_rounded, color: AppTheme.goldAccent),
                title: const Text('Pick Custom Date...', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _customSelectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() {
                      _customSelectedDate = picked;
                      _timeFilter = 'custom';
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showActivityDetailsDialog(BuildContext context, AuditActivityLog log) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: log.color.withAlpha(90), width: 1.2),
        ),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: log.color.withAlpha(25),
                      shape: BoxShape.circle,
                      border: Border.all(color: log.color.withAlpha(80)),
                    ),
                    child: Icon(log.icon, color: log.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          log.formattedDate,
                          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(150)),
                        ),
                      ],
                    ),
                  ),
                  _buildActionBadge(log.actionType),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Colors.white10),
              const SizedBox(height: 12),

              // Full Description
              Text(
                'Action Details:',
                style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(140), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x1F1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Text(
                  log.description,
                  style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Metadata Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile('Module', log.module.displayName, log.module.icon, log.module.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile('Operator', log.performedBy, Icons.person_rounded, Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile('Event', log.eventName ?? 'General', Icons.festival_rounded, AppTheme.goldAccent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDetailTile(
                      'Amount Involved',
                      log.amount != null ? currency.format(log.amount) : 'None',
                      Icons.payments_rounded,
                      log.amount != null ? AppTheme.successGreen : Colors.white38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0x1F1E293B),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppTheme.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Inspector', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(130), fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
