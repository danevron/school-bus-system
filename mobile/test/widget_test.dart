// This is a basic Flutter widget test for the localized School Bus App.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:school_bus_app/main.dart';

void main() {
  testWidgets('School Bus App launches with English localization', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());

    // Verify that our app title appears in English by default.
    expect(find.text('School Bus System'), findsOneWidget);
    expect(find.text('Mobile App'), findsOneWidget);
    
    // Verify that welcome message appears in English.
    expect(find.text('🚌 Welcome to School Bus App!'), findsOneWidget);
    
    // Verify the status indicator appears in English.
    expect(find.text('App is working correctly!'), findsOneWidget);
    
    // Verify language selector is present.
    expect(find.byIcon(Icons.language), findsWidgets);
  });

  testWidgets('App structure and basic UI elements are present', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SchoolBusApp());

    // Verify main UI elements are present.
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    expect(find.byType(PopupMenuButton<Locale>), findsOneWidget);
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
  });
}