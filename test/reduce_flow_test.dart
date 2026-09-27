import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:re_value/screens/reduce_scan_screen.dart';
import 'package:re_value/screens/reduce_screen.dart';
import 'package:re_value/services/reduce_service.dart';

void main() {
  test('MockReduceService returns repair-focused facts and estimates', () async {
    const service = MockReduceService();
    final result = await service.analyzeForRepair(
      image: File('dummy.jpg'),
      problemDescription: "Laptop doesn't turn on. Screen still works.",
    );

    expect(result.product, 'Laptop');
    expect(result.condition, 'Broken / partially functional');
    expect(result.reportedProblem, 'Does not turn on');
    expect(result.possibleIssue, 'Possible power-related issue');
    expect(result.repairability, 'Potentially repairable');
    expect(
      result.potentialRepairAreas,
      containsAll(['Battery', 'Charger', 'Power circuit', 'RAM', 'Motherboard']),
    );
    expect(result.estimate.minimumCost, 2000);
    expect(result.estimate.maximumCost, 3000);
    expect(result.replacementEstimateMin, 20000);
    expect(result.replacementEstimateMax, 25000);
  });

  testWidgets('ReduceScreen renders dedicated repair options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ReduceScreen()));

    expect(find.text('Repair before replacing.'), findsOneWidget);
    expect(
      find.text(
        'Find out whether your item can be repaired and whether repairing it could extend its useful life.',
      ),
      findsOneWidget,
    );
    expect(find.text('Scan an item'), findsOneWidget);
    expect(find.text('Describe the problem'), findsOneWidget);

    await tester.tap(find.text('Scan an item'));
    await tester.pumpAndSettle();
    expect(find.text('Analyze for Repair'), findsAtLeastNWidgets(1));
  });

  testWidgets('ReduceScanScreen validates missing image and description', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: ReduceScanScreen()));

    await tester.tap(
      find.widgetWithText(FilledButton, 'Analyze for Repair'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Please add a photo of the item.'), findsOneWidget);
    expect(find.text('Tell us what is wrong with the item.'), findsOneWidget);
  });
}
