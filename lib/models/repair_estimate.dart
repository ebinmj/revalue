class RepairEstimate {
  const RepairEstimate({
    required this.minimumCost,
    required this.maximumCost,
    required this.partsCost,
    required this.labourCost,
    required this.serviceCost,
    required this.replacementCost,
    required this.currency,
    required this.repairTime,
    required this.explanation,
  });

  final double minimumCost;
  final double maximumCost;
  final double partsCost;
  final double labourCost;
  final double serviceCost;
  final double replacementCost;
  final String currency;
  final String repairTime;
  final String explanation;

  RepairEstimate copyWith({
    double? minimumCost,
    double? maximumCost,
    double? partsCost,
    double? labourCost,
    double? serviceCost,
    double? replacementCost,
    String? currency,
    String? repairTime,
    String? explanation,
  }) {
    return RepairEstimate(
      minimumCost: minimumCost ?? this.minimumCost,
      maximumCost: maximumCost ?? this.maximumCost,
      partsCost: partsCost ?? this.partsCost,
      labourCost: labourCost ?? this.labourCost,
      serviceCost: serviceCost ?? this.serviceCost,
      replacementCost: replacementCost ?? this.replacementCost,
      currency: currency ?? this.currency,
      repairTime: repairTime ?? this.repairTime,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() => {
    'minimumCost': minimumCost,
    'maximumCost': maximumCost,
    'partsCost': partsCost,
    'labourCost': labourCost,
    'serviceCost': serviceCost,
    'replacementCost': replacementCost,
    'currency': currency,
    'repairTime': repairTime,
    'explanation': explanation,
  };

  factory RepairEstimate.fromJson(Map<String, dynamic> json) {
    double value(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return RepairEstimate(
      minimumCost: value('minimumCost'),
      maximumCost: value('maximumCost'),
      partsCost: value('partsCost'),
      labourCost: value('labourCost'),
      serviceCost: value('serviceCost'),
      replacementCost: value('replacementCost'),
      currency: json['currency'] as String? ?? 'INR',
      repairTime: json['repairTime'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
