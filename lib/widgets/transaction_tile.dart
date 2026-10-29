import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'glass_container.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isIncome;
  final PaymentMode paymentMode;
  final DateTime date;
  final String? tag;
  final bool hasReceipt;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isIncome,
    required this.paymentMode,
    required this.date,
    this.tag,
    this.hasReceipt = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    // Initials for avatar
    final initials = title.trim().isNotEmpty
        ? title
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : 'DP';

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isIncome
                    ? [const Color(0xFF1E3A8A), const Color(0xFF38BDF8)]
                    : [const Color(0xFF4C1D95), const Color(0xFFF43F5E)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isIncome ? AppTheme.primaryBlue : AppTheme.dangerRose).withAlpha(40),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isEmpty ? 'DP' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title, Subtitle, and Optional Tag
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((tag != null && tag!.trim().isNotEmpty) || hasReceipt) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (tag != null && tag!.trim().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isIncome ? AppTheme.primaryBlue : AppTheme.dangerRose).withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag!,
                            style: TextStyle(
                              color: isIncome ? AppTheme.primaryBlue : const Color(0xFFFF7B92),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (hasReceipt)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.successGreen.withAlpha(60), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.attach_file, size: 10, color: AppTheme.successGreenLight),
                              SizedBox(width: 2),
                              Text(
                                'Bill Attached',
                                style: TextStyle(
                                  color: AppTheme.successGreenLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Amount and Payment Mode badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${currency.format(amount)}',
                style: TextStyle(
                  color: isIncome ? AppTheme.successGreenLight : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isIncome ? AppTheme.successGreen : AppTheme.dangerRose).withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 10,
                      color: isIncome ? AppTheme.successGreenLight : AppTheme.dangerRose,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      paymentMode == PaymentMode.bankTransfer
                          ? 'BANK'
                          : paymentMode.name.toUpperCase(),
                      style: TextStyle(
                        color: isIncome ? AppTheme.successGreenLight : AppTheme.dangerRose,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
