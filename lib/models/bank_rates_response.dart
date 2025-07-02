import 'bank_currency_rate.dart';

class BankRatesResponse {
  final String bankCode;
  final String bankName;
  final List<BankCurrencyRate> cashRates;
  final List<BankCurrencyRate> transactionRates;

  BankRatesResponse({
    required this.bankCode,
    required this.bankName,
    required this.cashRates,
    required this.transactionRates,
  });

  factory BankRatesResponse.fromJson(Map<String, dynamic> json) {
    return BankRatesResponse(
      bankCode: json['bank_code'],
      bankName: json['bank_name'],
      cashRates: (json['cash_rate'] as List)
          .map((e) => BankCurrencyRate.fromJson(e))
          .toList(),
      transactionRates: (json['transaction_rate'] as List)
          .map((e) => BankCurrencyRate.fromJson(e))
          .toList(),
    );
  }
}
