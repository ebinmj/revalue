import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({supabase.SupabaseClient? client})
    : _client = client ?? supabase.Supabase.instance.client;

  final supabase.SupabaseClient _client;

  @override
  String? get accessToken => _client.auth.currentSession?.accessToken;

  @override
  Future<User?> login({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) return null;
    await _ensureProfile(user);
    return _mapUser(user);
  }

  @override
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    final user = response.user;
    if (user == null) return null;
    await _ensureProfile(user, name: name);
    return _mapUser(user);
  }

  @override
  Future<void> logout() => _client.auth.signOut();

  @override
  Future<bool> isLoggedIn() async => _client.auth.currentSession != null;

  @override
  Future<User?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  Future<void> _ensureProfile(supabase.User user, {String? name}) async {
    final token = accessToken;
    if (token == null) return;
    await ApiService(accessTokenProvider: () => accessToken).ensureProfile(
      name: name?.trim().isNotEmpty == true
          ? name!.trim()
          : (user.userMetadata?['name'] as String? ?? ''),
    );
  }

  User _mapUser(supabase.User user) {
    final metadataName = user.userMetadata?['name'] as String?;
    final email = user.email ?? '';
    return User(
      id: user.id,
      name: metadataName?.trim().isNotEmpty == true
          ? metadataName!.trim()
          : (email.contains('@') ? email.split('@').first : 'ReValue user'),
      email: email,
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }
}
