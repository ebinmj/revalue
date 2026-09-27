import 'dart:io';

import '../models/product_analysis.dart';

abstract class AnalysisService {
  Future<ProductAnalysis> analyzeItem({
    required File image,
    required String description,
  });
}

class MockAnalysisService implements AnalysisService {
  const MockAnalysisService();

  @override
  Future<ProductAnalysis> analyzeItem({
    required File image,
    required String description,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return const ProductAnalysis(
      category: 'Laptop',
      condition: 'Broken / partially functional',
      problem: 'Possible power-related issue',
      visibleComponents: [
        'RAM',
        'SSD',
        'Display',
        'Keyboard',
        'Battery',
        'Charger',
      ],
      possibleMaterials: [
        'Aluminium',
        'Plastic',
        'Copper',
        'Electronic components',
      ],
      riskFactors: ['Battery may require careful handling'],
    );
  }
}
