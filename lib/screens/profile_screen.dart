import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.user,
    required this.authService,
    required this.onLogout,
    super.key,
  });

  final User user;
  final AuthService authService;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        user.name.trim().isNotEmpty
                            ? user.name[0].toUpperCase()
                            : 'U',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _ProfileItem(
              title: 'My Listings',
              subtitle: 'Items you have listed',
              icon: Icons.inventory_2_outlined,
            ),
            _ProfileItem(
              title: 'My Purchases',
              subtitle: 'Recent purchases and requests',
              icon: Icons.shopping_bag_outlined,
            ),
            _ProfileItem(
              title: 'Saved Items',
              subtitle: 'Saved marketplace finds',
              icon: Icons.bookmark_border_rounded,
            ),
            _ProfileItem(
              title: 'Impact',
              subtitle: 'Your recovery contributions',
              icon: Icons.insights_outlined,
            ),
            _ProfileItem(
              title: 'Settings',
              subtitle: 'Manage your preferences',
              icon: Icons.settings_outlined,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                await authService.logout();
                onLogout();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
