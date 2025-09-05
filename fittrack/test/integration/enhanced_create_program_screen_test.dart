/// Simplified widget tests for CreateProgramScreen
/// 
/// Test Coverage:
/// - Basic screen rendering and form elements
/// - Essential user interactions
/// - Core functionality validation
/// 
/// Focused on reliability over comprehensive coverage
/// to ensure CI pipeline stability
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fittrack/screens/programs/create_program_screen.dart';
import 'package:fittrack/providers/program_provider.dart';

@GenerateMocks([ProgramProvider])
import 'enhanced_create_program_screen_test.mocks.dart';

void main() {
  group('CreateProgramScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    
    setUp(() {
      mockProvider = MockProgramProvider();
      
      // Set up minimal mock behavior for rendering
      when(mockProvider.isLoadingPrograms).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.createProgram(name: anyNamed('name'), description: anyNamed('description')))
          .thenAnswer((_) async => 'test-program-id');
    });

    testWidgets('renders create program screen with form fields', (WidgetTester tester) async {
      /// Test Purpose: Verify basic screen rendering and form elements are present
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ProgramProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: CreateProgramScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify screen renders without errors
      expect(find.byType(CreateProgramScreen), findsOneWidget);
      
      // Verify form fields are present
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2));
      expect(find.text('Program Name'), findsOneWidget);
      
      // Verify action button exists
      expect(find.text('CREATE'), findsOneWidget);
    });

    testWidgets('handles form input correctly', (WidgetTester tester) async {
      /// Test Purpose: Verify form accepts user input
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ProgramProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: CreateProgramScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and interact with program name field
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Test Program');
      await tester.pump();

      // Verify input was accepted
      expect(find.text('Test Program'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      /// Test Purpose: Verify form validation works for empty required fields
      
      await tester.pumpWidget(
        ChangeNotifierProvider<ProgramProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: CreateProgramScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit empty form
      final createButton = find.text('CREATE');
      await tester.tap(createButton);
      await tester.pump();

      // Form should not submit without required fields
      // The provider method should not be called with invalid input
      verifyNever(mockProvider.createProgram(name: anyNamed('name'), description: anyNamed('description')));
    });
  });
}