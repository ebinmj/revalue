import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../models/user.dart';
import '../screens/home_screen.dart';
import '../screens/impact_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/quick_scan_screen.dart';
import '../screens/reuse_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/supabase_auth_service.dart';
import '../theme/app_theme.dart';

class ReValueApp extends StatefulWidget {
  const ReValueApp({this.authService, this.aiTestMode, super.key});

  final AuthService? authService;
  final bool? aiTestMode;

  @override
  State<ReValueApp> createState() => _ReValueAppState();
}

class _ReValueAppState extends State<ReValueApp> {
  bool get _aiTestMode =>
      widget.aiTestMode ?? const bool.fromEnvironment('REVALUE_AI_TEST_MODE');

  late final AuthService _authService =
      widget.authService ?? SupabaseAuthService();
  User? _currentUser;
  bool _checkingAuth = true;
  bool _showSignup = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    if (_aiTestMode) {
      _checkingAuth = false;
      return;
    }
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    User? user;
    try {
      final isLoggedIn = await _authService.isLoggedIn().timeout(
        const Duration(seconds: 8),
      );
      if (isLoggedIn) {
        user = await _authService.getCurrentUser().timeout(
          const Duration(seconds: 8),
        );
      }
    } catch (_) {
      debugPrint('Auth session restore failed; showing the login screen.');
    }

    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _checkingAuth = false;
    });
  }

  void _handleLogin(User user) {
    setState(() {
      _currentUser = user;
      _showSignup = false;
      _selectedIndex = 0;
    });
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _showSignup = false;
      _selectedIndex = 0;
    });
  }

  void _showLoginScreen() {
    setState(() => _showSignup = false);
  }

  void _showSignupScreen() {
    setState(() => _showSignup = true);
  }

  void _openQuickScan() {
    setState(() => _selectedIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return MaterialApp(
        title: 'ReValue',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final appShell = MaterialApp(
      title: 'ReValue',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _aiTestMode
          ? const Scaffold(body: QuickScanScreen())
          : _currentUser == null
          ? (_showSignup
                ? SignupScreen(
                    authService: _authService,
                    onSignupSuccess: _handleLogin,
                    onBackToLogin: _showLoginScreen,
                  )
                : LoginScreen(
                    authService: _authService,
                    onLoginSuccess: _handleLogin,
                    onCreateAccount: _showSignupScreen,
                  ))
          : Scaffold(
              body: IndexedStack(
                index: _selectedIndex,
                children: [
                  HomeScreen(user: _currentUser!, onQuickScan: _openQuickScan),
                  ReuseScreen(
                    apiService: ApiService(
                      accessTokenProvider: () => _authService.accessToken,
                    ),
                  ),
                  const QuickScanScreen(),
                  const ImpactScreen(),
                  ProfileScreen(
                    user: _currentUser!,
                    authService: _authService,
                    onLogout: _handleLogout,
                  ),
                ],
              ),
              bottomNavigationBar: ReValueNavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
              ),
            ),
    );

    return appShell;
  }
}

class ReValueNavigationBar extends StatelessWidget {
  const ReValueNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 80,
      color: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _NavigationItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: () => onDestinationSelected(0),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.storefront_outlined,
              selectedIcon: Icons.storefront,
              label: 'Reuse',
              selected: selectedIndex == 1,
              onTap: () => onDestinationSelected(1),
            ),
          ),
          Expanded(
            child: _QuickScanNavigationItem(
              selected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights,
              label: 'Impact',
              selected: selectedIndex == 3,
              onTap: () => onDestinationSelected(3),
            ),
          ),
          Expanded(
            child: _NavigationItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profile',
              selected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickScanNavigationItem extends StatelessWidget {
  const _QuickScanNavigationItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Quick Scan',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: selected ? 0.35 : 0.15,
                      ),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.document_scanner,
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onPrimaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Quick Scan',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
