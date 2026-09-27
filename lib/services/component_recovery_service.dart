import '../models/product_analysis.dart';
import '../models/reusable_component.dart';

abstract class ComponentRecoveryService {
  List<ReusableComponent> findPotentialComponents(ProductAnalysis analysis);
}

class MockComponentRecoveryService implements ComponentRecoveryService {
  const MockComponentRecoveryService();

  @override
  List<ReusableComponent> findPotentialComponents(ProductAnalysis analysis) {
    final isLaptop = analysis.category.toLowerCase().contains('laptop');
    if (!isLaptop) {
      return analysis.visibleComponents.map((component) {
        return ReusableComponent(
          name: component,
          condition: 'Potential recovery candidate',
          reusePotential: 'Can be evaluated for component-level reuse.',
          estimatedMinimumValue: 500,
          estimatedMaximumValue: 1200,
          currency: 'INR',
          action: 'Find buyers',
        );
      }).toList();
    }

    return const [
      ReusableComponent(
        name: 'RAM',
        condition: 'Potentially reusable',
        reusePotential: 'May be reusable in a compatible laptop or mini-PC.',
        estimatedMinimumValue: 800,
        estimatedMaximumValue: 1500,
        currency: 'INR',
        action: 'Find buyers',
      ),
      ReusableComponent(
        name: 'SSD',
        condition: 'Potentially reusable',
        reusePotential:
            'May be reusable after secure data removal and health check.',
        estimatedMinimumValue: 1500,
        estimatedMaximumValue: 3000,
        currency: 'INR',
        action: 'Find buyers',
      ),
      ReusableComponent(
        name: 'Display',
        condition: 'Potentially reusable',
        reusePotential:
            'May help repair a compatible model if the panel is undamaged.',
        estimatedMinimumValue: 1800,
        estimatedMaximumValue: 3500,
        currency: 'INR',
        action: 'Find buyers',
      ),
      ReusableComponent(
        name: 'Keyboard',
        condition: 'Potentially reusable',
        reusePotential:
            'May be useful as a replacement part for the same model family.',
        estimatedMinimumValue: 500,
        estimatedMaximumValue: 1200,
        currency: 'INR',
        action: 'Find buyers',
      ),
      ReusableComponent(
        name: 'Battery',
        condition: 'Handle with care',
        reusePotential:
            'May be reusable only after professional health and safety checks.',
        estimatedMinimumValue: 500,
        estimatedMaximumValue: 1200,
        currency: 'INR',
        action: 'Service assessment',
      ),
      ReusableComponent(
        name: 'Charger',
        condition: 'Potentially reusable',
        reusePotential:
            'May be reusable with a compatible voltage, connector and model.',
        estimatedMinimumValue: 700,
        estimatedMaximumValue: 1500,
        currency: 'INR',
        action: 'Find buyers',
      ),
      ReusableComponent(
        name: 'Motherboard',
        condition: 'Condition needs testing',
        reusePotential:
            'May provide donor repair parts, but compatibility is not guaranteed.',
        estimatedMinimumValue: 1000,
        estimatedMaximumValue: 2500,
        currency: 'INR',
        action: 'Find buyers',
      ),
    ];
  }
}
