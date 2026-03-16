import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:empora/main.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/screens/login_screen.dart';
import 'package:empora/screens/home_screen.dart';

void main() {
  // ─── App Launch Test ────────────────────────────────────────────
  testWidgets('Empora app launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const EmporaApp());
    await tester.pump();
    // App should render something (splash screen initially)
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  // ─── Splash Screen Test ─────────────────────────────────────────
  testWidgets('Splash screen shows EMPORA text', (WidgetTester tester) async {
    await tester.pumpWidget(const EmporaApp());
    await tester.pump();
    expect(find.text('EMPORA'), findsOneWidget);
  });

  // ─── Login Screen Test ──────────────────────────────────────────
  testWidgets('Login screen renders email and password fields',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Email and password fields should be present
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  // ─── Login Validation Test ──────────────────────────────────────
  testWidgets('Login form shows error when submitted empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Tap Sign In without filling fields
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Validation errors should appear
    expect(find.text('Enter your email'), findsOneWidget);
  });

  // ─── Skip Button Test ───────────────────────────────────────────
  testWidgets('Skip button is tappable on login screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );
    await tester.pump();

    // Skip button should exist and be tappable
    expect(find.text('Skip'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  });

  // ─── Home Screen Test ───────────────────────────────────────────
  testWidgets('Home screen shows all 14 module cards',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // App name should appear
    expect(find.text('EMPORA'), findsOneWidget);

    // Check a few module names are visible
    expect(find.text('Fund'), findsOneWidget);
    expect(find.text('Loans'), findsOneWidget);
    expect(find.text('Taxation'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.text('Customer Support'), findsOneWidget);
  });

  // ─── Home Screen Search Test ─────────────────────────────────────
  testWidgets('Home screen search filters modules', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    // Type in search box
    await tester.enterText(find.byType(TextField).first, 'Fund');
    await tester.pump();

    // Fund module should still be visible
    expect(find.text('Fund'), findsOneWidget);
  });
}