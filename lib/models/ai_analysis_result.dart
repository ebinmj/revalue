class RecoveryRecommendationResult {
  const RecoveryRecommendationResult({
    required this.recommendation,
    required this.reason,
  });

  final String recommendation;
  final String reason;

  factory RecoveryRecommendationResult.fromJson(Object? value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('Missing or invalid "$field" recommendation.');
    }
    final recommendation = value['recommendation'];
    final reason = value['reason'];
    if (recommendation is! String ||
        recommendation.trim().isEmpty ||
        reason is! String ||
        reason.trim().isEmpty) {
      throw FormatException('Missing fields in "$field" recommendation.');
    }
    return RecoveryRecommendationResult(
      recommendation: recommendation,
      reason: reason,
    );
  }
}

class AiAnalysisResult {
  const AiAnalysisResult({
    required this.identifiedItem,
    required this.summary,
    required this.possibleProblem,
    required this.confidence,
    required this.reduce,
    required this.reuse,
    required this.recycle,
    required this.riddance,
    required this.followUpQuestions,
  });

  static const confidenceLevels = {'high', 'medium', 'low'};

  final String identifiedItem;
  final String summary;
  final String possibleProblem;
  final String confidence;
  final RecoveryRecommendationResult reduce;
  final RecoveryRecommendationResult reuse;
  final RecoveryRecommendationResult recycle;
  final RecoveryRecommendationResult riddance;
  final List<String> followUpQuestions;

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    String requiredString(String field) {
      final value = json[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing or invalid "$field" in AI response.');
      }
      return value;
    }

    final confidence = requiredString('confidence');
    if (!confidenceLevels.contains(confidence)) {
      throw const FormatException(
        'AI response confidence must be high, medium, or low.',
      );
    }

    final questions = json['follow_up_questions'];
    if (questions is! List ||
        questions.any((question) => question is! String)) {
      throw const FormatException(
        'AI response follow-up questions are invalid.',
      );
    }

    return AiAnalysisResult(
      identifiedItem: requiredString('identified_item'),
      summary: requiredString('summary'),
      possibleProblem: requiredString('possible_problem'),
      confidence: confidence,
      reduce: RecoveryRecommendationResult.fromJson(json['reduce'], 'reduce'),
      reuse: RecoveryRecommendationResult.fromJson(json['reuse'], 'reuse'),
      recycle: RecoveryRecommendationResult.fromJson(
        json['recycle'],
        'recycle',
      ),
      riddance: RecoveryRecommendationResult.fromJson(
        json['riddance'],
        'riddance',
      ),
      followUpQuestions: List<String>.from(questions),
    );
  }
}
