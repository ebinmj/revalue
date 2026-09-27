import '../models/user.dart';
import 'auth_service.dart';

class MockAuthService implements AuthService {
  MockAuthService();

  static const _demoEmail = 'demo@revalue.app';
  static const _demoPassword = 'ReValue123';

  final Map<String, User> _registeredUsers = {
    _demoEmail: User(
      id: 'demo-user',
      name: 'Demo User',
      email: _demoEmail,
      createdAt: DateTime.now(),
    ),
  };

  User? _currentUser;

  @override
  Future<User?> login({required String email, required String password}) async {
    final normalizedEmail = email.trim();
    final user = _registeredUsers[normalizedEmail.toLowerCase()];
    if (user == null) {
      return null;
    }

    if (normalizedEmail.toLowerCase() == _demoEmail &&
        password == _demoPassword) {
      _currentUser = user;
      return user;
    }

    if (_currentUser != null &&
        _currentUser!.email.toLowerCase() == normalizedEmail.toLowerCase()) {
      // allow signup users to log in with their created password during the mock phase.
      final storedPassword = _passwordByEmail[normalizedEmail.toLowerCase()];
      if (storedPassword == password) {
        _currentUser = user;
        return user;
      }
    }

    return null;
  }

  @override
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty ||
        !_isValidEmail(normalizedEmail) ||
        password.length < 6) {
      return null;
    }

    final user = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isNotEmpty ? name.trim() : 'User',
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );

    _registeredUsers[normalizedEmail] = user;
    _passwordByEmail[normalizedEmail] = password;
    _currentUser = user;
    return user;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<bool> isLoggedIn() async => _currentUser != null;

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  static final Map<String, String> _passwordByEmail = {
    _demoEmail: _demoPassword,
  };

  static bool _isValidEmail(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }
}
