import 'repair_estimate.dart';

class RepairAnalysisResult {
  const RepairAnalysisResult({
    required this.product,
    required this.condition,
    required this.reportedProblem,
    required this.possibleIssue,
    required this.repairability,
    required this.repairabilityExplanation,
    required this.potentialRepairAreas,
    required this.estimate,
    required this.replacementEstimateMin,
    required this.replacementEstimateMax,
    required this.comparisonExplanation,
    this.wasteAvoidedExplanation =
        'Repairing this item may extend its useful life, avoid replacing the complete device, and reduce potential electronic waste.',
  });

  final String product;
  final String condition;
  final String reportedProblem;
  final String possibleIssue;
  final String repairability;
  final String repairabilityExplanation;
  final List<String> potentialRepairAreas;
  final RepairEstimate estimate;
  final double replacementEstimateMin;
  final double replacementEstimateMax;
  final String comparisonExplanation;
  final String wasteAvoidedExplanation;

  Map<String, dynamic> toJson() => {
    'product': product,
    'condition': condition,
    'reportedProblem': reportedProblem,
    'possibleIssue': possibleIssue,
    'repairability': repairability,
    'repairabilityExplanation': repairabilityExplanation,
    'potentialRepairAreas': List<String>.from(potentialRepairAreas),
    'estimate': estimate.toJson(),
    'replacementEstimateMin': replacementEstimateMin,
    'replacementEstimateMax': replacementEstimateMax,
    'comparisonExplanation': comparisonExplanation,
    'wasteAvoidedExplanation': wasteAvoidedExplanation,
  };

  factory RepairAnalysisResult.fromJson(Map<String, dynamic> json) {
    return RepairAnalysisResult(
      product: json['product'] as String? ?? 'Item',
      condition: json['condition'] as String? ?? '',
      reportedProblem: json['reportedProblem'] as String? ?? '',
      possibleIssue: json['possibleIssue'] as String? ?? '',
      repairability:
          json['repairability'] as String? ?? 'Potentially repairable',
      repairabilityExplanation:
          json['repairabilityExplanation'] as String? ?? '',
      potentialRepairAreas:
          (json['potentialRepairAreas'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
      estimate: json['estimate'] is Map<String, dynamic>
          ? RepairEstimate.fromJson(json['estimate'] as Map<String, dynamic>)
          : const RepairEstimate(
            minimumCost: 2000,
            maximumCost: 3000,
            partsCost: 1500,
            labourCost: 800,
            serviceCost: 500,
            replacementCost: 25000,
            currency: 'INR',
            repairTime: '1–3 days',
            explanation: '',
          ),
      replacementEstimateMin:
          (json['replacementEstimateMin'] as num?)?.toDouble() ?? 20000,
      replacementEstimateMax:
          (json['replacementEstimateMax'] as num?)?.toDouble() ?? 25000,
      comparisonExplanation: json['comparisonExplanation'] as String? ?? '',
      wasteAvoidedExplanation: json['wasteAvoidedExplanation'] as String? ?? '',
    );
  }
}
