import 'analysis_data.dart';

enum RecoveryPath { reduce, reuse, recycle, riddance }

class LegacyFourRRecommendation {
  const LegacyFourRRecommendation({
    required this.path,
    required this.score,
    required this.title,
    required this.explanation,
    required this.recommendedAction,
  });

  final RecoveryPath path;
  final int score;
  final String title;
  final String explanation;
  final String recommendedAction;

  factory LegacyFourRRecommendation.fromJson(Map<String, dynamic> json) {
    final path = switch ((json['path'] as String? ?? '').toLowerCase()) {
      'reduce' => RecoveryPath.reduce,
      'reuse' => RecoveryPath.reuse,
      'recycle' => RecoveryPath.recycle,
      _ => RecoveryPath.riddance,
    };
    return LegacyFourRRecommendation(
      path: path,
      score: (json['score'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Recovery option',
      explanation: json['explanation'] as String? ?? '',
      recommendedAction: json['recommended_action'] as String? ?? '',
    );
  }
}

class ReValueRecommendation {
  const ReValueRecommendation({
    required this.bestNextStep,
    required this.why,
    required this.options,
  });

  final LegacyFourRRecommendation bestNextStep;
  final String why;
  final List<LegacyFourRRecommendation> options;

  // Deterministic MVP rules. Scores are recommendation scores, not probabilities.
  factory ReValueRecommendation.fromAnalysis(AnalysisData analysis) {
    final category = analysis.detectedCategory.toLowerCase();
    final isElectronic =
        category.contains('laptop') ||
        category.contains('electronic') ||
        category.contains('computer') ||
        category.contains('phone');
    final hasRecoverableParts = analysis.visibleComponents.length >= 3;
    final hasBatteryRisk = analysis.riskFactors.any(
      (risk) => risk.toLowerCase().contains('battery'),
    );

    final reduceScore = isElectronic ? 84 : (hasRecoverableParts ? 72 : 58);
    final reuseScore = isElectronic && hasRecoverableParts ? 78 : 62;
    final recycleScore = isElectronic ? 61 : 55;
    final riddanceScore = hasBatteryRisk ? 25 : 30;

    final options = [
      LegacyFourRRecommendation(
        path: RecoveryPath.reduce,
        score: reduceScore,
        title: 'Repair may be more valuable than replacing the entire item.',
        explanation: 'The reported condition suggests the item may still have useful life.',
        recommendedAction: 'Get a repair estimate before replacing it.',
      ),
      LegacyFourRRecommendation(
        path: RecoveryPath.reuse,
        score: reuseScore,
        title: 'Several components may still have recovery or resale value.',
        explanation: 'Visible components can potentially be reused even if the whole item is not working.',
        recommendedAction: 'Recover, donate or resell usable components.',
      ),
      LegacyFourRRecommendation(
        path: RecoveryPath.recycle,
        score: recycleScore,
        title:
            'Electronic materials and components can potentially be recovered.',
        explanation: 'Recycling is a useful fallback when repair or component reuse is not practical.',
        recommendedAction: 'Find a certified electronics recycling pathway.',
      ),
      LegacyFourRRecommendation(
        path: RecoveryPath.riddance,
        score: riddanceScore,
        title: 'Responsible disposal should be the last resort.',
        explanation: 'Disposal is less valuable while repair or recovery options remain available.',
        recommendedAction:
            'Use responsible e-waste disposal for unrecoverable parts.',
      ),
    ];

    final bestNextStep = options.reduce(
      (best, option) => option.score > best.score ? option : best,
    );

    return ReValueRecommendation(
      bestNextStep: bestNextStep,
      why: 'Repair and component recovery score highest because the item is partially functional and has multiple visible recoverable parts.',
      options: options,
    );
  }
}
