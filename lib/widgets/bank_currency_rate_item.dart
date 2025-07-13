import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BankCurrencyRateItem extends StatelessWidget {
  final String? currencyName;
  final String? currencyCode;
  final double? cashBuying;
  final double? cashSelling;
  final double? transactionBuying;
  final double? transactionSelling;
  final DateTime? updated;

  const BankCurrencyRateItem({
    super.key,
    required this.currencyName,
    required this.currencyCode,
    required this.cashBuying,
    required this.cashSelling,
    required this.transactionBuying,
    required this.transactionSelling,
    this.updated,
  });

  String _formatRate(double? value) {
    return value != null ? value.toStringAsFixed(4) : '-';
  }

  void _showLastUpdatedInfo(BuildContext context) {
    if (updated == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Last updated: ${DateFormat('MMM d, yyyy hh:mm a').format(updated!)}',
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
          // Header Row - Currency info and code
          Row(
            children: [
              // Currency icon and name
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.currency_exchange,
                  size: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  currencyName ?? 'Unknown',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              // Currency code and info icon
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
                      currencyCode ?? 'N/A',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (updated != null) ...[
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

  Widget _buildCompactRateCard(BuildContext context, String label, double? value, IconData icon, Color bgColor) {
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