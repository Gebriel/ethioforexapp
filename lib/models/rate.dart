class Rate {
  final double? buying;
  final double? selling;
  final DateTime? updated;

  Rate({this.buying, this.selling, this.updated});

  factory Rate.fromJson(Map<String, dynamic> json) {
    return Rate(
      buying: (json['buying'] as num?)?.toDouble(),
      selling: (json['selling'] as num?)?.toDouble(),
      updated: json['updated'] != null ? DateTime.parse(json['updated']) : null,
    );
  }
}
