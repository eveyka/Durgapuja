import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class HeroBalanceCard extends StatelessWidget {
  final double netBalance;
  final double todaysCollection;
  final double totalIncome;
  final double totalExpense;
  final String? eventName;
  final VoidCallback onAddChanda;
  final VoidCallback onAddExpense;
  final VoidCallback onViewReport;
  final VoidCallback? onGiveAdvance;

  const HeroBalanceCard({
    super.key,
    required this.netBalance,
    required this.todaysCollection,
    required this.totalIncome,
    required this.totalExpense,
    this.eventName,
    required this.onAddChanda,
    required this.onAddExpense,
    required this.onViewReport,
    this.onGiveAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return GlassContainer(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      hasGlow: true,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1E3A8A),
          Color(0xFF0F244C),
          Color(0xFF0A1329),
        ],
        stops: [0.0, 0.55, 1.0],
      ),
      border: Border.all(
        color: AppTheme.glassBorderLight,
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle & Event Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Net Balance',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              InkWell(
                onTap: onViewReport,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withAlpha(35),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.festival_rounded,
                        size: 13,
                        color: AppTheme.goldAccent,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        eventName ?? 'Live 2026',
                        style: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Main Big Balance Display
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currencyFormat.format(netBalance),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Growth & Today Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withAlpha(35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successGreenLight.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: AppTheme.successGreenLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+₹${NumberFormat.compact().format(todaysCollection)} Today',
                      style: const TextStyle(
                        color: AppTheme.successGreenLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(30),
                  ),
                ),
                child: Text(
                  'Inflow: ₹${NumberFormat.compact().format(totalIncome)}  •  Out: ₹${NumberFormat.compact().format(totalExpense)}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(210),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Action Glass Buttons
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.account_balance_rounded,
                  label: '+ Collection A/C',
                  onTap: onAddChanda,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.account_balance_wallet_rounded,
                  label: '+ Expenditure A/C',
                  onTap: onAddExpense,
                ),
              ),
              if (onGiveAdvance != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.wallet_rounded,
                    label: '+ Advance',
                    onTap: onGiveAdvance!,
                    isAdvance: true,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.summarize_outlined,
                  label: 'Reports',
                  onTap: onViewReport,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool isAdvance;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isAdvance = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColor = Colors.white70;
    Color labelColor = Colors.white70;
    Color bgColor = const Color(0x2E1E293B);
    Color borderColor = AppTheme.glassBorder;

    if (isPrimary) {
      iconColor = AppTheme.primaryBlue;
      labelColor = Colors.white;
      bgColor = AppTheme.primaryBlue.withAlpha(40);
      borderColor = AppTheme.primaryBlue.withAlpha(140);
    } else if (isAdvance) {
      iconColor = const Color(0xFFFBBF24); // Amber 400
      labelColor = Colors.white;
      bgColor = const Color(0xFFD97706).withAlpha(40); // Amber 600
      borderColor = const Color(0xFFFBBF24).withAlpha(120);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color: iconColor,
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
