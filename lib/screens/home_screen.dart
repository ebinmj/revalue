import 'package:flutter/material.dart';

import 'reuse_screen.dart';
import 'recycle_screen.dart';
import 'reduce_screen.dart';
import 'riddance_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.onQuickScan, super.key});

  final VoidCallback onQuickScan;

  static const _actions = [
    _ReValueAction(
      label: 'REDUCE',
      title: 'Repair & extend',
      description: 'Repair instead of replacing',
      icon: Icons.build_outlined,
    ),
    _ReValueAction(
      label: 'REUSE',
      title: 'Give it another life',
      description: 'Sell, donate or recover',
      icon: Icons.volunteer_activism_outlined,
    ),
    _ReValueAction(
      label: 'RECYCLE',
      title: 'Recover materials',
      description: 'Find the right recycling pathway',
      icon: Icons.recycling_outlined,
    ),
    _ReValueAction(
      label: 'RIDDANCE',
      title: 'Dispose responsibly',
      description: "For items that can't be recovered",
      icon: Icons.delete_outline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = MediaQuery.sizeOf(context).width >= 760 ? 4 : 2;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ReValue',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Give unwanted things a better next step.',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose what you want to do, or let ReValue figure it out.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    color: theme.colorScheme.primary,
                    child: InkWell(
                      onTap: onQuickScan,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'QUICK SCAN',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.1,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Not sure what to do with it?',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  theme.colorScheme.onPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload an item and let ReValue analyze every next step.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.colorScheme.onPrimary
                                                  .withValues(alpha: 0.82),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: onQuickScan,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: theme.colorScheme.primary,
                                ),
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                ),
                                label: const Text('Scan an item'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'What do you want to do?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 4 ? 0.84 : 0.72,
                    ),
                    itemCount: _actions.length,
                    itemBuilder: (context, index) {
                      final action = _actions[index];
                      return _ActionCard(
                        action: action,
                        onTap: () => _openAction(context, action),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAction(BuildContext context, _ReValueAction action) {
    final Widget destination;
    switch (action.label) {
      case 'REUSE':
        destination = const ReuseScreen();
      case 'REDUCE':
        destination = const ReduceScreen();
      case 'RECYCLE':
        destination = const RecycleScreen();
      default:
        destination = const RiddanceScreen();
    }
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => destination));
  }
}

class _ReValueAction {
  const _ReValueAction({
    required this.label,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String label;
  final String title;
  final String description;
  final IconData icon;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.onTap});

  final _ReValueAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                action.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                action.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  action.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
