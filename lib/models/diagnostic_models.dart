/// Data models for the interactive AI diagnostic conversation flow.
library;

class DiagnosticFinalRecommendation {
  const DiagnosticFinalRecommendation({
    required this.repairability,
    required this.repairabilityScore,
    required this.possibleIssue,
    required this.repairAreas,
    required this.repairExplanation,
    required this.recommended4r,
    required this.recommendedAction,
    required this.wasteImpact,
  });

  final String repairability;
  final int repairabilityScore;
  final String possibleIssue;
  final List<String> repairAreas;
  final String repairExplanation;
  final String recommended4r;
  final String recommendedAction;
  final String wasteImpact;

  factory DiagnosticFinalRecommendation.fromJson(Map<String, dynamic> json) {
    return DiagnosticFinalRecommendation(
      repairability: json['repairability'] as String? ?? 'Unknown',
      repairabilityScore: (json['repairability_score'] as num?)?.toInt() ?? 50,
      possibleIssue: json['possible_issue'] as String? ?? '',
      repairAreas: _stringList(json['repair_areas']),
      repairExplanation: json['repair_explanation'] as String? ?? '',
      recommended4r: json['recommended_4r'] as String? ?? 'Reduce',
      recommendedAction: json['recommended_action'] as String? ?? '',
      wasteImpact: json['waste_impact'] as String? ?? '',
    );
  }
}

class DiagnosticStartResponse {
  const DiagnosticStartResponse({
    required this.sessionId,
    required this.identifiedProduct,
    required this.identifiedCondition,
    required this.aiObservation,
    required this.followUpQuestions,
    required this.isComplete,
    required this.disclaimer,
    this.finalRecommendation,
  });

  final String sessionId;
  final String identifiedProduct;
  final String identifiedCondition;
  final String aiObservation;
  final List<String> followUpQuestions;
  final bool isComplete;
  final String disclaimer;
  final DiagnosticFinalRecommendation? finalRecommendation;

  factory DiagnosticStartResponse.fromJson(Map<String, dynamic> json) {
    final rec = json['final_recommendation'];
    return DiagnosticStartResponse(
      sessionId: json['session_id'] as String,
      identifiedProduct: json['identified_product'] as String? ?? 'Unknown device',
      identifiedCondition: json['identified_condition'] as String? ?? '',
      aiObservation: json['ai_observation'] as String? ?? '',
      followUpQuestions: _stringList(json['follow_up_questions']),
      isComplete: json['is_complete'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      finalRecommendation: rec is Map<String, dynamic>
          ? DiagnosticFinalRecommendation.fromJson(rec)
          : null,
    );
  }
}

class DiagnosticContinueResponse {
  const DiagnosticContinueResponse({
    required this.sessionId,
    required this.summary,
    required this.followUpQuestions,
    required this.isComplete,
    required this.disclaimer,
    this.finalRecommendation,
  });

  final String sessionId;
  final String summary;
  final List<String> followUpQuestions;
  final bool isComplete;
  final String disclaimer;
  final DiagnosticFinalRecommendation? finalRecommendation;

  factory DiagnosticContinueResponse.fromJson(Map<String, dynamic> json) {
    final rec = json['final_recommendation'];
    return DiagnosticContinueResponse(
      sessionId: json['session_id'] as String,
      summary: json['summary'] as String? ?? '',
      followUpQuestions: _stringList(json['follow_up_questions']),
      isComplete: json['is_complete'] as bool? ?? false,
      disclaimer: json['disclaimer'] as String? ?? '',
      finalRecommendation: rec is Map<String, dynamic>
          ? DiagnosticFinalRecommendation.fromJson(rec)
          : null,
    );
  }
}

/// A single message bubble in the diagnostic chat.
class DiagnosticMessage {
  const DiagnosticMessage({
    required this.role,
    required this.text,
    this.questions = const [],
    this.isLoading = false,
  });

  /// 'ai' or 'user'
  final String role;
  final String text;

  /// Non-empty for AI messages that contain follow-up questions.
  final List<String> questions;

  /// True while awaiting API response.
  final bool isLoading;

  bool get isAi => role == 'ai';
}

List<String> _stringList(Object? value) =>
    (value as List<dynamic>? ?? []).whereType<String>().toList();
