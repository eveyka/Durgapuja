import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/desktop_controller.dart';
import '../providers/puja_provider.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';
import 'desktop_shortcuts_dialog.dart';
import 'dialogs.dart';
import 'glass_container.dart';
import 'update_dialog.dart';

class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PujaProvider>(context);
    final desktopCtrl = Provider.of<DesktopController>(context);
    final isCollapsed = desktopCtrl.isSidebarCollapsed;
    final activeEvent = provider.selectedEvent;
    final pendingAdvancesCount = provider.advances.where((a) => a.status == 'Pending').length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isCollapsed ? 76 : 260,
      margin: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: const Color(0xF50A1128),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.glassBorderLight.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 18,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCollapsed ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Brand Header
            Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryBlue, AppTheme.deepAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.festival_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DPER TERMINAL',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PC Cashier Suite',
                          style: TextStyle(fontSize: 10, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 2. Active Festival Indicator Card
            if (!isCollapsed) ...[
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => desktopCtrl.setTab(1),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activeEvent != null ? AppTheme.successGreen : AppTheme.goldAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeEvent != null ? '${activeEvent.name} (${activeEvent.year})' : 'All Festivals',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                activeEvent != null ? 'Active Event' : 'Select Festival',
                                style: TextStyle(fontSize: 9.5, color: Colors.white.withAlpha(140)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white38),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Quick Account Creation Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.account_balance_rounded, size: 13),
                      label: const Text(
                        '+ Collection',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddCollectionAccountDialog(initialEventId: activeEvent?.id),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0x1F1E293B),
                        foregroundColor: AppTheme.dangerRose,
                        side: BorderSide(color: AppTheme.dangerRose.withAlpha(120)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      ),
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 13),
                      label: const Text(
                        '+ Expense',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AddExpenditureAccountDialog(initialEventId: activeEvent?.id),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // 4. Navigation Links
            _buildNavItem(context, desktopCtrl, 0, Icons.dashboard_rounded, 'Dashboard', isCollapsed),
            _buildNavItem(
              context,
              desktopCtrl,
              1,
              Icons.festival_rounded,
              'Festivals & Events',
              isCollapsed,
              badgeText: '${provider.events.length}',
            ),
            _buildNavItem(
              context,
              desktopCtrl,
              2,
              Icons.swap_horiz_rounded,
              'Ledger & Records',
              isCollapsed,
              badgeText: pendingAdvancesCount > 0 ? '$pendingAdvancesCount' : null,
              badgeColor: AppTheme.goldAccent,
            ),
            _buildNavItem(
              context,
              desktopCtrl,
              3,
              Icons.history_rounded,
              'Recent History',
              isCollapsed,
              badgeText: provider.activityLogs.isNotEmpty ? '${provider.activityLogs.length}' : null,
              badgeColor: AppTheme.primaryBlue,
            ),
            _buildNavItem(context, desktopCtrl, 4, Icons.insert_chart_rounded, 'Analytics & KPIs', isCollapsed),
            _buildNavItem(context, desktopCtrl, 5, Icons.description_rounded, 'Balance Sheet', isCollapsed),

            const Spacer(),

            // 5. In-App Updates Manager Button
            Consumer<UpdateProvider>(
              builder: (context, updateProv, _) {
                final hasUpdate = updateProv.hasUpdateAvailable;
                return InkWell(
                  onTap: () => AppUpdateDialog.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 6 : 10, vertical: 7),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: hasUpdate ? AppTheme.goldAccent.withAlpha(25) : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasUpdate ? AppTheme.goldAccent.withAlpha(90) : Colors.white10,
                        width: hasUpdate ? 1.2 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        Icon(
                          hasUpdate ? Icons.new_releases_rounded : Icons.system_update_rounded,
                          size: 15,
                          color: hasUpdate ? AppTheme.goldAccent : AppTheme.primaryBlue,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasUpdate ? 'Update Available!' : 'Check for Updates',
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUpdate ? AppTheme.goldAccent : Colors.white70,
                                fontWeight: hasUpdate ? FontWeight.w800 : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasUpdate)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.goldAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // 6. Shortcuts Button & Guide
            if (!isCollapsed)
              InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const DesktopShortcutsDialog(),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x14FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.keyboard_outlined, size: 13, color: AppTheme.goldAccent),
                      SizedBox(width: 6),
                      Text(
                        'Press F1 for Shortcuts',
                        style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

            // 7. User Profile Card
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final initials = auth.displayName.isNotEmpty
                    ? auth.displayName
                        .split(' ')
                        .take(2)
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .join()
                        .toUpperCase()
                    : 'CD';

                return InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const EditCommitteeSettingsDialog(initialTab: 1),
                  ),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.all(isCollapsed ? 6 : 8),
                    decoration: BoxDecoration(
                      color: const Color(0x1F1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.glassBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryBlue,
                          backgroundImage: auth.photoUrl != null ? NetworkImage(auth.photoUrl!) : null,
                          child: auth.photoUrl == null
                              ? Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Color(0xFF070D1E),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                )
                              : null,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.displayName.isNotEmpty ? auth.displayName : 'Cashier Desk',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  auth.email.isNotEmpty ? auth.email : 'Local Operator',
                                  style: const TextStyle(fontSize: 9, color: Colors.white60),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: AppTheme.dangerRose, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Sign Out',
                            onPressed: () => _confirmSignOut(context),
                          ),
                        ],
                      ],
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

  Widget _buildNavItem(
    BuildContext context,
    DesktopController controller,
    int index,
    IconData icon,
    String label,
    bool isCollapsed, {
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = controller.activeTabIndex == index;

    return Tooltip(
      message: isCollapsed ? label : '',
      child: GestureDetector(
        onTap: () => controller.setTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 10 : 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue.withAlpha(110) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppTheme.primaryBlue : Colors.white60),
              if (!isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppTheme.primaryBlue).withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (badgeColor ?? AppTheme.primaryBlue).withAlpha(90)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: badgeColor ?? AppTheme.primaryBlue,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: 22,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRose.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.dangerRose, size: 26),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sign Out Terminal?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Are you sure you want to exit your Cashier Desk session?',
                style: TextStyle(fontSize: 12.5, color: Colors.white.withAlpha(160)),
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
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                        Provider.of<AuthProvider>(context, listen: false).signOut();
                      },
                      child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
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
