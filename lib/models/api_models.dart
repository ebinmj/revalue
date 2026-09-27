import 'analysis_data.dart';
import 'marketplace_listing.dart';
import 'repair_cost_estimate.dart';
import 'revalue_recommendation.dart';

class ApiAnalysisResponse {
  const ApiAnalysisResponse({required this.analysis, required this.disclaimer});

  final AnalysisData analysis;
  final String disclaimer;

  factory ApiAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return ApiAnalysisResponse(
      analysis: AnalysisData(
        detectedCategory:
            json['detected_category'] as String? ?? 'Unknown product',
        condition: json['condition'] as String? ?? 'Unknown condition',
        possibleIssue:
            json['possible_issue'] as String? ??
            'Possible issue could not be determined.',
        visibleComponents: _stringList(json['visible_components']),
        possibleMaterials: _stringList(json['possible_materials']),
        riskFactors: _stringList(json['risk_factors']),
      ),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class ApiRecommendationResponse {
  const ApiRecommendationResponse({
    required this.recommendation,
    required this.disclaimer,
  });

  final ReValueRecommendation recommendation;
  final String disclaimer;

  factory ApiRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegacyFourRRecommendation.fromJson)
        .toList();
    final best = options.isNotEmpty
        ? options.reduce(
            (current, option) =>
                option.score > current.score ? option : current,
          )
        : const LegacyFourRRecommendation(
            path: RecoveryPath.riddance,
            score: 0,
            title: 'No recommendation is available.',
            explanation: 'The backend did not return any recovery paths.',
            recommendedAction: 'Try again when the backend is available.',
          );
    return ApiRecommendationResponse(
      recommendation: ReValueRecommendation(
        bestNextStep: best,
        why: json['why'] as String? ?? 'No explanation was returned.',
        options: options,
      ),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class ApiRepairEstimateResponse {
  const ApiRepairEstimateResponse({
    required this.estimate,
    required this.disclaimer,
  });

  final RepairCostEstimate estimate;
  final String disclaimer;

  factory ApiRepairEstimateResponse.fromJson(Map<String, dynamic> json) {
    int value(String key) => (json[key] as num?)?.toInt() ?? 0;
    return ApiRepairEstimateResponse(
      estimate: RepairCostEstimate(
        partsMin: value('parts_min'),
        partsMax: value('parts_max'),
        labourMin: value('labour_min'),
        labourMax: value('labour_max'),
        serviceMin: value('service_min'),
        serviceMax: value('service_max'),
        replacementFrom: value('replacement_from'),
        potentialValueRetainedFrom: value('potential_value_retained_from'),
      ),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

class ApiMarketplaceResponse {
  const ApiMarketplaceResponse({
    required this.listings,
    required this.disclaimer,
  });

  final List<MarketplaceListing> listings;
  final String disclaimer;

  factory ApiMarketplaceResponse.fromJson(Map<String, dynamic> json) {
    return ApiMarketplaceResponse(
      listings: (json['listings'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (listing) => MarketplaceListing(
              title: listing['title'] as String? ?? 'Untitled listing',
              price: (listing['price'] as num?)?.toDouble() ?? 0,
              condition: listing['condition'] as String? ?? 'Unknown condition',
              category: listing['category'] as String? ?? 'Other',
              description: listing['title'] as String? ?? '',
              seller: listing['seller'] as String? ?? 'Unknown seller',
            ),
          )
          .toList(),
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? []).whereType<String>().toList();
