import 'package:flutter_test/flutter_test.dart';
import 'package:re_value/models/four_r_assessment.dart';
import 'package:re_value/models/four_r_recommendation.dart';
import 'package:re_value/models/impact_data.dart';
import 'package:re_value/models/marketplace_listing.dart';
import 'package:re_value/models/product_analysis.dart';
import 'package:re_value/models/repair_estimate.dart';
import 'package:re_value/models/reusable_component.dart';

void main() {
  test('ProductAnalysis round trips typed facts', () {
    const analysis = ProductAnalysis(
      category: 'Laptop',
      brand: 'Example',
      model: 'Model 1',
      condition: 'Broken / partially functional',
      problem: 'Possible power-related issue',
      visibleComponents: ['RAM', 'SSD'],
      possibleMaterials: ['Aluminium'],
      riskFactors: ['Battery may require careful handling'],
    );

    final restored = ProductAnalysis.fromJson(analysis.toJson());

    expect(restored.category, 'Laptop');
    expect(restored.visibleComponents, ['RAM', 'SSD']);
    expect(restored.brand, 'Example');
  });

  test('FourRAssessment validates allowed types and score bounds', () {
    final assessment = FourRAssessment(
      type: 'reduce',
      score: 84,
      title: 'Reduce',
      explanation: 'Repair may avoid replacement.',
      recommendedAction: 'Explore repair options',
    );

    expect(FourRAssessment.fromJson(assessment.toJson()).score, 84);
    expect(
      () => FourRAssessment(
        type: 'unknown',
        score: 50,
        title: '',
        explanation: '',
        recommendedAction: '',
      ),
      throwsA(isA<AssertionError>()),
    );
  });

  test('FourRRecommendation round trips all four assessments', () {
    FourRAssessment assessment(String type, int score) => FourRAssessment(
      type: type,
      score: score,
      title: type,
      explanation: 'Explanation',
      recommendedAction: 'Action',
    );

    final recommendation = FourRRecommendation(
      reduce: assessment('reduce', 84),
      reuse: assessment('reuse', 78),
      recycle: assessment('recycle', 61),
      riddance: assessment('riddance', 25),
      recommendationTitle: 'Explore repair first.',
      recommendationExplanation: 'Repair may preserve value.',
      primaryAction: 'repair',
    );

    final restored = FourRRecommendation.fromJson(recommendation.toJson());

    expect(restored.recycle.score, 61);
    expect(restored.primaryAction, 'repair');
  });

  test('estimate, component, listing and impact models round trip', () {
    const estimate = RepairEstimate(
      minimumCost: 2500,
      maximumCost: 4000,
      partsCost: 2200,
      labourCost: 1000,
      serviceCost: 0,
      replacementCost: 25000,
      currency: 'INR',
      repairTime: '2-5 days',
      explanation: 'Estimated cost only.',
    );
    const component = ReusableComponent(
      name: '16GB RAM',
      condition: 'Good',
      reusePotential: 'Potentially reusable',
      estimatedMinimumValue: 1500,
      estimatedMaximumValue: 2500,
      currency: 'INR',
      action: 'List for reuse',
    );
    const listing = MarketplaceListing(
      id: 'listing-1',
      title: '16GB RAM',
      description: 'Used memory module',
      category: 'Components',
      price: 1800,
      condition: 'Good',
      sellerName: 'Seller',
      location: 'Local',
      tags: ['RAM'],
      matchScore: 0.88,
    );
    const impact = ImpactData(
      itemsAnalyzed: 1,
      itemsRepaired: 1,
      itemsReused: 0,
      itemsRecycled: 0,
      itemsDisposed: 0,
      estimatedWasteAvoidedKg: 2.5,
      estimatedValueRecovered: 21000,
      ecoPoints: 100,
      currency: 'INR',
    );

    expect(RepairEstimate.fromJson(estimate.toJson()).maximumCost, 4000);
    expect(ReusableComponent.fromJson(component.toJson()).name, '16GB RAM');
    expect(MarketplaceListing.fromJson(listing.toJson()).matchScore, 0.88);
    expect(ImpactData.fromJson(impact.toJson()).ecoPoints, 100);
  });
}
