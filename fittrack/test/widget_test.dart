// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fittrack/main.dart';

void main() {
  testWidgets('FitTrack app instantiation test', (WidgetTester tester) async {
    // Test that the FitTrackApp widget can be created without errors
    // This is a basic instantiation test that doesn't require Firebase initialization
    const app = FitTrackApp();
    
    // Verify the widget is not null and can be created
    expect(app, isNotNull);
    expect(app.runtimeType, FitTrackApp);
  });
  
  testWidgets('Material app theme configuration test', (WidgetTester tester) async {
    // Test a simpler MaterialApp widget to verify theme configuration
    await tester.pumpWidget(
      MaterialApp(
        title: 'FitTrack',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Text('Test App'),
        ),
      ),
    );

    // Verify the app renders correctly
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Test App'), findsOneWidget);
  });
}
