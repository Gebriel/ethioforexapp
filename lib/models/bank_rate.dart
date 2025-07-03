class BankRate {
  final String bankCode;
  final String bankName;
  final String currencyCode;
  final String currencyName;
  final double buying;
  final double selling;
  final DateTime? updatedAt;

  BankRate({
    required this.bankCode,
    required this.bankName,
    required this.currencyCode,
    required this.currencyName,
    required this.buying,
    required this.selling,
    this.updatedAt,
  });

  factory BankRate.fromJson(Map<String, dynamic> json) {
    return BankRate(
      bankCode: json['bank_code'],
      bankName: json['bank_name'],
      currencyCode: json['currency_code'],
      currencyName: json['currency_name'],
      buying: (json['buying'] as num).toDouble(),
      selling: (json['selling'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
