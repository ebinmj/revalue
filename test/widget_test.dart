import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:re_value/app/app.dart';

void main() {
  testWidgets('ReValue app shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ReValueApp());

    expect(
      find.text('Give unwanted things a better next step.'),
      findsOneWidget,
    );
    expect(find.text('What do you want to do?'), findsOneWidget);
    expect(find.text('REDUCE'), findsOneWidget);
    expect(find.text('Scan an item'), findsOneWidget);
  });

  testWidgets('Home actions use local navigation and feedback', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReValueApp());

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Share a photo and describe what is wrong. ReValue will suggest a better next step.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REDUCE'));
    await tester.pumpAndSettle();
    expect(find.text('Reduce'), findsOneWidget);
  });

  testWidgets('all Home actions open their intended destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ReValueApp());

    final destinations = <String, String>{
      'REDUCE': 'Reduce',
      'REUSE': 'Reuse Marketplace',
      'RECYCLE': 'Recycle',
      'RIDDANCE': 'Riddance',
    };

    for (final entry in destinations.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsAtLeastNWidgets(1));
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Scan an item'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Share a photo and describe what is wrong. ReValue will suggest a better next step.',
      ),
      findsOneWidget,
    );
  });
}
