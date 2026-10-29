import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class DesktopShortcutsDialog extends StatelessWidget {
  const DesktopShortcutsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primaryBlue.withAlpha(80)),
                        ),
                        child: const Icon(Icons.keyboard_outlined, color: AppTheme.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PC Keyboard Shortcuts',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            'Quick terminal controls for high-speed operation',
                            style: TextStyle(fontSize: 12, color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),

              // Shortcut Sections
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSection('⚡ Quick Data Entry (Cashier POS)', [
                        _buildShortcutRow('F2 / Ctrl + N', 'Create New Chanda Slip (Collection)'),
                        _buildShortcutRow('F3 / Ctrl + E', 'Create New Expense Voucher'),
                        _buildShortcutRow('F4 / Ctrl + A', 'Issue Member / Vendor Advance'),
                        _buildShortcutRow('Enter / Ctrl + Enter', 'Save & Submit Form in Fast Entry Modal'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('🧭 Navigation & Views', [
                        _buildShortcutRow('Ctrl + 1', 'Dashboard Overview'),
                        _buildShortcutRow('Ctrl + 2', 'Festivals & Events'),
                        _buildShortcutRow('Ctrl + 3', 'Transactions & Ledger'),
                        _buildShortcutRow('Ctrl + 4', 'Recent Activity History'),
                        _buildShortcutRow('Ctrl + 5', 'Financial Analytics'),
                        _buildShortcutRow('Ctrl + 6', 'Balance Sheet & Reports'),
                        _buildShortcutRow('Ctrl + B', 'Toggle Collapsible Sidebar'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('🔍 Search & Inspector', [
                        _buildShortcutRow('Ctrl + F', 'Focus Global Search Filter'),
                        _buildShortcutRow('Esc', 'Close Inspector Panel / Clear Selection / Cancel'),
                        _buildShortcutRow('Ctrl + P', 'Print / PDF Export Summary'),
                        _buildShortcutRow('F1 / Ctrl + H', 'Open this Shortcuts Guide'),
                      ]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: const Color(0xFF070D1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it (Esc)', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x1F1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.goldAccent),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keyCombination, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              keyCombination,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
