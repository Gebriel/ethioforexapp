import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import for date formatting

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

  // Original _formatRate logic: Shows actual value (including 0.0000) or '-' for null.
  String _formatRate(double value) {
    // Note: The original code passed `double` directly, implying non-null.
    // If it could be null, the parameter type would need to be `double?`.
    // Assuming it's guaranteed to be non-null for now as per original _buildRateCard.
    return value.toStringAsFixed(4);
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use theme.colorScheme for consistency
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Use theme.colorScheme.surface for consistency
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1), // Use theme.colorScheme.shadow
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
              Row(
                children: [
                  if (bankLogo != null && bankLogo!.isNotEmpty)
                    CircleAvatar(
                      backgroundImage: NetworkImage(bankLogo!),
                      radius: 16,
                      backgroundColor: Colors.transparent,
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      // Use theme colors for consistency
                      backgroundColor: isDark ? colorScheme.surfaceContainerHighest : colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.account_balance,
                        size: 16,
                        color: isDark ? colorScheme.onSurface : colorScheme.onSurface,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Text(
                    bankName,
                    style: theme.textTheme.titleMedium?.copyWith( // Use theme.textTheme
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface, // Use theme.colorScheme
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bankCode,
                  style: theme.textTheme.labelMedium?.copyWith( // Use theme.textTheme
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
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
                  colorScheme.surfaceContainerHighest, // Use theme.colorScheme
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Cash Sell",
                  cashSelling,
                  colorScheme.surfaceContainerHighest, // Use theme.colorScheme
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
                  colorScheme.surfaceContainerHighest, // Use theme.colorScheme
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Txn Sell",
                  transactionSelling,
                  colorScheme.surfaceContainerHighest, // Use theme.colorScheme
                ),
              ),
            ],
          ),
          // Added Updated At
          if (updatedAt != null) ...[
            const SizedBox(height: 16),
            Divider(color: colorScheme.outline, thickness: 0.5), // Use theme.colorScheme
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Last updated: ${DateFormat('MMM d, hh:mm a').format(updatedAt!)}',
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

  Widget _buildRateCard(BuildContext context, String label, double value, Color bgColor) {
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
            _formatRate(value), // Use _formatRate for consistency
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