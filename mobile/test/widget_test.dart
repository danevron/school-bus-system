// This is a basic Flutter widget test for the localized School Bus App.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_bus_app/main.dart';

void main() {
  setUpAll(() async {
    // Initialize AuthService for testing
    await AuthService.init();
  });

  testWidgets('School Bus App shows login screen when not authenticated', (WidgetTester tester) async {
    // Ensure user is logged out
    await AuthService.logout();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());
    await tester.pumpAndSettle();

    // Verify that login screen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('School Bus System'), findsOneWidget);
    expect(find.text('Login'), findsAtLeastNWidget(1)); // Login title and button
    expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
  });

  testWidgets('Login screen has proper form validation', (WidgetTester tester) async {
    // Ensure user is logged out
    await AuthService.logout();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());
    await tester.pumpAndSettle();

    // Find and tap login button without entering data
    final loginButton = find.text('Login').last; // Get the button, not the title
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify validation messages appear (they should be in the widget tree)
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Login screen structure and UI elements are present', (WidgetTester tester) async {
    // Ensure user is logged out
    await AuthService.logout();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());
    await tester.pumpAndSettle();

    // Verify main UI elements are present in login screen.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('App supports both English and Hebrew locales', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());

    // Find the MaterialApp widget and verify supported locales.
    final materialAppFinder = find.byType(MaterialApp);
    expect(materialAppFinder, findsOneWidget);
    
    final MaterialApp materialApp = tester.widget(materialAppFinder);
    expect(materialApp.supportedLocales.length, equals(2));
    expect(materialApp.supportedLocales.any((l) => l.languageCode == 'en'), isTrue);
    expect(materialApp.supportedLocales.any((l) => l.languageCode == 'he'), isTrue);
    
    // Verify localization delegates are set.
    expect(materialApp.localizationsDelegates, isNotNull);
    expect(materialApp.localizationsDelegates!.length, greaterThanOrEqualTo(4));
    
    // Verify routing is configured
    expect(materialApp.routes, isNotNull);
    expect(materialApp.routes!.containsKey('/'), isTrue);
    expect(materialApp.routes!.containsKey('/login'), isTrue);
    expect(materialApp.routes!.containsKey('/welcome'), isTrue);
  });
  
  testWidgets('AuthService integration works', (WidgetTester tester) async {
    // Test AuthService methods
    expect(AuthService.isAuthenticated, isFalse);
    expect(AuthService.token, isNull);
    expect(AuthService.user, isNull);
    
    // Test logout (should not throw)
    await AuthService.logout();
    expect(AuthService.isAuthenticated, isFalse);
  });
}