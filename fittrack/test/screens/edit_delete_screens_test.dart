import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/screens/programs/create_program_screen.dart';
import 'package:fittrack/screens/weeks/create_week_screen.dart';
import 'package:fittrack/widgets/delete_confirmation_dialog.dart';

import 'edit_delete_screens_test.mocks.dart';

/// Widget tests for edit and delete functionality screens
/// 
/// These tests verify that the UI components correctly:
/// - Display edit forms with pre-populated data
/// - Handle form submission for both create and edit modes
/// - Show appropriate confirmation dialogs for delete operations
/// - Provide proper user feedback for successful and failed operations
/// 
/// Tests use mocked providers to isolate UI behavior
/// and ensure reliable test execution.

@GenerateMocks([ProgramProvider, app_auth.AuthProvider])
void main() {
  group('Edit/Delete Screens Widget Tests', () {
    late MockProgramProvider mockProvider;
    late MockAuthProvider mockAuthProvider;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    late Program testProgram;
    late Week testWeek;

    setUp(() {
      mockProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();
      
      testProgram = Program(
        id: 'prog123',
        name: 'Test Program',
        description: 'Test Description',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user123',
      );

      testWeek = Week(
        id: 'week123',
        name: 'Test Week',
        order: 1,
        notes: 'Test notes',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userId: 'user123',
        programId: 'prog123',
      );

      // Set up basic mock responses
      when(mockProvider.updateProgramFields(anyNamed('programId'), name: anyNamed('name'), description: anyNamed('description')))
          .thenAnswer((_) async {});
      when(mockProvider.createProgram(name: anyNamed('name'), description: anyNamed('description')))
          .thenAnswer((_) async => 'new_program_id');
      when(mockProvider.updateWeekFields(anyNamed('weekId'), name: anyNamed('name'), notes: anyNamed('notes')))
          .thenAnswer((_) async {});
      when(mockProvider.createWeek(programId: anyNamed('programId'), name: anyNamed('name'), notes: anyNamed('notes')))
          .thenAnswer((_) async => 'new_week_id');
      when(mockProvider.weeks).thenReturn([]);
      when(mockProvider.selectedProgram).thenReturn(testProgram);
      
      // Set up auth provider mocks to prevent Firebase calls
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
    });

    Widget createTestWidget({required Widget child}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<ProgramProvider>.value(value: mockProvider),
            ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
          ],
          child: child,
        ),
      );
    }

    group('CreateProgramScreen Edit Mode', () {
      testWidgets('displays edit mode UI when program is provided', (tester) async {
        /// Test Purpose: Verify edit mode shows correct title and button text
        /// Users should clearly understand they're editing an existing program
        
        await tester.pumpWidget(createTestWidget(
          child: CreateProgramScreen(program: testProgram),
        ));

        await tester.pumpAndSettle();

        // Verify edit mode UI elements
        expect(find.text('Edit Program'), findsOneWidget);
        expect(find.text('SAVE'), findsOneWidget);
        expect(find.text('CREATE'), findsNothing);
      });

      testWidgets('pre-populates form fields with existing program data', (tester) async {
        /// Test Purpose: Verify form fields are populated with current values
        /// Users should see existing data when editing programs
        
        await tester.pumpWidget(createTestWidget(
          child: CreateProgramScreen(program: testProgram),
        ));

        await tester.pumpAndSettle();

        // Verify form fields are populated
        expect(find.widgetWithText(TextFormField, testProgram.name), findsOneWidget);
        expect(find.widgetWithText(TextFormField, testProgram.description!), findsOneWidget);
      });

      testWidgets('calls updateProgramFields on save in edit mode', (tester) async {
        /// Test Purpose: Verify edit mode saves updates correctly
        /// Form submission should call update method instead of create
        
        await tester.pumpWidget(createTestWidget(
          child: CreateProgramScreen(program: testProgram),
        ));

        await tester.pumpAndSettle();

        // Modify the name field
        await tester.enterText(
          find.widgetWithText(TextFormField, testProgram.name),
          'Modified Program Name',
        );

        // Tap save button
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Verify update method was called
        verify(mockProvider.updateProgramFields(
          testProgram.id,
          name: 'Modified Program Name',
          description: testProgram.description,
        )).called(1);
      });

      testWidgets('shows success message and navigates back after successful edit', (tester) async {
        /// Test Purpose: Verify successful edit provides user feedback
        /// Users should see confirmation and return to previous screen
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProgramProvider>.value(
                value: mockProvider,
                child: CreateProgramScreen(program: testProgram),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Verify success message
        expect(find.text('Program updated successfully!'), findsOneWidget);
      });

      testWidgets('handles update errors gracefully', (tester) async {
        /// Test Purpose: Verify error handling during program updates
        /// Users should see meaningful error messages when updates fail
        
        when(mockProvider.updateProgramFields(any, name: anyNamed('name'), description: any))
            .thenThrow(Exception('Update failed'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProgramProvider>.value(
                value: mockProvider,
                child: CreateProgramScreen(program: testProgram),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Verify error message is shown
        expect(find.textContaining('Failed to update program'), findsOneWidget);
      });
    });

    group('CreateProgramScreen Create Mode', () {
      testWidgets('displays create mode UI when no program provided', (tester) async {
        /// Test Purpose: Verify create mode shows correct UI elements
        /// Users should understand they're creating a new program
        
        await tester.pumpWidget(createTestWidget(
          child: const CreateProgramScreen(),
        ));

        await tester.pumpAndSettle();

        // Verify create mode UI elements
        expect(find.text('Create Program'), findsOneWidget);
        expect(find.text('CREATE'), findsOneWidget);
        expect(find.text('SAVE'), findsNothing);
      });

      testWidgets('calls createProgram on save in create mode', (tester) async {
        /// Test Purpose: Verify create mode creates new programs
        /// Form submission should call create method
        
        await tester.pumpWidget(createTestWidget(
          child: const CreateProgramScreen(),
        ));

        await tester.pumpAndSettle();

        // Fill in form fields
        await tester.enterText(
          find.byType(TextFormField).first,
          'New Program',
        );

        await tester.enterText(
          find.byType(TextFormField).last,
          'New Description',
        );

        // Tap create button
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify create method was called
        verify(mockProvider.createProgram(
          name: 'New Program',
          description: 'New Description',
        )).called(1);
      });
    });

    group('CreateWeekScreen Edit Mode', () {
      testWidgets('displays edit mode UI when week is provided', (tester) async {
        /// Test Purpose: Verify week edit mode shows correct UI
        /// Users should understand they're editing an existing week
        
        await tester.pumpWidget(createTestWidget(
          child: CreateWeekScreen(program: testProgram, week: testWeek),
        ));

        await tester.pumpAndSettle();

        // Verify edit mode UI elements
        expect(find.text('Edit Week'), findsOneWidget);
        expect(find.text('SAVE'), findsOneWidget);
      });

      testWidgets('pre-populates form fields with existing week data', (tester) async {
        /// Test Purpose: Verify week form fields are populated correctly
        /// Users should see existing data when editing weeks
        
        await tester.pumpWidget(createTestWidget(
          child: CreateWeekScreen(program: testProgram, week: testWeek),
        ));

        await tester.pumpAndSettle();

        // Verify form fields are populated
        expect(find.widgetWithText(TextFormField, testWeek.name), findsOneWidget);
        expect(find.widgetWithText(TextFormField, testWeek.notes!), findsOneWidget);
      });

      testWidgets('calls updateWeekFields on save in edit mode', (tester) async {
        /// Test Purpose: Verify week edit saves updates correctly
        /// Form submission should call week update method
        
        await tester.pumpWidget(createTestWidget(
          child: CreateWeekScreen(program: testProgram, week: testWeek),
        ));

        await tester.pumpAndSettle();

        // Modify the name field
        await tester.enterText(
          find.widgetWithText(TextFormField, testWeek.name),
          'Modified Week Name',
        );

        // Tap save button
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Verify update method was called
        verify(mockProvider.updateWeekFields(
          testWeek.id,
          name: 'Modified Week Name',
          notes: testWeek.notes,
        )).called(1);
      });

      testWidgets('handles week update errors gracefully', (tester) async {
        /// Test Purpose: Verify error handling during week updates
        /// Failed updates should provide clear user feedback
        
        when(mockProvider.updateWeekFields(any, name: anyNamed('name'), notes: anyNamed('notes')))
            .thenThrow(Exception('Week update failed'));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<ProgramProvider>.value(
                value: mockProvider,
                child: CreateWeekScreen(program: testProgram, week: testWeek),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap save button
        await tester.tap(find.text('SAVE'));
        await tester.pumpAndSettle();

        // Verify error message is shown
        expect(find.textContaining('Failed to update week'), findsOneWidget);
      });
    });

    group('DeleteConfirmationDialog', () {
      testWidgets('displays correct confirmation dialog content', (tester) async {
        /// Test Purpose: Verify delete confirmation shows appropriate warning
        /// Users should understand the consequences of deletion
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    DeleteConfirmationDialog.show(
                      context: context,
                      title: 'Delete Program',
                      content: 'This will permanently delete the program.',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Trigger dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog content
        expect(find.text('Delete Program'), findsOneWidget);
        expect(find.text('This will permanently delete the program.'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      });

      testWidgets('returns true when delete is confirmed', (tester) async {
        /// Test Purpose: Verify dialog returns correct result on confirmation
        /// Delete operations should proceed when user confirms
        
        bool? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await DeleteConfirmationDialog.show(
                      context: context,
                      title: 'Delete Program',
                      content: 'Confirm deletion.',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Trigger dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Tap delete button
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Verify result
        expect(dialogResult, isTrue);
      });

      testWidgets('returns false when delete is cancelled', (tester) async {
        /// Test Purpose: Verify dialog returns correct result on cancellation
        /// Delete operations should be aborted when user cancels
        
        bool? dialogResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    dialogResult = await DeleteConfirmationDialog.show(
                      context: context,
                      title: 'Delete Program',
                      content: 'Confirm deletion.',
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        // Trigger dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Tap cancel button
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify result
        expect(dialogResult, isFalse);
      });
    });

    group('Form Validation', () {
      testWidgets('prevents submission with invalid data', (tester) async {
        /// Test Purpose: Verify form validation prevents invalid submissions
        /// Users should see validation errors for empty required fields
        
        await tester.pumpWidget(createTestWidget(
          child: const CreateProgramScreen(),
        ));

        await tester.pumpAndSettle();

        // Try to submit without filling required fields
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify validation error is shown
        expect(find.text('Please enter a program name'), findsOneWidget);
        
        // Verify create method was not called
        verifyNever(mockProvider.createProgram(name: anyNamed('name')));
      });

      testWidgets('allows submission with valid data', (tester) async {
        /// Test Purpose: Verify form accepts valid input
        /// Properly filled forms should submit successfully
        
        await tester.pumpWidget(createTestWidget(
          child: const CreateProgramScreen(),
        ));

        await tester.pumpAndSettle();

        // Fill in required field
        await tester.enterText(
          find.byType(TextFormField).first,
          'Valid Program Name',
        );

        // Submit form
        await tester.tap(find.text('CREATE'));
        await tester.pumpAndSettle();

        // Verify create method was called
        verify(mockProvider.createProgram(name: 'Valid Program Name')).called(1);
      });
    });
  });
}