import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/four_r_assessment.dart';
import '../models/four_r_recommendation.dart';
import '../models/product_analysis.dart';
import '../widgets/app_page.dart';
import 'component_recovery_screen.dart';
import 'recycle_screen.dart';
import 'repair_cost_screen.dart';
import 'riddance_screen.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({
    required this.imageBytes,
    required this.description,
    required this.analysis,
    required this.recommendation,
    super.key,
  });

  final Uint8List imageBytes;
  final String description;
  final ProductAnalysis analysis;
  final FourRRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final assessments = [
      recommendation.reduce,
      recommendation.reuse,
      recommendation.recycle,
      recommendation.riddance,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'AI Analysis',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(analysis.category, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(analysis.condition, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            _ResultSection(title: 'Possible issue', value: analysis.problem),
            _ListSection(
              title: 'Visible components',
              values: analysis.visibleComponents,
            ),
            _ListSection(
              title: 'Possible materials',
              values: analysis.possibleMaterials,
            ),
            _ListSection(title: 'Risk factors', values: analysis.riskFactors),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your description', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your ReValue Recommendation',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.recommendationTitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recommendation.recommendationExplanation,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            ...assessments.map(
              (assessment) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssessmentCard(
                  assessment: assessment,
                  analysis: analysis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment, required this.analysis});

  final FourRAssessment assessment;
  final ProductAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assessment.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${assessment.score}/100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(assessment.explanation),
            const SizedBox(height: 6),
            Text(
              assessment.recommendedAction,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () =>
                    _openAction(context, assessment.type, analysis),
                child: Text(_actionLabel(assessment.type)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAction(
    BuildContext context,
    String type,
    ProductAnalysis analysis,
  ) {
    final Widget destination;
    switch (type) {
      case 'reduce':
        destination = RepairCostScreen(analysis: analysis);
      case 'reuse':
        destination = ComponentRecoveryScreen(analysis: analysis);
      case 'recycle':
        destination = RecycleScreen(analysis: analysis);
      default:
        destination = RiddanceScreen(analysis: analysis);
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => destination));
  }

  String _actionLabel(String type) => switch (type) {
    'reduce' => 'Explore Repair',
    'reuse' => 'Recover Components',
    'recycle' => 'Recycling Options',
    _ => 'Responsible Disposal',
  };
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.values});

  final String title;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values.map((value) => Chip(label: Text(value))).toList(),
          ),
        ],
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
