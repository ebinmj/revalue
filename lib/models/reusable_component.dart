class ReusableComponent {
  const ReusableComponent({
    required this.name,
    required this.condition,
    required this.reusePotential,
    required this.estimatedMinimumValue,
    required this.estimatedMaximumValue,
    required this.currency,
    required this.action,
  });

  final String name;
  final String condition;
  final String reusePotential;
  final double estimatedMinimumValue;
  final double estimatedMaximumValue;
  final String currency;
  final String action;

  ReusableComponent copyWith({
    String? name,
    String? condition,
    String? reusePotential,
    double? estimatedMinimumValue,
    double? estimatedMaximumValue,
    String? currency,
    String? action,
  }) {
    return ReusableComponent(
      name: name ?? this.name,
      condition: condition ?? this.condition,
      reusePotential: reusePotential ?? this.reusePotential,
      estimatedMinimumValue:
          estimatedMinimumValue ?? this.estimatedMinimumValue,
      estimatedMaximumValue:
          estimatedMaximumValue ?? this.estimatedMaximumValue,
      currency: currency ?? this.currency,
      action: action ?? this.action,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'condition': condition,
    'reusePotential': reusePotential,
    'estimatedMinimumValue': estimatedMinimumValue,
    'estimatedMaximumValue': estimatedMaximumValue,
    'currency': currency,
    'action': action,
  };

  factory ReusableComponent.fromJson(Map<String, dynamic> json) {
    double value(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return ReusableComponent(
      name: json['name'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      reusePotential:
          json['reusePotential'] as String? ?? 'Potentially reusable',
      estimatedMinimumValue: value('estimatedMinimumValue'),
      estimatedMaximumValue: value('estimatedMaximumValue'),
      currency: json['currency'] as String? ?? 'INR',
      action: json['action'] as String? ?? '',
    );
  }
}
