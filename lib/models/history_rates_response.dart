import 'rate.dart';

class HistoryRatesResponse {
  final String bankCode;
  final String bankName;
  final String currencyCode;
  final String currencyName;
  final List<Rate> cashRates;
  final List<Rate> transactionRates;

  HistoryRatesResponse({
    required this.bankCode,
    required this.bankName,
    required this.currencyCode,
    required this.currencyName,
    required this.cashRates,
    required this.transactionRates,
  });

  factory HistoryRatesResponse.fromJson(Map<String, dynamic> json) {
    return HistoryRatesResponse(
      bankCode: json['bank_code'],
      bankName: json['bank_name'],
      currencyCode: json['currency_code'],
      currencyName: json['currency_name'],
      cashRates: (json['cash_rate'] as List<dynamic>)
          .map((e) => Rate.fromJson(e))
          .toList(),
      transactionRates: (json['transaction_rate'] as List<dynamic>)
          .map((e) => Rate.fromJson(e))
          .toList(),
    );
  }
}
