class BankCurrencyRate {

  final String currencyCode;
  final String currencyName;
  final double buying;
  final double selling;


  BankCurrencyRate({

    required this.currencyCode,
    required this.currencyName,
    required this.buying,
    required this.selling,
  });

  factory BankCurrencyRate.fromJson(Map<String, dynamic> json) {
    //print("JSON: $json");
    return BankCurrencyRate(
      currencyCode: json['currency_code'],
      currencyName: json['currency_name'],
      buying: (json['buying'] as num).toDouble(),
      selling: (json['selling'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'currency_code': currencyCode,
    'currency_name': currencyName,
    'buying': buying,
    'selling': selling,
  };
}
