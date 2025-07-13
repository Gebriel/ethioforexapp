import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RateListItem extends StatelessWidget {
  final String bankName;
  final String? bankLogo;
  final String bankCode;
  final double cashBuying;
  final double cashSelling;
  final double transactionBuying;
  final double transactionSelling;
  final DateTime? updatedAt;

  const RateListItem({
    super.key,
    required this.bankName,
    required this.bankLogo,
    required this.bankCode,
    required this.cashBuying,
    required this.cashSelling,
    required this.transactionBuying,
    required this.transactionSelling,
    this.updatedAt,
  });

  String _formatRate(double value) {
    return value.toStringAsFixed(4);
  }

  void _showLastUpdatedInfo(BuildContext context) {
    if (updatedAt == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Last updated: ${DateFormat('MMM d, yyyy hh:mm a').format(updatedAt!)}',
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Bank info and code
          Row(
            children: [
              // Bank logo and name
              if (bankLogo != null && bankLogo!.isNotEmpty)
                CircleAvatar(
                  backgroundImage: NetworkImage(bankLogo!),
                  radius: 14,
                  backgroundColor: Colors.transparent,
                )
              else
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.account_balance,
                    size: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bankName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Bank code and info icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bankCode,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showLastUpdatedInfo(context),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.info_outline,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rates Grid - 2x2 layout
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactRateCard(
                        context,
                        "Cash Buy",
                        cashBuying,
                        Icons.trending_up,
                        colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactRateCard(
                        context,
                        "Txn Buy",
                        transactionBuying,
                        Icons.account_balance_wallet,
                        colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      _buildCompactRateCard(
                        context,
                        "Cash Sell",
                        cashSelling,
                        Icons.trending_down,
                        colorScheme.surfaceContainerHighest,
                      ),
                      const SizedBox(height: 6),
                      _buildCompactRateCard(
                        context,
                        "Txn Sell",
                        transactionSelling,
                        Icons.account_balance_wallet,
                        colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRateCard(BuildContext context, String label, double value, IconData icon, Color bgColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            _formatRate(value),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}