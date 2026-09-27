import '../models/user.dart';

abstract class AuthService {
  Future<User?> login({required String email, required String password});
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<void> logout();
  Future<bool> isLoggedIn();
  Future<User?> getCurrentUser();
}
