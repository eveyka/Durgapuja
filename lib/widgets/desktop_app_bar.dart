import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/desktop_controller.dart';
import '../providers/puja_provider.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';
import 'desktop_fast_entry_modal.dart';
import 'desktop_shortcuts_dialog.dart';
import 'update_dialog.dart';

class DesktopAppBar extends StatelessWidget {
  const DesktopAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final desktopCtrl = Provider.of<DesktopController>(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xF7091124),
        border: Border(
          bottom: BorderSide(color: AppTheme.glassBorderLight.withAlpha(60), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          // 1. Sidebar Toggle Button
          IconButton(
            tooltip: 'Toggle Sidebar (Ctrl+B)',
            icon: Icon(
              desktopCtrl.isSidebarCollapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () => desktopCtrl.toggleSidebar(),
          ),
          const SizedBox(width: 8),

          // 2. Festival Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x1F1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.selectedEventId,
                dropdownColor: const Color(0xFF0F172A),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.goldAccent, size: 18),
                hint: const Row(
                  children: [
                    Icon(Icons.festival_rounded, color: AppTheme.goldAccent, size: 16),
                    SizedBox(width: 6),
                    Text('All Festivals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive_rounded, color: AppTheme.primaryBlue, size: 16),
                        SizedBox(width: 8),
                        Text('All Festivals (Combined)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  ...provider.events.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.id,
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: e.status == 'Active' ? AppTheme.successGreen : Colors.white38,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.name} (${e.year})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (id) {
                  if (id != null) {
                    provider.selectEvent(id);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 3. Quick Financial Status Pill Tickers
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatPill(
                    label: 'Net Balance',
                    value: currency.format(provider.netBalance),
                    color: provider.netBalance >= 0 ? AppTheme.successGreen : AppTheme.dangerRose,
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    label: "Today's Collection",
                    value: currency.format(provider.todaysCollection),
                    color: AppTheme.goldAccent,
                    icon: Icons.today_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildStatPill(
                    label: 'Cash in Hand',
                    value: currency.format(provider.totalCashIncome - provider.totalCashExpense),
                    color: AppTheme.primaryBlue,
                    icon: Icons.payments_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 4. Global Search Bar
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              focusNode: desktopCtrl.searchFocusNode,
              onChanged: (val) => desktopCtrl.setSearchQuery(val),
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search ledger (Ctrl+F)...',
                hintStyle: TextStyle(fontSize: 11.5, color: Colors.white.withAlpha(120)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Colors.white60),
                suffixIcon: desktopCtrl.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.white70),
                        onPressed: () => desktopCtrl.clearSearch(),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(right: 6, top: 8, bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Ctrl+F', style: TextStyle(fontSize: 9, color: Colors.white60, fontWeight: FontWeight.bold)),
                      ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                filled: true,
                fillColor: const Color(0x1F1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.2)),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 5. Quick Action Button Dock
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
            label: const Text('+ Chanda (F2)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.chanda),
            ),
          ),
          const SizedBox(width: 8),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 15),
            label: const Text('+ Expense (F3)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const DesktopFastEntryModal(initialType: QuickEntryType.expense),
            ),
          ),
          const SizedBox(width: 8),

          // In-App Updates Check Button
          Consumer<UpdateProvider>(
            builder: (context, updateProv, _) {
              final hasUpdate = updateProv.hasUpdateAvailable;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    tooltip: hasUpdate ? 'New Update Available! (Click to Install)' : 'Check for Updates',
                    icon: Icon(
                      hasUpdate ? Icons.new_releases_rounded : Icons.system_update_rounded,
                      color: hasUpdate ? AppTheme.goldAccent : Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => AppUpdateDialog.show(context),
                  ),
                  if (hasUpdate)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Activity History Log Button
          IconButton(
            tooltip: 'Recent Activity History & Audit Trail',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.history_rounded, color: AppTheme.primaryBlue, size: 22),
                if (provider.activityLogs.isNotEmpty)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: AppTheme.goldAccent, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  ),
              ],
            ),
            onPressed: () => desktopCtrl.setTab(3),
          ),

          // Shortcuts & Help Icon
          IconButton(
            tooltip: 'Shortcuts & Cheatsheet (F1)',
            icon: const Icon(Icons.keyboard_outlined, color: AppTheme.goldAccent, size: 21),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const DesktopShortcutsDialog(),
            ),
          ),

          // Density Setting Dropdown
          PopupMenuButton<DesktopDensity>(
            tooltip: 'Table Density',
            icon: const Icon(Icons.density_medium_rounded, color: Colors.white70, size: 19),
            onSelected: (d) => desktopCtrl.setDensity(d),
            itemBuilder: (_) => [
              const PopupMenuItem(value: DesktopDensity.compact, child: Text('Compact View')),
              const PopupMenuItem(value: DesktopDensity.standard, child: Text('Standard View')),
              const PopupMenuItem(value: DesktopDensity.comfortable, child: Text('Comfortable View')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(180), fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
