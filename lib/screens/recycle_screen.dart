import 'package:flutter/material.dart';

import '../models/product_analysis.dart';
import '../widgets/app_page.dart';
import 'reuse_marketplace_screen.dart';

class RecycleScreen extends StatelessWidget {
  const RecycleScreen({this.analysis, super.key});

  final ProductAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCategory = analysis?.category ?? 'Electronic item';
    final materials =
        analysis?.possibleMaterials.isNotEmpty == true
            ? analysis!.possibleMaterials
            : const [
              'Aluminium',
              'Copper',
              'Plastic',
              'Electronic components',
            ];

    return Scaffold(
      appBar: AppBar(title: const Text('Recycle')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.recycling,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Material Recovery',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Responsible pathway for $itemCategory',
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Potentially Recoverable Materials',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These materials may be recoverable through appropriate recycling channels:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          materials
                              .map(
                                (material) => Chip(
                                  avatar: const Icon(
                                    Icons.category_outlined,
                                    size: 16,
                                  ),
                                  label: Text(material),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Why they have value:',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Non-ferrous metals like copper and aluminium require up to 95% less energy to recycle into new raw materials than primary mining and smelting. Electronics contain traceable precious metals and critical minerals.',
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
                      'Recycling Guidance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Before handing over equipment to a recycling stream, consider whether any components can still be reused. Always ensure personal storage drives are removed or wiped.',
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('Separate hazardous batteries'),
                      subtitle: Text(
                        'Lithium batteries require dedicated collection and must not be crushed.',
                      ),
                    ),
                    const ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text('Certified e-waste handlers only'),
                      subtitle: Text(
                        'Ensure your recyclers comply with state environmental guidelines.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Controlled Knowledge Note',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ReValue provides general e-waste material recovery pathways based on product categories and does not fabricate specific local municipal facilities.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ReuseMarketplaceScreen(
                    initialCategory: 'Components',
                  ),
                ),
              ),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Check Reuse Marketplace for Parts First'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Return to Analysis'),
            ),
          ],
        ),
      ),
    );
  }
}
