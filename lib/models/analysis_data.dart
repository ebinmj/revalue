class AnalysisData {
  const AnalysisData({
    required this.detectedCategory,
    required this.condition,
    required this.possibleIssue,
    required this.visibleComponents,
    required this.possibleMaterials,
    required this.riskFactors,
  });

  final String detectedCategory;
  final String condition;
  final String possibleIssue;
  final List<String> visibleComponents;
  final List<String> possibleMaterials;
  final List<String> riskFactors;
}
