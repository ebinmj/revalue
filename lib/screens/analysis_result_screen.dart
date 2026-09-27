import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/ai_analysis_result.dart';
import '../widgets/app_page.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({
    required this.imageBytes,
    required this.description,
    required this.result,
    super.key,
  });

  final Uint8List imageBytes;
  final String description;
  final AiAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            const SizedBox(height: 16),
            _ResultSection(
              title: 'Identified item',
              value: result.identifiedItem,
            ),
            _ResultSection(title: 'Summary', value: result.summary),
            _ResultSection(
              title: 'Possible problem',
              value: result.possibleProblem,
            ),
            _ResultSection(
              title: 'Confidence',
              value: _capitalize(result.confidence),
            ),
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
              'Recovery options',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _RecommendationCard(title: 'Reduce', value: result.reduce),
            _RecommendationCard(title: 'Reuse', value: result.reuse),
            _RecommendationCard(title: 'Recycle', value: result.recycle),
            _RecommendationCard(title: 'Riddance', value: result.riddance),
            if (result.followUpQuestions.isNotEmpty)
              _QuestionSection(questions: result.followUpQuestions),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.title, required this.value});

  final String title;
  final RecoveryRecommendationResult value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(value.recommendation),
            const SizedBox(height: 6),
            Text(
              value.reason,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Follow-up questions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        ...questions.map(
          (question) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.help_outline),
            title: Text(question),
          ),
        ),
      ],
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

String _capitalize(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
