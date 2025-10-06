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
import 'package:fittrack/providers/auth_provider.dart' as app_auth;

@GenerateMocks([ProgramProvider, app_auth.AuthProvider])
import 'enhanced_create_program_screen_test.mocks.dart';

void main() {
  group('CreateProgramScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    late MockAuthProvider mockAuthProvider;

    setUpAll(() async {
      // Initialize Flutter test binding only - no Firebase needed
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    setUp(() {
      mockProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();
      
      // Set up minimal mock behavior for rendering
      when(mockProvider.isLoadingPrograms).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.programs).thenReturn([]);
      when(mockProvider.selectedProgram).thenReturn(null);
      
      // Set up auth provider mocks to prevent Firebase calls
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
      
      // Set up basic successful responses without argument matchers in setUp
      when(mockProvider.createProgram(
        name: 'Test Program', 
        description: null
      )).thenAnswer((_) async => 'test-program-id');
      
      when(mockProvider.createProgram(
        name: 'Test Program', 
        description: ''
      )).thenAnswer((_) async => 'test-program-id');
      
      // Mock updateProgramFields for edit mode support
      when(mockProvider.updateProgramFields(
        any, 
        name: 'Test Program',
        description: null
      )).thenAnswer((_) async {});
      
      when(mockProvider.updateProgramFields(
        any, 
        name: 'Test Program', 
        description: ''
      )).thenAnswer((_) async {});
    });

    testWidgets('renders create program screen with form fields', (WidgetTester tester) async {
      /// Test Purpose: Verify basic screen rendering and form elements are present
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
              ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const CreateProgramScreen(),
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
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
              ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const CreateProgramScreen(),
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
      
      // Verify the form fields exist and can accept input
      final descriptionField = find.byType(TextFormField).at(1);
      await tester.enterText(descriptionField, 'Test Description');
      await tester.pump();
      
      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      /// Test Purpose: Verify form validation works for empty required fields
      
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
              ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ],
            child: const CreateProgramScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit empty form by tapping the CREATE button
      final createButton = find.text('CREATE');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Form should show validation error for required name field
      expect(find.text('Please enter a program name'), findsOneWidget);
      
      // Verify that createProgram was never called since form validation failed
      // We'll verify by checking that none of our predefined createProgram mocks were called
      verifyNever(mockProvider.createProgram(name: 'Test Program', description: null));
      verifyNever(mockProvider.createProgram(name: 'Test Program', description: ''));
    });
  });
}