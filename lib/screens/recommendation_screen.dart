import 'package:flutter/material.dart';

import '../models/analysis_data.dart';
import '../models/product_analysis.dart';
import '../models/revalue_recommendation.dart';
import '../widgets/app_page.dart';
import 'component_recovery_screen.dart';
import 'repair_cost_screen.dart';

class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({
    required this.analysis,
    required this.recommendation,
    super.key,
  });

  final AnalysisData analysis;
  final ReValueRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('ReValue Recommendation')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Your best next step',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore repair and component recovery before disposal.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            _BestStepCard(recommendation: recommendation),
            const SizedBox(height: 24),
            Text(
              'Why this recommendation?',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.why,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Compare the 4R paths',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recommendation.options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendationCard(option: option, analysis: analysis),
              ),
            ),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'ReValue Recommendation Scores are deterministic guidance for this prototype, not probabilities or a final diagnosis.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.option, required this.analysis});

  final LegacyFourRRecommendation option;
  final AnalysisData analysis;

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
                    _pathLabel(option.path),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${option.score}/100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(option.title),
            const SizedBox(height: 8),
            Text(
              option.explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  if (option.path == RecoveryPath.reduce) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RepairCostScreen(
                          analysis: ProductAnalysis(
                            category: analysis.detectedCategory,
                            condition: analysis.condition,
                            problem: analysis.possibleIssue,
                            visibleComponents: analysis.visibleComponents,
                            possibleMaterials: analysis.possibleMaterials,
                            riskFactors: analysis.riskFactors,
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  if (option.path == RecoveryPath.reuse) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ComponentRecoveryScreen(
                          analysis: ProductAnalysis(
                            category: analysis.detectedCategory,
                            condition: analysis.condition,
                            problem: analysis.possibleIssue,
                            visibleComponents: analysis.visibleComponents,
                            possibleMaterials: analysis.possibleMaterials,
                            riskFactors: analysis.riskFactors,
                          ),
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(option.recommendedAction)),
                  );
                },
                child: Text(_actionLabel(option.path)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BestStepCard extends StatelessWidget {
  const _BestStepCard({required this.recommendation});

  final ReValueRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final option = recommendation.bestNextStep;
    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_outline, color: theme.colorScheme.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pathLabel(option.path),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                Text(
                  '${option.score}/100',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              option.recommendedAction,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              option.explanation,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _pathLabel(RecoveryPath path) => switch (path) {
  RecoveryPath.reduce => 'Reduce',
  RecoveryPath.reuse => 'Reuse',
  RecoveryPath.recycle => 'Recycle',
  RecoveryPath.riddance => 'Riddance',
};

String _actionLabel(RecoveryPath path) => switch (path) {
  RecoveryPath.reduce => 'Repair & Cost',
  RecoveryPath.reuse => 'Recover Components',
  RecoveryPath.recycle => 'Recycle',
  RecoveryPath.riddance => 'Responsible Disposal',
};
