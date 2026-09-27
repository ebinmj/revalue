import 'package:flutter/material.dart';

import '../models/product_analysis.dart';
import '../models/repair_estimate.dart';
import '../services/repair_cost_service.dart';
import 'component_recovery_screen.dart';
import 'reuse_marketplace_screen.dart';

class RepairCostScreen extends StatefulWidget {
  const RepairCostScreen({
    required this.analysis,
    this.repairCostService = const MockRepairCostService(),
    super.key,
  });

  final ProductAnalysis analysis;
  final RepairCostService repairCostService;

  @override
  State<RepairCostScreen> createState() => _RepairCostScreenState();
}

class _RepairCostScreenState extends State<RepairCostScreen> {
  late final Future<RepairEstimate> _estimateFuture;

  @override
  void initState() {
    super.initState();
    _estimateFuture = Future.value(
      widget.repairCostService.estimateFor(widget.analysis),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Repair & Extend')),
      body: FutureBuilder<RepairEstimate>(
        future: _estimateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StatusState(
              icon: Icons.calculate_outlined,
              title: 'Preparing estimate',
              message: 'Reviewing the item details...',
              loading: true,
            );
          }
          if (snapshot.hasError) {
            return _StatusState(
              icon: Icons.cloud_off_outlined,
              title: 'Estimate unavailable',
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
            );
          }
          final estimate = snapshot.data!;
          final potentialSavingsMin =
              (estimate.replacementCost - estimate.maximumCost).clamp(
                0.0,
                double.infinity,
              );
          final potentialSavingsMax =
              (estimate.replacementCost - estimate.minimumCost).clamp(
                0.0,
                double.infinity,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              Text(
                'Repair before replacing',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'See whether repairing your ${widget.analysis.category.toLowerCase()} could extend its life.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
                        'Identified Issue',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.analysis.problem,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Condition: ${widget.analysis.condition}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _EstimateCard(
                title: 'Repair estimate (estimated)',
                child: Column(
                  children: [
                    _CostRow(
                      label: 'Parts',
                      value: _currency(estimate.partsCost.toInt()),
                    ),
                    _CostRow(
                      label: 'Labour',
                      value: _currency(estimate.labourCost.toInt()),
                    ),
                    _CostRow(
                      label: 'Service & diagnostics',
                      value: _currency(estimate.serviceCost.toInt()),
                    ),
                    const Divider(height: 24),
                    _CostRow(
                      label: 'Total estimated repair',
                      value: _range(
                        estimate.minimumCost.toInt(),
                        estimate.maximumCost.toInt(),
                      ),
                      emphasized: true,
                    ),
                    const SizedBox(height: 6),
                    _CostRow(
                      label: 'Estimated repair time',
                      value: estimate.repairTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _EstimateCard(
                title: 'Replacement comparison',
                child: Column(
                  children: [
                    _CostRow(
                      label: 'Estimated replacement cost',
                      value: '${_currency(estimate.replacementCost.toInt())}+',
                      emphasized: true,
                    ),
                    const Divider(height: 24),
                    _CostRow(
                      label: 'Estimated potential savings',
                      value: _range(
                        potentialSavingsMin.toInt(),
                        potentialSavingsMax.toInt(),
                      ),
                      emphasized: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Repair may be worth considering',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        estimate.explanation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Estimated ~2.1 kg e-waste avoided by extending lifecycle',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Estimates only. Prices are estimated ranges. Actual repair costs and replacement prices depend on the specific brand, model, and local service providers.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ReuseMarketplaceScreen(
                      initialCategory: 'Components',
                    ),
                  ),
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Find Spare Parts in Marketplace'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ComponentRecoveryScreen(analysis: widget.analysis),
                  ),
                ),
                icon: const Icon(Icons.extension_outlined),
                label: const Text('Or Recover Components for Reuse'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusState extends StatelessWidget {
  const _StatusState({
    required this.icon,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (loading) ...[
              const SizedBox(height: 18),
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
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
