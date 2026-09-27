import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:re_value/app/app.dart';
import 'package:re_value/models/user.dart';
import 'package:re_value/services/auth_service.dart';

class _TestAuthService implements AuthService {
  _TestAuthService({bool initiallyLoggedIn = false})
    : _loggedIn = initiallyLoggedIn;

  bool _loggedIn;

  final User _user = User(
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
    createdAt: DateTime.utc(2026),
  );

  @override
  String? get accessToken => null;

  @override
  Future<User?> getCurrentUser() async => _user;

  @override
  Future<bool> isLoggedIn() async => _loggedIn;

  @override
  Future<User?> login({required String email, required String password}) async {
    _loggedIn = true;
    return _user;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _loggedIn = true;
    return _user;
  }
}

class _StalledAuthService implements AuthService {
  @override
  String? get accessToken => null;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<bool> isLoggedIn() => Completer<bool>().future;

  @override
  Future<User?> login({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<User?> signup({
    required String name,
    required String email,
    required String password,
  }) async => null;
}

void main() {
  testWidgets('Unauthenticated users see the login screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ReValueApp(authService: _TestAuthService()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account? Sign up"), findsOneWidget);
  });

  testWidgets('Stalled session restore exits loading and shows login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(ReValueApp(authService: _StalledAuthService()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('AI test mode opens Quick Scan without checking auth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ReValueApp(aiTestMode: true, authService: _StalledAuthService()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick Scan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('Users can open the signup screen', (WidgetTester tester) async {
    await tester.pumpWidget(ReValueApp(authService: _TestAuthService()));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Join ReValue'), findsOneWidget);
  });

  testWidgets('Authenticated users can open Quick Scan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ReValueApp(authService: _TestAuthService(initiallyLoggedIn: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan an item'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Share a photo and describe what is wrong. ReValue\'s AI will ask a few questions and find the best recovery path.',
      ),
      findsOneWidget,
    );
  });
}
