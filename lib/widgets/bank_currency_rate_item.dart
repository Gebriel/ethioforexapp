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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${currencyName ?? 'Unknown'} (${currencyCode ?? 'N/A'})",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRate("Cash Buy", cashBuying),
              _buildRate("Cash Sell", cashSelling),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRate("Txn Buy", transactionBuying),
              _buildRate("Txn Sell", transactionSelling),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRate(String label, double? value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value != null ? value.toStringAsFixed(4) : '-',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
