import 'package:flutter/material.dart';

class BankCurrencyRateItem extends StatelessWidget {
  final String? currencyName;
  final String? currencyCode;
  final double? cashBuying;
  final double? cashSelling;
  final double? transactionBuying;
  final double? transactionSelling;

  const BankCurrencyRateItem({
    super.key,
    required this.currencyName,
    required this.currencyCode,
    required this.cashBuying,
    required this.cashSelling,
    required this.transactionBuying,
    required this.transactionSelling,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
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
                  isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F7FA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Cash Sell",
                  cashSelling,
                  isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F7FA),
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
                  isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F7FA),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRateCard(
                  context,
                  "Txn Sell",
                  transactionSelling,
                  isDark ? Color(0xFF2A2A2A) : Color(0xFFF5F7FA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(BuildContext context, String label, double? value, Color bgColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value != null ? value.toStringAsFixed(4) : '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}