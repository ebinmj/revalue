import 'four_r_assessment.dart';

class FourRRecommendation {
  const FourRRecommendation({
    required this.reduce,
    required this.reuse,
    required this.recycle,
    required this.riddance,
    required this.recommendationTitle,
    required this.recommendationExplanation,
    required this.primaryAction,
  });

  final FourRAssessment reduce;
  final FourRAssessment reuse;
  final FourRAssessment recycle;
  final FourRAssessment riddance;
  final String recommendationTitle;
  final String recommendationExplanation;
  final String primaryAction;

  FourRRecommendation copyWith({
    FourRAssessment? reduce,
    FourRAssessment? reuse,
    FourRAssessment? recycle,
    FourRAssessment? riddance,
    String? recommendationTitle,
    String? recommendationExplanation,
    String? primaryAction,
  }) {
    return FourRRecommendation(
      reduce: reduce ?? this.reduce,
      reuse: reuse ?? this.reuse,
      recycle: recycle ?? this.recycle,
      riddance: riddance ?? this.riddance,
      recommendationTitle: recommendationTitle ?? this.recommendationTitle,
      recommendationExplanation:
          recommendationExplanation ?? this.recommendationExplanation,
      primaryAction: primaryAction ?? this.primaryAction,
    );
  }

  Map<String, dynamic> toJson() => {
    'reduce': reduce.toJson(),
    'reuse': reuse.toJson(),
    'recycle': recycle.toJson(),
    'riddance': riddance.toJson(),
    'recommendationTitle': recommendationTitle,
    'recommendationExplanation': recommendationExplanation,
    'primaryAction': primaryAction,
  };

  factory FourRRecommendation.fromJson(Map<String, dynamic> json) {
    FourRAssessment assessment(String key, String type) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return FourRAssessment.fromJson(value);
      }
      return FourRAssessment(
        type: type,
        score: 0,
        title: type,
        explanation: '',
        recommendedAction: '',
      );
    }

    return FourRRecommendation(
      reduce: assessment('reduce', 'reduce'),
      reuse: assessment('reuse', 'reuse'),
      recycle: assessment('recycle', 'recycle'),
      riddance: assessment('riddance', 'riddance'),
      recommendationTitle: json['recommendationTitle'] as String? ?? '',
      recommendationExplanation:
          json['recommendationExplanation'] as String? ?? '',
      primaryAction: json['primaryAction'] as String? ?? '',
    );
  }
}
