import 'package:flutter/material.dart';

import '../widgets/placeholder_screen.dart';

class ImpactScreen extends StatelessWidget {
  const ImpactScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Impact',
    description: 'See the difference your recovery decisions can make.',
    icon: Icons.insights_outlined,
  );
}
