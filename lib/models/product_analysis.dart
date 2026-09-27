class ProductAnalysis {
  const ProductAnalysis({
    required this.category,
    this.brand,
    this.model,
    required this.condition,
    required this.problem,
    required this.visibleComponents,
    required this.possibleMaterials,
    required this.riskFactors,
  });

  final String category;
  final String? brand;
  final String? model;
  final String condition;
  final String problem;
  final List<String> visibleComponents;
  final List<String> possibleMaterials;
  final List<String> riskFactors;

  ProductAnalysis copyWith({
    String? category,
    String? brand,
    String? model,
    String? condition,
    String? problem,
    List<String>? visibleComponents,
    List<String>? possibleMaterials,
    List<String>? riskFactors,
  }) {
    return ProductAnalysis(
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      condition: condition ?? this.condition,
      problem: problem ?? this.problem,
      visibleComponents: visibleComponents ?? this.visibleComponents,
      possibleMaterials: possibleMaterials ?? this.possibleMaterials,
      riskFactors: riskFactors ?? this.riskFactors,
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'brand': brand,
    'model': model,
    'condition': condition,
    'problem': problem,
    'visibleComponents': List<String>.from(visibleComponents),
    'possibleMaterials': List<String>.from(possibleMaterials),
    'riskFactors': List<String>.from(riskFactors),
  };

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    return ProductAnalysis(
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      condition: json['condition'] as String? ?? '',
      problem: json['problem'] as String? ?? '',
      visibleComponents: _stringList(json['visibleComponents']),
      possibleMaterials: _stringList(json['possibleMaterials']),
      riskFactors: _stringList(json['riskFactors']),
    );
  }
}

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? []).whereType<String>().toList();
