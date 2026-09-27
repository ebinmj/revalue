import 'package:flutter/material.dart';

import '../models/product_analysis.dart';
import '../models/reusable_component.dart';
import '../services/component_recovery_service.dart';
import '../widgets/app_page.dart';
import 'reuse_marketplace_screen.dart';

class ComponentRecoveryScreen extends StatelessWidget {
  const ComponentRecoveryScreen({
    required this.analysis,
    this.recoveryService = const MockComponentRecoveryService(),
    super.key,
  });

  final ProductAnalysis analysis;
  final ComponentRecoveryService recoveryService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = recoveryService.findPotentialComponents(analysis);

    return Scaffold(
      appBar: AppBar(title: const Text('Component Recovery')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Text(
              'Potentially reusable components',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recover individual parts from your ${analysis.category.toLowerCase()} to keep them in circulation.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (components.isEmpty)
              const _EmptyRecoveryState()
            else
              ...components.map(
                (component) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ComponentCard(
                    component: component,
                    onTap: () => _openMarketplaceForComponent(
                      context,
                      component.name,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReuseMarketplaceScreen(
                      initialCategory: 'Components',
                    ),
                  ),
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse Reuse Marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openMarketplaceForComponent(BuildContext context, String componentName) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReuseMarketplaceScreen(
          initialQuery: componentName,
          initialCategory: 'Components',
        ),
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.component, required this.onTap});

  final ReusableComponent component;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      component.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      component.condition,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(component.reusePotential),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estimated value: ${_range(component.estimatedMinimumValue.toInt(), component.estimatedMaximumValue.toInt())}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(component.action),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRecoveryState extends StatelessWidget {
  const _EmptyRecoveryState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.extension_off_outlined,
              size: 38,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'No reusable components identified for this item.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

String _range(int minimum, int maximum) =>
    '${_currency(minimum)}–${_currency(maximum)}';

String _currency(int value) {
  final digits = value.toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '₹$formatted';
}
