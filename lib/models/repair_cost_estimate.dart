class RepairCostEstimate {
  const RepairCostEstimate({
    required this.partsMin,
    required this.partsMax,
    required this.labourMin,
    required this.labourMax,
    required this.serviceMin,
    required this.serviceMax,
    required this.replacementFrom,
    required this.potentialValueRetainedFrom,
  });

  final int partsMin;
  final int partsMax;
  final int labourMin;
  final int labourMax;
  final int serviceMin;
  final int serviceMax;
  final int replacementFrom;
  final int potentialValueRetainedFrom;

  int get repairTotalMin => partsMin + labourMin + serviceMin;
  int get repairTotalMax => partsMax + labourMax + serviceMax;
}
