import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_zapp/core/models/user.dart';
import 'package:project_zapp/core/theme.dart';
import 'package:project_zapp/features/auth/login_screen.dart';
import 'package:project_zapp/features/auth/signup_screen.dart';

void main() {
  group('Auth Models & Serialization', () {
    test('PendingUser parses JSON correctly', () {
      final json = {
        'id': 'user-123',
        'name': 'John Doe',
        'email': 'john@test.com',
        'phone_number': '1234567890',
        'username': 'johndoe',
        'role': 'USER',
        'status': 'PENDING',
        'created_at': '2026-10-10T12:00:00Z',
      };

      final user = PendingUser.fromJson(json);
      expect(user.id, 'user-123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@test.com');
      expect(user.phoneNumber, '1234567890');
      expect(user.username, 'johndoe');
      expect(user.role, 'USER');
      expect(user.status, 'PENDING');
      expect(user.createdAt, isNotNull);
    });

    test('AppUser role and status helpers work', () {
      const admin = AppUser(
        id: '1',
        username: 'admin',
        role: UserRole.admin,
        status: AccountStatus.approved,
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.isApproved, isTrue);

      const user = AppUser(
        id: '2',
        username: 'student',
        role: UserRole.user,
        status: AccountStatus.pending,
      );
      expect(user.isAdmin, isFalse);
      expect(user.isApproved, isFalse);
    });
  });

  group('Signup Screen Validation', () {
    Widget buildSignupScreen() {
      return MaterialApp(
        theme: appTheme,
        home: const ProviderScope(child: SignupScreen()),
      );
    }

    testWidgets(
      'Signup screen renders all 6 required fields and submit button',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildSignupScreen());

        expect(find.text('Create Account'), findsWidgets);
        expect(find.text('Full name'), findsOneWidget);
        expect(find.text('Email address'), findsOneWidget);
        expect(find.text('Phone number'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Confirm password'), findsOneWidget);
      },
    );

    testWidgets('Signup validation triggers on empty submit', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildSignupScreen());

      // Scroll to submit button and tap
      final submitFinder = find.widgetWithText(FilledButton, 'Create Account');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(
        find.text('Enter your full name (minimum 2 characters)'),
        findsOneWidget,
      );
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter your 10-digit mobile number'), findsOneWidget);
      expect(find.text('Choose a username'), findsOneWidget);
      expect(find.text('Use at least 8 characters'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);
    });
  });

  group('Login Screen Mode Toggle', () {
    Widget buildLoginScreen() {
      return MaterialApp(
        theme: appTheme,
        home: const ProviderScope(child: LoginScreen()),
      );
    }

    testWidgets('Login screen toggles between Student and Administrator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildLoginScreen());

      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

      // Switch to Admin
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Portal'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Sign in as Administrator'),
        findsOneWidget,
      );
    });
  });
}
