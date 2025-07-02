import 'bank_rate.dart';

class CurrencyRatesResponse {
  final String currencyCode;
  final String currencyName;
  final List<BankRate> cashRates;
  final List<BankRate> transactionRates;

  CurrencyRatesResponse({
    required this.currencyCode,
    required this.currencyName,
    required this.cashRates,
    required this.transactionRates,
  });

  factory CurrencyRatesResponse.fromJson(Map<String, dynamic> json) {
    final List<BankRate> cash = (json['cash_rate'] as List)
        .map((e) => BankRate.fromJson(e))
        .toList();

    final List<BankRate> transaction = (json['transaction_rate'] as List)
        .map((e) => BankRate.fromJson(e))
        .toList();

    return CurrencyRatesResponse(
      currencyCode: json['currency_code'],
      currencyName: json['currency_name'],
      cashRates: cash,
      transactionRates: transaction,
    );
  }
}
