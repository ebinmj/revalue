import 'package:flutter/material.dart';

import '../models/product_analysis.dart';
import '../widgets/app_page.dart';

class RiddanceScreen extends StatelessWidget {
  const RiddanceScreen({this.analysis, super.key});

  final ProductAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCategory = analysis?.category ?? 'End-of-life item';
    final riskFactors =
        analysis?.riskFactors.isNotEmpty == true
            ? analysis!.riskFactors
            : const [
              'Damaged lithium batteries pose thermal runaway and fire risks',
              'Internal capacitors may retain high voltage charges',
            ];

    return Scaffold(
      appBar: AppBar(title: const Text('Riddance')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.onErrorContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Responsible Disposal',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Safety guidance for $itemCategory',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Why Disposal May Be Necessary',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When an item has experienced critical structural failure, severe corrosion, or battery degradation where repair or material extraction poses hazards, safe disposal is the only responsible option.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identified Risk Factors',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...riskFactors.map(
                      (risk) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(risk)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What NOT to do',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _WarningItem(
                      text:
                          'Do NOT throw this item into ordinary municipal household garbage.',
                    ),
                    const _WarningItem(
                      text:
                          'Do NOT attempt to puncture, incinerate, or disassemble damaged batteries.',
                    ),
                    const _WarningItem(
                      text:
                          'Do NOT store swollen or leaking batteries indoors near flammable items.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appropriate Disposal Channel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Category: Designated Hazardous E-Waste / Battery Drop-Off\n\nContact your regional municipal hazardous waste program or drop off at an authorized electronics manufacturer take-back collection bin.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to Analysis Results'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningItem extends StatelessWidget {
  const _WarningItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close_rounded, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
