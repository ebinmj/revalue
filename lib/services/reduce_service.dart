import 'dart:io';

import '../models/repair_analysis_result.dart';
import '../models/repair_estimate.dart';

abstract class ReduceService {
  Future<RepairAnalysisResult> analyzeForRepair({
    required File image,
    required String problemDescription,
  });
}

class MockReduceService implements ReduceService {
  const MockReduceService();

  @override
  Future<RepairAnalysisResult> analyzeForRepair({
    required File image,
    required String problemDescription,
  }) async {
    // Deterministic simulation delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    final isLaptop =
        problemDescription.toLowerCase().contains('laptop') ||
        problemDescription.toLowerCase().contains('turn on') ||
        problemDescription.toLowerCase().contains('screen') ||
        problemDescription.toLowerCase().contains('computer');

    if (isLaptop) {
      return const RepairAnalysisResult(
        product: 'Laptop',
        condition: 'Broken / partially functional',
        reportedProblem: 'Does not turn on',
        possibleIssue: 'Possible power-related issue',
        repairability: 'Potentially repairable',
        repairabilityExplanation:
            'The device may contain repairable components, but the exact fault needs to be verified.',
        potentialRepairAreas: [
          'Battery',
          'Charger',
          'Power circuit',
          'RAM',
          'Motherboard',
        ],
        estimate: RepairEstimate(
          minimumCost: 2000,
          maximumCost: 3000,
          partsCost: 1500,
          labourCost: 500,
          serviceCost: 0,
          replacementCost: 25000,
          currency: 'INR',
          repairTime: '1–3 days',
          explanation:
              'Repairing the power circuit or port could extend the lifespan and avoid replacing the whole device.',
        ),
        replacementEstimateMin: 20000,
        replacementEstimateMax: 25000,
        comparisonExplanation:
            'Repair may be worth considering because the estimated repair cost is substantially lower than replacing the device.',
        wasteAvoidedExplanation:
            'Repairing this item may extend its useful life, avoid replacing the complete device, and reduce potential electronic waste.',
      );
    }

    return RepairAnalysisResult(
      product: 'Electronic Device',
      condition: 'Broken / partially functional',
      reportedProblem:
          problemDescription.isNotEmpty
              ? problemDescription
              : 'Malfunctioning or damaged item',
      possibleIssue: 'Possible component-level electrical or physical defect',
      repairability: 'Potentially repairable',
      repairabilityExplanation:
          'Component inspection and targeted servicing could extend the item lifecycle, subject to parts availability.',
      potentialRepairAreas: const [
        'Internal wiring',
        'Power connector',
        'Controller board',
      ],
      estimate: const RepairEstimate(
        minimumCost: 1200,
        maximumCost: 2400,
        partsCost: 1000,
        labourCost: 600,
        serviceCost: 0,
        replacementCost: 18000,
        currency: 'INR',
        repairTime: '1–3 days',
        explanation: 'Targeted repair may restore functionality.',
      ),
      replacementEstimateMin: 15000,
      replacementEstimateMax: 20000,
      comparisonExplanation:
          'Repair may be worth considering because the estimated repair cost is significantly lower than replacing the device.',
      wasteAvoidedExplanation:
          'Repairing this item extends its useful life and prevents premature disposal.',
    );
  }
}
