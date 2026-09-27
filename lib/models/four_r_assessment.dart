class FourRAssessment {
  FourRAssessment({
    required this.type,
    required this.score,
    required this.title,
    required this.explanation,
    required this.recommendedAction,
  }) : assert(_allowedTypes.contains(type), 'Invalid ReValue pathway type'),
       assert(score >= 0 && score <= 100, 'Score must be between 0 and 100');

  static const _allowedTypes = {'reduce', 'reuse', 'recycle', 'riddance'};

  final String type;
  final int score;
  final String title;
  final String explanation;
  final String recommendedAction;

  FourRAssessment copyWith({
    String? type,
    int? score,
    String? title,
    String? explanation,
    String? recommendedAction,
  }) {
    return FourRAssessment(
      type: type ?? this.type,
      score: score ?? this.score,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      recommendedAction: recommendedAction ?? this.recommendedAction,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'score': score,
    'title': title,
    'explanation': explanation,
    'recommendedAction': recommendedAction,
  };

  factory FourRAssessment.fromJson(Map<String, dynamic> json) {
    return FourRAssessment(
      type: json['type'] as String? ?? 'riddance',
      score: (json['score'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
    );
  }
}
