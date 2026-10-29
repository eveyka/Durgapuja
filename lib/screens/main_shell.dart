import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/desktop_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/desktop_app_bar.dart';
import '../widgets/desktop_fast_entry_modal.dart';
import '../widgets/desktop_inspector_panel.dart';
import '../widgets/desktop_shortcuts_dialog.dart';
import '../widgets/desktop_sidebar.dart';
import '../widgets/responsive_layout.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'history_screen.dart';
import 'reports_screen.dart';
import 'transactions_screen.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late final List<Widget> _screens = [
    DashboardScreen(onNavigateTab: (idx) {
      if (mounted) {
        Provider.of<DesktopController>(context, listen: false).setTab(idx);
      }
    }),
    const EventsScreen(),
    const TransactionsScreen(),
    const HistoryScreen(),
    const AnalyticsScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final desktopCtrl = Provider.of<DesktopController>(context);
    final screens = _screens;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Background ambient gradient orbs
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryBlue.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.deepAccent.withAlpha(18),
              ),
            ),
          ),

          ResponsiveLayout(
            mobile: _buildMobileLayout(screens, desktopCtrl),
            desktop: _buildDesktopLayout(screens, desktopCtrl),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(List<Widget> screens, DesktopController desktopCtrl) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final currentIndex = desktopCtrl.activeTabIndex;

    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: IndexedStack(
            index: currentIndex,
            children: screens,
          ),
        ),

        // Floating Mobile Navigation Bar
        Positioned(
          left: 10,
          right: 10,
          bottom: bottomInset > 0 ? bottomInset + 8 : 16,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xF50A1128),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppTheme.primaryBlue.withAlpha(50),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(120),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: AppTheme.primaryBlue.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildMobileNavItem(0, Icons.home_rounded, 'Home', desktopCtrl),
                _buildMobileNavItem(1, Icons.festival_rounded, 'Events', desktopCtrl),
                _buildMobileNavItem(2, Icons.swap_horiz_rounded, 'Ledger', desktopCtrl),
                _buildMobileNavItem(3, Icons.history_rounded, 'History', desktopCtrl),
                _buildMobileNavItem(4, Icons.insert_chart_rounded, 'Analytics', desktopCtrl),
                _buildMobileNavItem(5, Icons.description_rounded, 'Reports', desktopCtrl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String label, DesktopController desktopCtrl) {
    final isSelected = desktopCtrl.activeTabIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (desktopCtrl.activeTabIndex != index) {
          HapticFeedback.lightImpact();
          desktopCtrl.setTab(index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withAlpha(35) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue.withAlpha(120) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected ? AppTheme.primaryBlue : Colors.white60,
            ),
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerLeft,
                child: isSelected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 7),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.clip,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(List<Widget> screens, DesktopController desktopCtrl) {
    // Comprehensive PC Systematic Keyboard Shortcuts
    final shortcuts = <ShortcutActivator, VoidCallback>{
      // Navigation
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): () => desktopCtrl.setTab(0),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): () => desktopCtrl.setTab(1),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): () => desktopCtrl.setTab(2),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true): () => desktopCtrl.setTab(3),
      const SingleActivator(LogicalKeyboardKey.digit5, control: true): () => desktopCtrl.setTab(4),
      const SingleActivator(LogicalKeyboardKey.digit6, control: true): () => desktopCtrl.setTab(5),
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () => desktopCtrl.toggleSidebar(),

      // Fast Cashier Terminal POS Data Entry
      const SingleActivator(LogicalKeyboardKey.f1): () {
        showDialog(context: context, builder: (_) => const DesktopShortcutsDialog());
      },
      const SingleActivator(LogicalKeyboardKey.keyH, control: true): () {
        showDialog(context: context, builder: (_) => const DesktopShortcutsDialog());
      },
      const SingleActivator(LogicalKeyboardKey.f2): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.chanda));
      },
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.chanda));
      },
      const SingleActivator(LogicalKeyboardKey.f3): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.expense));
      },
      const SingleActivator(LogicalKeyboardKey.keyE, control: true): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.expense));
      },
      const SingleActivator(LogicalKeyboardKey.f4): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.advance));
      },
      const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
        showDialog(context: context, builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.advance));
      },

      // Search & Inspector
      const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => desktopCtrl.focusSearch(),
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (desktopCtrl.isInspectorOpen) {
          desktopCtrl.closeInspector();
        } else if (desktopCtrl.searchQuery.isNotEmpty) {
          desktopCtrl.clearSearch();
        }
      },
      const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => desktopCtrl.setTab(4),
    };

    return CallbackShortcuts(
      bindings: shortcuts,
      child: Focus(
        autofocus: true,
        child: Row(
          children: [
            // 1. Collapsible Desktop Navigation Sidebar
            const DesktopSidebar(),

            // 2. Main Content Area with Systematic Top Command Bar & Master-Detail Pane
            Expanded(
              child: Column(
                children: [
                  // Top Command & Header Bar
                  const DesktopAppBar(),

                  // Split-Pane Body Area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Main View / Data Tables
                        Expanded(
                          child: IndexedStack(
                            index: desktopCtrl.activeTabIndex,
                            children: screens,
                          ),
                        ),

                        // Master-Detail Inspector Panel (Slides in on record click)
                        if (desktopCtrl.isInspectorOpen) const DesktopInspectorPanel(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
