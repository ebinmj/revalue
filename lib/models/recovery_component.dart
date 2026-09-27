class RecoveryComponent {
  const RecoveryComponent({
    required this.name,
    required this.condition,
    required this.potentialReuse,
    required this.estimatedValueMin,
    required this.estimatedValueMax,
    required this.action,
  });

  final String name;
  final String condition;
  final String potentialReuse;
  final int estimatedValueMin;
  final int estimatedValueMax;
  final String action;
}
