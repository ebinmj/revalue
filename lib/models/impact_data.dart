class ImpactData {
  const ImpactData({
    required this.itemsAnalyzed,
    required this.itemsRepaired,
    required this.itemsReused,
    required this.itemsRecycled,
    required this.itemsDisposed,
    required this.estimatedWasteAvoidedKg,
    required this.estimatedValueRecovered,
    required this.ecoPoints,
    required this.currency,
  });

  final int itemsAnalyzed;
  final int itemsRepaired;
  final int itemsReused;
  final int itemsRecycled;
  final int itemsDisposed;
  final double estimatedWasteAvoidedKg;
  final double estimatedValueRecovered;
  final int ecoPoints;
  final String currency;

  ImpactData copyWith({
    int? itemsAnalyzed,
    int? itemsRepaired,
    int? itemsReused,
    int? itemsRecycled,
    int? itemsDisposed,
    double? estimatedWasteAvoidedKg,
    double? estimatedValueRecovered,
    int? ecoPoints,
    String? currency,
  }) {
    return ImpactData(
      itemsAnalyzed: itemsAnalyzed ?? this.itemsAnalyzed,
      itemsRepaired: itemsRepaired ?? this.itemsRepaired,
      itemsReused: itemsReused ?? this.itemsReused,
      itemsRecycled: itemsRecycled ?? this.itemsRecycled,
      itemsDisposed: itemsDisposed ?? this.itemsDisposed,
      estimatedWasteAvoidedKg:
          estimatedWasteAvoidedKg ?? this.estimatedWasteAvoidedKg,
      estimatedValueRecovered:
          estimatedValueRecovered ?? this.estimatedValueRecovered,
      ecoPoints: ecoPoints ?? this.ecoPoints,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toJson() => {
    'itemsAnalyzed': itemsAnalyzed,
    'itemsRepaired': itemsRepaired,
    'itemsReused': itemsReused,
    'itemsRecycled': itemsRecycled,
    'itemsDisposed': itemsDisposed,
    'estimatedWasteAvoidedKg': estimatedWasteAvoidedKg,
    'estimatedValueRecovered': estimatedValueRecovered,
    'ecoPoints': ecoPoints,
    'currency': currency,
  };

  factory ImpactData.fromJson(Map<String, dynamic> json) {
    int count(String key) => (json[key] as num?)?.toInt() ?? 0;
    double estimate(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return ImpactData(
      itemsAnalyzed: count('itemsAnalyzed'),
      itemsRepaired: count('itemsRepaired'),
      itemsReused: count('itemsReused'),
      itemsRecycled: count('itemsRecycled'),
      itemsDisposed: count('itemsDisposed'),
      estimatedWasteAvoidedKg: estimate('estimatedWasteAvoidedKg'),
      estimatedValueRecovered: estimate('estimatedValueRecovered'),
      ecoPoints: count('ecoPoints'),
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}
