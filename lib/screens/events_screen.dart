import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass_container.dart';
import '../widgets/responsive_layout.dart';
import 'chanda_books_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String? _openedEventId;
  String _searchQuery = '';
  String _selectedStatusFilter = 'All'; // 'All', 'Active', 'Synced'

  @override
  Widget build(BuildContext context) {
    // If an event is opened, show that event's dedicated workspace
    if (_openedEventId != null) {
      return ChandaBooksScreen(
        initialEventId: _openedEventId,
        onBackToEvents: () {
          setState(() {
            _openedEventId = null;
          });
        },
      );
    }

    final provider = Provider.of<PujaProvider>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final events = provider.events;

    // Filter events
    final filteredEvents = events.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.name.toLowerCase().contains(_searchQuery.toLowerCase().trim()) ||
          e.year.toString().contains(_searchQuery.trim());

      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Active') {
        matchesStatus = e.status.toLowerCase() == 'active';
      } else if (_selectedStatusFilter == 'Synced') {
        matchesStatus = e.isSynced;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    // Committee aggregate financial metrics (only synced events)
    final totalCollectedSynced = provider.totalIncome;
    final totalExpenseSynced = provider.totalExpense;
    final totalNetSynced = provider.netBalance;
    final syncedCount = events.where((e) => e.isSynced).length;

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final hPadding = isDesktop ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. TOP HEADER (Fixed Height: 50px)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPadding, 14, hPadding, 8),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withAlpha(50),
                              AppTheme.goldAccent.withAlpha(35),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: const Icon(Icons.festival_rounded, color: AppTheme.goldAccent, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Festivals & Events',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Events Hub • Chanda & Expenses',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white60,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // + Create Event Button (Fixed Height: 36px)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: const Color(0xFF070D1E),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF070D1E)),
                          label: const Text(
                            'Create Event',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CreateEditEventDialog(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. TOTAL COMMITTEE BALANCE SUMMARY CARD (Fixed Proportions)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 4),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      SizedBox(
                        height: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_rounded, size: 12, color: AppTheme.primaryBlue),
                                SizedBox(width: 6),
                                Text(
                                  'TOTAL COMMITTEE NET BALANCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryBlue,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withAlpha(20)),
                              ),
                              child: Text(
                                '$syncedCount of ${events.length} Synced',
                                style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3 KPI Columns in a fixed 46px row
                      SizedBox(
                        height: 46,
                        child: Row(
                          children: [
                            _buildSummaryKpi(
                              title: 'Synced Chanda',
                              value: currency.format(totalCollectedSynced),
                              color: AppTheme.successGreen,
                            ),
                            Container(width: 1, height: 30, color: Colors.white.withAlpha(20)),
                            _buildSummaryKpi(
                              title: 'Synced Expenses',
                              value: currency.format(totalExpenseSynced),
                              color: AppTheme.warningAmber,
                            ),
                            Container(width: 1, height: 30, color: Colors.white.withAlpha(20)),
                            _buildSummaryKpi(
                              title: 'Total Net Balance',
                              value: currency.format(totalNetSynced),
                              color: totalNetSynced >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. SEARCH & FILTER TOOLBAR (Fixed Height: 40px)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPadding, 8, hPadding, 8),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      // Search Input
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0x1F1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.glassBorder),
                          ),
                          child: TextField(
                            style: const TextStyle(fontSize: 12.5, color: Colors.white),
                            onChanged: (val) => setState(() => _searchQuery = val),
                            decoration: InputDecoration(
                              hintText: 'Search festival name or year...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.white.withAlpha(120)),
                              prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppTheme.primaryBlue),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 15, color: Colors.white60),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filter Segment
                      Container(
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0x1F1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Row(
                          children: ['All', 'Active', 'Synced'].map((status) {
                            final isSel = _selectedStatusFilter == status;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedStatusFilter = status),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel ? AppTheme.primaryBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                                    color: isSel ? const Color(0xFF070D1E) : Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4. EVENTS LIST / GRID
            if (filteredEvents.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: GlassContainer(
                    borderRadius: 22,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.goldAccent.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.festival_outlined, size: 40, color: AppTheme.goldAccent),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _searchQuery.isNotEmpty ? 'No Matching Events' : 'No Events Created Yet',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching with a different keyword.'
                              : 'Create your first event like Durga Puja, Lakshmi Puja, or Kali Puja.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(150), height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldAccent,
                            foregroundColor: const Color(0xFF070D1E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Create Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const CreateEditEventDialog(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossCount = screenWidth > 1750 ? 4 : (screenWidth > 1200 ? 3 : 2);

                  return SliverPadding(
                    padding: EdgeInsets.fromLTRB(hPadding, 4, hPadding, isDesktop ? 24 : 95),
                    sliver: isDesktop
                        ? SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildStructuredEventCard(context, provider, filteredEvents[index], currency),
                              childCount: filteredEvents.length,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildStructuredEventCard(context, provider, filteredEvents[index], currency),
                              ),
                              childCount: filteredEvents.length,
                            ),
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryKpi({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withAlpha(150),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// PROPER STRUCTURED EVENT CARD (Fixed proportions, zero overflow, 3-line menu)
  Widget _buildStructuredEventCard(
    BuildContext context,
    PujaProvider provider,
    PujaEvent event,
    NumberFormat currency,
  ) {
    final isSelected = provider.selectedEventId == event.id;
    final collected = provider.getEventCollected(event.id);
    final expense = provider.getEventExpense(event.id);
    final netBalance = provider.getEventNetBalance(event.id);
    final donorCount = provider.getEventDonorCount(event.id);
    final inKindCount = provider.getEventInKindCount(event.id);
    final pendingAdvance = provider.getEventPendingAdvance(event.id);

    final targetBudget = event.targetBudget ?? 0.0;
    final double budgetProgress = targetBudget > 0 ? (collected / targetBudget).clamp(0.0, 1.0) : 0.0;

    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      border: Border.all(
        color: isSelected ? AppTheme.primaryBlue.withAlpha(140) : AppTheme.glassBorder,
        width: isSelected ? 1.6 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ----------------------------------------------------
          // ROW 1: HEADER (Fixed Height: 40px)
          // ----------------------------------------------------
          SizedBox(
            height: 40,
            child: Row(
              children: [
                // Event Icon (36x36)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isSelected ? AppTheme.primaryBlue.withAlpha(60) : const Color(0x1F1E293B),
                        AppTheme.goldAccent.withAlpha(30),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.glassBorder),
                  ),
                  child: Icon(
                    Icons.festival_rounded,
                    color: isSelected ? AppTheme.primaryBlue : AppTheme.goldAccent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Badges
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              event.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${event.year}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            event.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: event.status.toLowerCase() == 'active' ? AppTheme.successGreen : Colors.white60,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withAlpha(80),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            event.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            size: 11,
                            color: event.isSynced ? AppTheme.successGreen : Colors.white38,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            event.isSynced ? 'SYNCED' : 'UNSYNCED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: event.isSynced ? AppTheme.successGreen : Colors.white54,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withAlpha(80),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'CURRENT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // 3-LINES ("chota bra") POPUP MENU BUTTON (Sync, Edit, Delete)
                _buildThreeLineMenuButton(context, provider, event),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // ROW 2: 3 KPI TILES (Fixed Height: 54px)
          // ----------------------------------------------------
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1F1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                _buildKpiTile(
                  label: 'Collected',
                  value: currency.format(collected),
                  color: AppTheme.successGreen,
                ),
                Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                _buildKpiTile(
                  label: 'Expenses',
                  value: currency.format(expense),
                  color: AppTheme.warningAmber,
                ),
                Container(width: 1, height: 26, color: Colors.white.withAlpha(20)),
                _buildKpiTile(
                  label: 'Net Balance',
                  value: currency.format(netBalance),
                  color: netBalance >= 0 ? AppTheme.goldAccent : AppTheme.dangerRose,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ----------------------------------------------------
          // ROW 3: META & BUDGET PROGRESS (Fixed Height: 20px)
          // ----------------------------------------------------
          SizedBox(
            height: 20,
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, size: 13, color: Colors.white.withAlpha(160)),
                const SizedBox(width: 4),
                Text(
                  '$donorCount Donors',
                  style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(170), fontWeight: FontWeight.w500),
                ),
                if (inKindCount > 0) ...[
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 10)),
                  const SizedBox(width: 8),
                  Icon(Icons.card_giftcard_rounded, size: 13, color: AppTheme.goldAccent.withAlpha(200)),
                  const SizedBox(width: 4),
                  Text(
                    '$inKindCount Samagri',
                    style: const TextStyle(fontSize: 11, color: AppTheme.goldAccent, fontWeight: FontWeight.w600),
                  ),
                ],
                if (pendingAdvance > 0) ...[
                  const SizedBox(width: 8),
                  Text('•', style: TextStyle(color: Colors.white.withAlpha(80), fontSize: 10)),
                  const SizedBox(width: 8),
                  const Icon(Icons.wallet_rounded, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 4),
                  Text(
                    'Adv: ${currency.format(pendingAdvance)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                  ),
                ],
                const Spacer(),
                if (targetBudget > 0) ...[
                  Text(
                    'Budget: ${(budgetProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 50,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: budgetProgress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withAlpha(20),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.goldAccent),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ----------------------------------------------------
          // ROW 4: FIXED ACTION DOCK (Fixed Height: 36px)
          // ----------------------------------------------------
          SizedBox(
            height: 36,
            child: Row(
              children: [
                // 1. + Collection A/C
                Expanded(
                  flex: 12,
                  child: _buildActionBtn(
                    label: '+ Collection A/C',
                    icon: Icons.account_balance_rounded,
                    color: AppTheme.successGreen,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddCollectionAccountDialog(
                          initialEventId: event.id,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // 2. + Expenditure A/C
                Expanded(
                  flex: 12,
                  child: _buildActionBtn(
                    label: '+ Expenditure A/C',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.dangerRose,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddExpenditureAccountDialog(initialEventId: event.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // 3. + Advance
                Expanded(
                  flex: 11,
                  child: _buildActionBtn(
                    label: '+ Advance',
                    icon: Icons.wallet_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => GiveAdvanceDialog(initialEventId: event.id),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),

                // 4. Open ➔ (Primary Button)
                Expanded(
                  flex: 9,
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 2,
                      ),
                      onPressed: () {
                        provider.selectEvent(event.id);
                        setState(() {
                          _openedEventId = event.id;
                        });
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Open', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3-LINES ("chota bra") POPUP MENU BUTTON (Sync, Edit, Delete)
  Widget _buildThreeLineMenuButton(
    BuildContext context,
    PujaProvider provider,
    PujaEvent event,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(
        cardColor: const Color(0xFF131D31),
        popupMenuTheme: PopupMenuThemeData(
          color: const Color(0xFF131D31),
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x334FC3F7), width: 1.2),
          ),
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Festival Options',
        offset: const Offset(0, 38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x334FC3F7), width: 1.2),
        ),
        color: const Color(0xFF131D31),
        elevation: 12,
        onSelected: (value) {
          if (value == 'sync') {
            provider.toggleEventSync(event.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      !event.isSynced ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      color: !event.isSynced ? AppTheme.successGreen : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !event.isSynced
                            ? '${event.name} is now synced to Committee Total Net Balance!'
                            : '${event.name} removed from Committee Total Net Balance.',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF162032),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (value == 'pdf') {
            showDialog(
              context: context,
              builder: (_) => EventPdfExportDialog(event: event),
            );
          } else if (value == 'advance') {
            showDialog(
              context: context,
              builder: (_) => GiveAdvanceDialog(initialEventId: event.id),
            );
          } else if (value == 'edit') {
            showDialog(
              context: context,
              builder: (_) => CreateEditEventDialog(existing: event),
            );
          } else if (value == 'delete') {
            _confirmDeleteEvent(context, provider, event);
          }
        },
        itemBuilder: (ctx) => [
          // 1. SYNC / UNSYNC OPTION
          PopupMenuItem<String>(
            value: 'sync',
            height: 52,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (event.isSynced ? AppTheme.successGreen : AppTheme.warningAmber).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    event.isSynced ? Icons.cloud_done_rounded : Icons.sync_rounded,
                    size: 17,
                    color: event.isSynced ? AppTheme.successGreen : AppTheme.warningAmber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.isSynced ? 'Synced to Net' : 'Sync to Net',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: event.isSynced ? AppTheme.successGreen : Colors.white,
                        ),
                      ),
                      Text(
                        event.isSynced ? 'Included in Committee Total' : 'Tap to add to Committee Total',
                        style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(140)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: (event.isSynced ? AppTheme.successGreen : AppTheme.warningAmber).withAlpha(35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (event.isSynced ? AppTheme.successGreen : AppTheme.warningAmber).withAlpha(120),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    event.isSynced ? 'SYNCED' : 'OFF',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: event.isSynced ? AppTheme.successGreen : AppTheme.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),

          // 2. EXPORT PDF STATEMENT OPTION
          PopupMenuItem<String>(
            value: 'pdf',
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, size: 17, color: Color(0xFFFB7185)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Export PDF Statement',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        'Statement, Chanda, Expenses, Advances',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),

          // 3. GIVE ADVANCE OPTION
          PopupMenuItem<String>(
            value: 'advance',
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.wallet_rounded, size: 17, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Give Advance',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        'Handover cash advance to member',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),

          // 2. EDIT EVENT OPTION
          PopupMenuItem<String>(
            value: 'edit',
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0x264FC3F7),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Icon(Icons.edit_outlined, size: 17, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Festival',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      Text(
                        'Update festival name, year, budget',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const PopupMenuDivider(height: 1),

          // 3. DELETE EVENT OPTION
          PopupMenuItem<String>(
            value: 'delete',
            height: 48,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0x26FB7185),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 17, color: AppTheme.dangerRose),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Delete Festival',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.dangerRose),
                      ),
                      Text(
                        'Permanently remove event and data',
                        style: TextStyle(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        // The 3 horizontal lines ("chota bra") icon button
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white.withAlpha(25)),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 17,
                height: 2.2,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 3.5),
              Container(
                width: 10,
                height: 2.2,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 3.5),
              Container(
                width: 14,
                height: 2.2,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(230),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(140)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(90), width: 1.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, PujaProvider provider, PujaEvent event) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRose, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'Delete ${event.name} (${event.year})?',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to remove this festival event? Existing slips and expenses linked to it will remain safe in records.',
                style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(160), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: AppTheme.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerRose,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        provider.deleteEvent(event.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${event.name} deleted successfully.'),
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                        );
                      },
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
