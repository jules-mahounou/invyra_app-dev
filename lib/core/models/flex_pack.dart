class FlexPack {
  final String id;
  final String label;
  final int guestLimit;
  final int priceFcfa;

  const FlexPack({
    required this.id,
    required this.label,
    required this.guestLimit,
    required this.priceFcfa,
  });

  factory FlexPack.fromJson(Map<String, dynamic> json) {
    return FlexPack(
      id: json['id'] as String,
      label: json['label'] as String,
      guestLimit: (json['guest_limit'] as num).toInt(),
      priceFcfa: (json['price_fcfa'] as num).toInt(),
    );
  }
}
