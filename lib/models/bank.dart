class Bank {
  final String bankCode;
  final String bankName;
  final String? bankLogo;

  Bank({
    required this.bankCode,
    required this.bankName,
    this.bankLogo,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      bankCode: json['bank_code'],
      bankName: json['bank_name'],
      bankLogo: json['bank_logo'],
    );
  }
}
