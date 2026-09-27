import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:re_value/services/analysis_service.dart';
import 'package:re_value/services/revalue_engine.dart';

void main() {
  test('mock analysis produces structured laptop facts', () async {
    final analysis = await const MockAnalysisService().analyzeItem(
      image: File('laptop.jpg'),
      description: "Old laptop. It doesn't turn on.",
    );

    expect(analysis.category, 'Laptop');
    expect(analysis.problem, 'Possible power-related issue');
    expect(analysis.visibleComponents, contains('RAM'));
  });

  test(
    'ReValue engine returns deterministic laptop recommendation scores',
    () async {
      final analysis = await const MockAnalysisService().analyzeItem(
        image: File('laptop.jpg'),
        description: 'Old laptop',
      );
      final recommendation = const RevalueEngine().evaluate(analysis);

      expect(recommendation.reduce.score, 84);
      expect(recommendation.reuse.score, 78);
      expect(recommendation.recycle.score, 61);
      expect(recommendation.riddance.score, 25);
      expect(recommendation.primaryAction, 'repair');
    },
  );
}
