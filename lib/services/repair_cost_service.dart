import '../models/product_analysis.dart';
import '../models/repair_estimate.dart';

abstract class RepairCostService {
  RepairEstimate estimateFor(ProductAnalysis analysis);
}

class MockRepairCostService implements RepairCostService {
  const MockRepairCostService();

  @override
  RepairEstimate estimateFor(ProductAnalysis analysis) {
    final isLaptop = analysis.category.toLowerCase().contains('laptop');

    if (isLaptop) {
      return const RepairEstimate(
        minimumCost: 2000,
        maximumCost: 3000,
        partsCost: 1500,
        labourCost: 800,
        serviceCost: 500,
        replacementCost: 25000,
        currency: 'INR',
        repairTime: '2–4 business days',
        explanation:
            'Repairing the power delivery circuit or charging socket can restore normal operation at an estimated fraction of replacement cost.',
      );
    }

    return const RepairEstimate(
      minimumCost: 1000,
      maximumCost: 2500,
      partsCost: 800,
      labourCost: 700,
      serviceCost: 400,
      replacementCost: 15000,
      currency: 'INR',
      repairTime: '1–3 business days',
      explanation:
          'Component inspection and targeted servicing could extend the item lifecycle.',
    );
  }
}
