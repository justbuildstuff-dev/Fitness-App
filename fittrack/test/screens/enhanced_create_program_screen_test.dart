/// Comprehensive widget tests for CreateProgramScreen
/// 
/// Test Coverage:
/// - Screen rendering and layout validation
/// - Form field behavior and validation
/// - User interaction handling (tap, input, navigation)
/// - Loading states and error handling
/// - Provider integration and state management
/// - Accessibility and usability validation
/// 
/// If any test fails, it indicates issues with:
/// - UI component rendering and layout
/// - Form validation and user input handling
/// - State management and provider integration
/// - User experience and navigation flow

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/screens/programs/create_program_screen.dart';
import '../../lib/providers/program_provider.dart';
import '../../lib/models/program.dart';

@GenerateMocks([ProgramProvider])
import 'enhanced_create_program_screen_test.mocks.dart';

void main() {
  group('CreateProgramScreen Widget Tests', () {
    late MockProgramProvider mockProvider;
    
    setUp(() {
      mockProvider = MockProgramProvider();
      
      // Set up default mock behavior
      when(mockProvider.isLoadingPrograms).thenReturn(false);
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.createProgram(any)).thenAnswer((_) async => 'new-program-id');
    });

    group('Screen Rendering and Layout', () {
      testWidgets('renders all required form fields correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify all form fields are present and properly labeled
        /// This ensures the UI provides all necessary inputs for program creation
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen title
        expect(find.text('Create Program'), findsOneWidget);
        
        // Verify form fields are present
        expect(find.byType(TextFormField), findsNWidgets(2)); // Name and description
        
        // Verify labels
        expect(find.text('Program Name'), findsOneWidget);
        expect(find.text('Description (Optional)'), findsOneWidget);
        
        // Verify action buttons
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.text('Create Program'), findsOneWidget);
        
        // Verify app bar
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays correct screen layout structure', (WidgetTester tester) async {
        /// Test Purpose: Verify screen layout follows design specifications
        /// This ensures consistent UI structure and proper widget hierarchy
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify scaffold structure
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        
        // Verify padding and spacing
        expect(find.byType(Padding), findsAtLeastNWidgets(1));
        expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
      });
    });

    group('Form Field Behavior', () {
      testWidgets('validates required program name field', (WidgetTester tester) async {
        /// Test Purpose: Verify program name validation prevents empty submissions
        /// This ensures data quality and prevents invalid program creation
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Try to submit without entering name
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Please enter a program name'), findsOneWidget);
        
        // Verify provider method was not called
        verifyNever(mockProvider.createProgram(any));
      });

      testWidgets('validates program name length constraints', (WidgetTester tester) async {
        /// Test Purpose: Verify program name length validation follows business rules
        /// This ensures UI prevents names that exceed database constraints
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter name that's too long
        final tooLongName = 'A' * 201; // Exceeds 200 character limit
        await tester.enterText(
          find.byType(TextFormField).first,
          tooLongName,
        );
        
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show length validation error
        expect(find.textContaining('too long'), findsOneWidget);
        verifyNever(mockProvider.createProgram(any));
      });

      testWidgets('accepts valid program name input', (WidgetTester tester) async {
        /// Test Purpose: Verify valid program names are accepted and processed
        /// This ensures proper form handling for valid input
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter valid program name
        await tester.enterText(
          find.byType(TextFormField).first,
          'Valid Program Name',
        );

        // Verify text was entered
        expect(find.text('Valid Program Name'), findsOneWidget);
        
        // Submit form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify provider method was called
        verify(mockProvider.createProgram(any)).called(1);
      });

      testWidgets('handles optional description field correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify description field is optional and handled properly
        /// This ensures optional fields don't prevent valid program creation
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter only required field (name)
        await tester.enterText(
          find.byType(TextFormField).first,
          'Program Without Description',
        );
        
        // Leave description empty and submit
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should succeed without description
        verify(mockProvider.createProgram(any)).called(1);
      });
    });

    group('User Interactions', () {
      testWidgets('close button navigates back correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify close button provides proper navigation
        /// This ensures users can exit the form without saving
        bool navigatedBack = false;
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: Builder(
                builder: (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateProgramScreen(),
                        ),
                      ).then((_) => navigatedBack = true);
                    },
                    child: Text('Open Create Screen'),
                  ),
                ),
              ),
            ),
          ),
        );

        // Navigate to create screen
        await tester.tap(find.text('Open Create Screen'));
        await tester.pumpAndSettle();

        // Tap close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify navigation back
        expect(find.text('Open Create Screen'), findsOneWidget);
      });

      testWidgets('form submission triggers provider method with correct data', (WidgetTester tester) async {
        /// Test Purpose: Verify form data is passed correctly to provider
        /// This ensures data integrity from UI to business logic layer
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Fill out form
        await tester.enterText(
          find.byType(TextFormField).first,
          'Test Program Name',
        );
        
        await tester.enterText(
          find.byType(TextFormField).last,
          'Test program description',
        );

        // Submit form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify provider was called with correct data
        final capturedProgram = verify(mockProvider.createProgram(captureAny)).captured.single as Program;
        expect(capturedProgram.name, 'Test Program Name');
        expect(capturedProgram.description, 'Test program description');
      });
    });

    group('Loading States and Error Handling', () {
      testWidgets('displays loading indicator during program creation', (WidgetTester tester) async {
        /// Test Purpose: Verify loading state provides proper user feedback
        /// This ensures users understand when operations are in progress
        when(mockProvider.isLoadingPrograms).thenReturn(true);
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Submit button should be disabled
        final submitButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(submitButton.onPressed, isNull);
      });

      testWidgets('displays error message when creation fails', (WidgetTester tester) async {
        /// Test Purpose: Verify error handling displays appropriate user feedback
        /// This ensures users are informed when operations fail
        const errorMessage = 'Failed to create program: Network error';
        when(mockProvider.error).thenReturn(errorMessage);
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('clears error state when user modifies input', (WidgetTester tester) async {
        /// Test Purpose: Verify error states are cleared when user continues editing
        /// This ensures error messages don't persist inappropriately
        when(mockProvider.error).thenReturn('Previous error');
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify error is shown
        expect(find.text('Previous error'), findsOneWidget);

        // Simulate user typing (should clear error)
        when(mockProvider.error).thenReturn(null);
        await tester.enterText(find.byType(TextFormField).first, 'New input');
        await tester.pumpAndSettle();

        // Error should be cleared
        expect(find.text('Previous error'), findsNothing);
      });
    });

    group('Provider Integration', () {
      testWidgets('responds to provider state changes correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify UI updates when provider state changes
        /// This ensures reactive UI behavior with state management
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially not loading
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Simulate loading state change
        when(mockProvider.isLoadingPrograms).thenReturn(true);
        mockProvider.notifyListeners();
        await tester.pumpAndSettle();

        // Should now show loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('handles successful program creation flow', (WidgetTester tester) async {
        /// Test Purpose: Verify complete successful creation workflow
        /// This ensures the happy path user experience works correctly
        bool navigationOccurred = false;
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: Builder(
                builder: (context) => CreateProgramScreen(),
              ),
              onGenerateRoute: (settings) {
                if (settings.name == '/') {
                  navigationOccurred = true;
                }
                return MaterialPageRoute(builder: (_) => Scaffold());
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Fill out form
        await tester.enterText(
          find.byType(TextFormField).first,
          'Successful Program',
        );

        // Submit form
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify provider method was called
        verify(mockProvider.createProgram(any)).called(1);
      });
    });

    group('Form Validation Edge Cases', () {
      testWidgets('handles whitespace-only program names', (WidgetTester tester) async {
        /// Test Purpose: Verify whitespace validation prevents invalid names
        /// This ensures data quality by rejecting whitespace-only input
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter whitespace-only name
        await tester.enterText(
          find.byType(TextFormField).first,
          '   \n\t   ',
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.textContaining('enter a program name'), findsOneWidget);
        verifyNever(mockProvider.createProgram(any));
      });

      testWidgets('trims whitespace from program name and description', (WidgetTester tester) async {
        /// Test Purpose: Verify input trimming for clean data storage
        /// This ensures consistent data formatting and prevents whitespace issues
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter name and description with extra whitespace
        await tester.enterText(
          find.byType(TextFormField).first,
          '  Trimmed Program  ',
        );
        
        await tester.enterText(
          find.byType(TextFormField).last,
          '  Trimmed description  ',
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify trimmed data was passed to provider
        final capturedProgram = verify(mockProvider.createProgram(captureAny)).captured.single as Program;
        expect(capturedProgram.name, 'Trimmed Program');
        expect(capturedProgram.description, 'Trimmed description');
      });

      testWidgets('handles special characters and unicode input', (WidgetTester tester) async {
        /// Test Purpose: Verify international character support in form fields
        /// This ensures global usability and proper text handling
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Enter international characters and emojis
        await tester.enterText(
          find.byType(TextFormField).first,
          'Программа Упражнений 🏋️‍♂️',
        );
        
        await tester.enterText(
          find.byType(TextFormField).last,
          'Descripción con acentos y émojis 💪🎯',
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify unicode input was handled correctly
        final capturedProgram = verify(mockProvider.createProgram(captureAny)).captured.single as Program;
        expect(capturedProgram.name, contains('Программа'));
        expect(capturedProgram.name, contains('🏋️‍♂️'));
        expect(capturedProgram.description, contains('émojis'));
        expect(capturedProgram.description, contains('💪'));
      });
    });

    group('State Management Integration', () {
      testWidgets('reacts to provider loading state changes', (WidgetTester tester) async {
        /// Test Purpose: Verify UI responds to all provider state changes
        /// This ensures reactive UI behavior throughout the operation lifecycle
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially not loading
        expect(find.byType(CircularProgressIndicator), findsNothing);
        
        // Change to loading state
        when(mockProvider.isLoadingPrograms).thenReturn(true);
        mockProvider.notifyListeners();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Change back to not loading
        when(mockProvider.isLoadingPrograms).thenReturn(false);
        mockProvider.notifyListeners();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('handles provider error state transitions', (WidgetTester tester) async {
        /// Test Purpose: Verify UI handles error state changes correctly
        /// This ensures proper error display and recovery
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Initially no error
        expect(find.byIcon(Icons.error), findsNothing);

        // Set error state
        when(mockProvider.error).thenReturn('Test error message');
        mockProvider.notifyListeners();
        await tester.pump();

        expect(find.text('Test error message'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);

        // Clear error state
        when(mockProvider.error).thenReturn(null);
        mockProvider.notifyListeners();
        await tester.pump();

        expect(find.text('Test error message'), findsNothing);
        expect(find.byIcon(Icons.error), findsNothing);
      });
    });

    group('Accessibility and Usability', () {
      testWidgets('provides proper semantic labels for screen readers', (WidgetTester tester) async {
        /// Test Purpose: Verify accessibility support for screen readers
        /// This ensures the app is usable by users with visual impairments
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify semantic labels exist
        expect(find.bySemanticsLabel('Program Name'), findsOneWidget);
        expect(find.bySemanticsLabel('Description'), findsOneWidget);
        expect(find.bySemanticsLabel('Create Program'), findsOneWidget);
      });

      testWidgets('supports keyboard navigation', (WidgetTester tester) async {
        /// Test Purpose: Verify keyboard navigation works properly
        /// This ensures accessibility and desktop usability
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test tab navigation between fields
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Verify focus management
        final focusedField = FocusManager.instance.primaryFocus;
        expect(focusedField, isNotNull);
      });

      testWidgets('handles different screen sizes appropriately', (WidgetTester tester) async {
        /// Test Purpose: Verify responsive design works on different screen sizes
        /// This ensures consistent user experience across devices
        
        // Test with small screen
        await tester.binding.setSurfaceSize(Size(320, 568)); // iPhone SE size
        
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify all elements are still visible
        expect(find.text('Create Program'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Test with large screen
        await tester.binding.setSurfaceSize(Size(1024, 768)); // Tablet size
        await tester.pumpAndSettle();

        // Should still render correctly
        expect(find.text('Create Program'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
      });
    });

    group('Performance and Memory', () {
      testWidgets('disposes resources properly when screen is closed', (WidgetTester tester) async {
        /// Test Purpose: Verify proper resource cleanup prevents memory leaks
        /// This ensures the screen doesn't cause memory leaks
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Navigate away from screen
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Text('Different Screen')),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen is no longer in widget tree
        expect(find.byType(CreateProgramScreen), findsNothing);
      });

      testWidgets('handles rapid user input without performance issues', (WidgetTester tester) async {
        /// Test Purpose: Verify form handles rapid input changes efficiently
        /// This ensures responsive UI during fast typing
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Simulate rapid typing
        for (int i = 0; i < 10; i++) {
          await tester.enterText(
            find.byType(TextFormField).first,
            'Program Name $i',
          );
          await tester.pump(Duration(milliseconds: 10)); // Very fast updates
        }

        // Should handle rapid updates without issues
        expect(find.text('Program Name 9'), findsOneWidget);
      });
    });

    group('Integration with Material Design', () {
      testWidgets('follows Material Design theme correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify screen follows Material Design guidelines
        /// This ensures consistent design language across the application
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Material Design components
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('adapts to dark theme correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify screen works with dark theme
        /// This ensures theme consistency and user preference support
        await tester.pumpWidget(
          ChangeNotifierProvider<ProgramProvider>(
            create: (_) => mockProvider,
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: CreateProgramScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify screen renders with dark theme
        expect(find.byType(CreateProgramScreen), findsOneWidget);
        expect(find.text('Create Program'), findsOneWidget);
      });
    });
  });
}

/// Test utilities for widget testing
class WidgetTestUtils {
  static Widget createTestApp(Widget home, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: home,
    );
  }

  static Widget createTestAppWithProvider(Widget home, ProgramProvider provider) {
    return ChangeNotifierProvider<ProgramProvider>(
      create: (_) => provider,
      child: MaterialApp(home: home),
    );
  }
}