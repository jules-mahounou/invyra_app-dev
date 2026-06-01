class SubscriptionPlan {
  final String id;
  final String code;
  final String name;
  final String? description;
  final int price;
  final String? billingPeriod;
  final int? maxEvents;
  final int? maxGuestsPerEvent;
  final bool allowsPremiumTemplates;
  final List<String> features;
  final bool isPopular;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.price,
    this.billingPeriod,
    this.maxEvents,
    this.maxGuestsPerEvent,
    required this.allowsPremiumTemplates,
    required this.features,
    required this.isPopular,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <String>[];
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        if (item != null) {
          features.add(item.toString());
        }
      }
    }

    return SubscriptionPlan(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      billingPeriod: json['billing_period'] as String?,
      maxEvents: json['max_events'] as int?,
      maxGuestsPerEvent: json['max_guests_per_event'] as int?,
      allowsPremiumTemplates: json['allows_premium_templates'] as bool? ?? false,
      features: features,
      isPopular: json['is_popular'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String get priceLabel {
    if (price == 0 && billingPeriod == null) {
      return 'Gratuit';
    }
    if (billingPeriod == 'mensuel') {
      return '${_formatFcfa(price)} F / mois';
    }
    if (billingPeriod == 'one_shot') {
      return 'One-Shot';
    }
    return '${_formatFcfa(price)} F';
  }

  static String _formatFcfa(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
