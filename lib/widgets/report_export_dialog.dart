import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/puja_provider.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class ReportExportDialog extends StatefulWidget {
  final PujaEvent? initialEvent;
  final bool initialAllEvents;

  const ReportExportDialog({
    super.key,
    this.initialEvent,
    this.initialAllEvents = true,
  });

  @override
  State<ReportExportDialog> createState() => _ReportExportDialogState();
}

class _ReportExportDialogState extends State<ReportExportDialog> {
  late bool _isAllEvents;
  PujaEvent? _selectedEvent;
  bool _isGenerating = false;
  String _loadingText = '';

  final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _isAllEvents = widget.initialEvent == null ? widget.initialAllEvents : false;
    _selectedEvent = widget.initialEvent;
  }

  PujaEvent? _resolveSelectedEvent(PujaProvider provider) {
    if (_selectedEvent != null) {
      final exists = provider.events.any((e) => e.id == _selectedEvent!.id);
      if (exists) {
        return provider.events.firstWhere((e) => e.id == _selectedEvent!.id);
      }
    }
    if (widget.initialEvent != null) {
      final exists = provider.events.any((e) => e.id == widget.initialEvent!.id);
      if (exists) {
        return provider.events.firstWhere((e) => e.id == widget.initialEvent!.id);
      }
    }
    if (provider.selectedEvent != null) {
      return provider.selectedEvent;
    }
    if (provider.events.isNotEmpty) {
      return provider.events.first;
    }
    return null;
  }

  Future<void> _handleAllEventsGenerate(
    PujaProvider provider, {
    required bool isLedger,
    required bool isShare,
  }) async {
    setState(() {
      _isGenerating = true;
      _loadingText = isShare
          ? 'Preparing consolidated statement to share...'
          : 'Generating printable consolidated statement...';
    });
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      if (isLedger) {
        if (isShare) {
          await PdfReportService.shareAllEventsLedgerReport(provider);
        } else {
          await PdfReportService.printAllEventsLedgerReport(provider);
        }
      } else {
        if (isShare) {
          await PdfReportService.shareAuditReport(provider);
        } else {
          await PdfReportService.printAuditReport(provider);
        }
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.dangerRose,
          ),
        );
      }
    }
  }

  Future<void> _handleSingleEventGenerate(
    PujaProvider provider,
    PujaEvent event,
    EventPdfReportType type, {
    required bool isShare,
  }) async {
    setState(() {
      _isGenerating = true;
      _loadingText = isShare
          ? 'Preparing ${event.name} PDF to share...'
          : 'Generating printable ${event.name} statement...';
    });
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      if (isShare) {
        await PdfReportService.shareEventReport(
          provider: provider,
          event: event,
          reportType: type,
        );
      } else {
        await PdfReportService.printEventReport(
          provider: provider,
          event: event,
          reportType: type,
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppTheme.dangerRose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final activeEvent = _resolveSelectedEvent(provider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        border: Border.all(color: const Color(0x33E11D48), width: 1.2),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withAlpha(80),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Export PDF Statements',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Choose scope: All Festivals combined or a Single Event',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withAlpha(160),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scope Selector Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0x1F0F172A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.glassBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildScopeTab(
                              title: 'All Events Combined',
                              subtitle: '${provider.events.length} Festivals',
                              icon: Icons.layers_rounded,
                              isSelected: _isAllEvents,
                              onTap: () => setState(() => _isAllEvents = true),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildScopeTab(
                              title: 'Single Event',
                              subtitle: activeEvent != null ? activeEvent.name : 'Select Event',
                              icon: Icons.festival_rounded,
                              isSelected: !_isAllEvents,
                              onTap: () => setState(() => _isAllEvents = false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dynamic Scope Body
                    if (_isAllEvents)
                      _buildAllEventsContent(provider)
                    else
                      _buildSingleEventContent(provider, activeEvent),

                    const SizedBox(height: 12),

                    // Bottom info hint
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Colors.white54),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Click "Print" for official A4 preview or WhatsApp icon for direct sharing.',
                            style: TextStyle(fontSize: 10.5, color: Colors.white.withAlpha(140)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (_isGenerating)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xDD070D1E),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            color: Color(0xFFE11D48),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _loadingText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Formatting official printable statement...',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeTab({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE11D48).withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFE11D48).withAlpha(120) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFFFB7185) : Colors.white60,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? const Color(0xFFFB7185) : Colors.white38,
                    ),
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

  // ALL EVENTS CONTENT
  Widget _buildAllEventsContent(PujaProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Financial Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Total Inflow', _currency.format(provider.totalIncome), AppTheme.successGreenLight),
              Container(width: 1, height: 22, color: Colors.white12),
              _buildMiniStat('Total Outflow', _currency.format(provider.totalExpense), AppTheme.dangerRose),
              Container(width: 1, height: 22, color: Colors.white12),
              _buildMiniStat('Net Surplus', _currency.format(provider.netBalance), AppTheme.goldAccent),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Included Festivals Badges
        if (provider.events.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: provider.events.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 11, color: AppTheme.successGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${e.name} (${e.year})',
                      style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
        ],

        const Text(
          'CHOOSE CONSOLIDATED REPORT TYPE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // 1. Consolidated Audit Report & Balance Sheet
        _buildReportOptionCard(
          title: 'Consolidated Balance Sheet & Audit Report',
          subtitle: 'Official balance sheet, event-by-event breakdown, books audit, category expenditure & cash in hand',
          badge: 'Master Audit',
          icon: Icons.account_balance_rounded,
          accentColor: AppTheme.goldAccent,
          countText: '${provider.events.length} Events • ${_currency.format(provider.netBalance)} Surplus',
          onPrint: () => _handleAllEventsGenerate(provider, isLedger: false, isShare: false),
          onShare: () => _handleAllEventsGenerate(provider, isLedger: false, isShare: true),
        ),
        const SizedBox(height: 10),

        // 2. All Events Unified Transactions Ledger
        _buildReportOptionCard(
          title: 'All Events Unified Transactions Ledger',
          subtitle: 'Full chronological register combining all slips, vouchers & advances/contracts across all festivals',
          badge: 'Grand Ledger',
          icon: Icons.receipt_long_rounded,
          accentColor: AppTheme.primaryBlue,
          countText: '${provider.slips.length + provider.expenses.length + provider.advances.length} Total Transactions',
          onPrint: () => _handleAllEventsGenerate(provider, isLedger: true, isShare: false),
          onShare: () => _handleAllEventsGenerate(provider, isLedger: true, isShare: true),
        ),
      ],
    );
  }

  // SINGLE EVENT CONTENT
  Widget _buildSingleEventContent(PujaProvider provider, PujaEvent? event) {
    if (provider.events.isEmpty || event == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x1F1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.event_busy_rounded, color: Colors.white38, size: 36),
            SizedBox(height: 8),
            Text(
              'No Events Available',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'Create an event or switch to "All Events Combined" tab to export overall reports.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.white38),
            ),
          ],
        ),
      );
    }

    final eventSlips = provider.slips.where((s) => s.eventId == event.id).toList();
    final eventExpenses = provider.expenses.where((e) => e.eventId == event.id).toList();
    final eventAdvances = provider.advances.where((a) => a.eventId == event.id).toList();

    final totalCollected = eventSlips.fold<double>(0.0, (sum, s) => sum + s.amount);
    final totalExpense = eventExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final totalAdvances = eventAdvances.fold<double>(0.0, (sum, a) => sum + a.advanceAmount);
    final netSurplus = totalCollected - totalExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Festival Dropdown / Selector Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33E11D48)),
          ),
          child: Row(
            children: [
              const Icon(Icons.festival_rounded, color: Color(0xFFFB7185), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Select Festival:',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: event.id,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF0F172A),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
                    items: provider.events.map((ev) {
                      return DropdownMenuItem<String>(
                        value: ev.id,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${ev.name} (${ev.year})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (ev.status == 'Active' ? AppTheme.successGreen : Colors.white24).withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ev.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: ev.status == 'Active' ? AppTheme.successGreen : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newId) {
                      if (newId != null) {
                        setState(() {
                          _selectedEvent = provider.events.firstWhere((e) => e.id == newId);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Event Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x1F1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Chanda', _currency.format(totalCollected), AppTheme.successGreen),
              Container(width: 1, height: 20, color: Colors.white12),
              _buildMiniStat('Expenses', _currency.format(totalExpense), AppTheme.dangerRose),
              Container(width: 1, height: 20, color: Colors.white12),
              _buildMiniStat('Advances', _currency.format(totalAdvances), const Color(0xFFF59E0B)),
              Container(width: 1, height: 20, color: Colors.white12),
              _buildMiniStat('Net', _currency.format(netSurplus), AppTheme.goldAccent),
            ],
          ),
        ),
        const SizedBox(height: 14),

        const Text(
          'CHOOSE STATEMENT TYPE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // Option 1: Complete Statement (All Transactions)
        _buildReportOptionCard(
          title: 'All Transactions (Complete Statement)',
          subtitle: 'Unified Inflow, Outflow & Advances chronological ledger with balance',
          badge: 'Complete Audit',
          icon: Icons.receipt_long_rounded,
          accentColor: AppTheme.primaryBlue,
          countText: '${eventSlips.length + eventExpenses.length + eventAdvances.length} entries',
          onPrint: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.allTransactions, isShare: false),
          onShare: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.allTransactions, isShare: true),
        ),
        const SizedBox(height: 8),

        // Option 2: Only Collections (Chanda)
        _buildReportOptionCard(
          title: 'Only Collections (Chanda Slips)',
          subtitle: 'Donor slips, book numbers, payment modes & collectors register',
          badge: 'Collections',
          icon: Icons.volunteer_activism_rounded,
          accentColor: AppTheme.successGreen,
          countText: '${eventSlips.length} Slips (${_currency.format(totalCollected)})',
          onPrint: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.collectionsOnly, isShare: false),
          onShare: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.collectionsOnly, isShare: true),
        ),
        const SizedBox(height: 8),

        // Option 3: Only Expenses (Vouchers)
        _buildReportOptionCard(
          title: 'Only Expenses (Expenditures)',
          subtitle: 'Itemized vouchers, category breakdown, vendors & bill numbers',
          badge: 'Expenses',
          icon: Icons.payments_rounded,
          accentColor: AppTheme.dangerRose,
          countText: '${eventExpenses.length} Vouchers (${_currency.format(totalExpense)})',
          onPrint: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.expensesOnly, isShare: false),
          onShare: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.expensesOnly, isShare: true),
        ),
        const SizedBox(height: 8),

        // Option 4: Only Advances & Contracts (Pesgi)
        _buildReportOptionCard(
          title: 'Only Advances & Contracts (Pesgi)',
          subtitle: 'Cash disbursed to contractors & members, actual spent & refund cash tracking',
          badge: 'Advances',
          icon: Icons.wallet_rounded,
          accentColor: const Color(0xFFF59E0B),
          countText: '${eventAdvances.length} Advances (${_currency.format(totalAdvances)})',
          onPrint: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.advancesOnly, isShare: false),
          onShare: () => _handleSingleEventGenerate(provider, event, EventPdfReportType.advancesOnly, isShare: true),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReportOptionCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color accentColor,
    required String countText,
    required VoidCallback onPrint,
    required VoidCallback onShare,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPrint,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withAlpha(70), width: 0.8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 10),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: accentColor.withAlpha(80), width: 0.7),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withAlpha(140),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countText,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: accentColor.withAlpha(220),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Action Buttons: Share & Print
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share icon button
                    IconButton(
                      tooltip: 'Share on WhatsApp / Apps',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        padding: const EdgeInsets.all(7),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 15, color: Colors.white),
                      onPressed: onShare,
                    ),
                    const SizedBox(width: 6),

                    // Print / Save button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: const Color(0xFF070D1E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 2,
                      ),
                      onPressed: onPrint,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.print_rounded, size: 14),
                          SizedBox(width: 4),
                          Text('Print', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
