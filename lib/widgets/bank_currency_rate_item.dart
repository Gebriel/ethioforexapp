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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use theme.colorScheme for consistency
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1), // Use theme.co
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyName ?? 'Unknown',
                style: theme.textTheme.titleMedium?.copyWith( // Use theme.textTheme
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface, // Use theme.colorScheme
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  currencyCode ?? 'N/A',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRateCard(
                  context,
                  "Cash Buy",
                  cashBuying,
                  colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Cash Sell",
                  cashSelling,
                  colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildRateCard(
                  context,
                  "Txn Buy",
                  transactionBuying,
                  colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Txn Sell",
                  transactionSelling,
                  colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
          // Added Updated At
          if (updated != null) ...[
            const SizedBox(height: 16),
            Divider(color: colorScheme.outline, thickness: 0.5), // Use theme.colorScheme
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last updated: ${DateFormat('MMM d, hh:mm a').format(updated!)}',
                style: theme.textTheme.bodySmall?.copyWith( // Use theme.textTheme
                  color: colorScheme.onSurfaceVariant, // Use theme.colorScheme for good contrast
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateCard(BuildContext context, String label, double? value, Color bgColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use theme.colorScheme

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith( // Use theme.textTheme
              color: colorScheme.onSurfaceVariant, // Use theme.colorScheme for good contrast
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? value.toStringAsFixed(4) : '-',
            style: theme.textTheme.bodyMedium?.copyWith( // Use theme.textTheme
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface, // Use theme.colorScheme for good contrast
            ),
          ),
        ],
      ),
    );
  }
}