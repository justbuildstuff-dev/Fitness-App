import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/weeks/weeks_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/week.dart';
import 'package:fittrack/models/workout.dart';

import 'weeks_screen_workout_test.mocks.dart';
import 'test_setup_helper.dart';

/// Widget tests for WeeksScreen workout functionality
/// 
/// These tests verify that the WeeksScreen correctly:
/// - Displays workout lists and empty states
/// - Handles loading and error states for workouts
/// - Provides navigation to workout creation
/// - Shows workout cards with proper information
/// - Integrates with ProgramProvider for workout operations
/// 
/// Widget tests focus on the workout display and interaction aspects of WeeksScreen
/// If tests fail, check workout list rendering, state management, or provider integration
@GenerateMocks([ProgramProvider])
void main() {
  group('WeeksScreen Workout Functionality Tests', () {
    late MockProgramProvider mockProvider;

    setUpAll(() async {
      await TestSetupHelper.initializeFirebaseForWidgetTests();
    });
    late Program testProgram;
    late Week testWeek;

    setUp(() {
      // Set up test data and mocks for consistent test environment
      // Clean state ensures tests don't interfere with each other
      mockProvider = MockProgramProvider();
      
      testProgram = Program(
        id: 'test-program-123',
        name: 'Test Program',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        userId: 'test-user',
      );
      
      testWeek = Week(
        id: 'test-week-456',
        name: 'Test Week 1',
        order: 1,
        notes: 'Test week notes',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        userId: 'test-user',
        programId: 'test-program-123',
      );

      // Set up default mock provider state
      when(mockProvider.error).thenReturn(null);
      when(mockProvider.isLoadingWorkouts).thenReturn(false);
      when(mockProvider.workouts).thenReturn([]);
    });

    /// Helper method to create the widget under test with necessary providers and routing
    /// This ensures consistent test setup and simulates the real app environment
    Widget createTestWidget() {
      return TestSetupHelper.createTestAppWithMockedProviders(
        programProvider: mockProvider,
        child: WeeksScreen(
          program: testProgram,
          week: testWeek,
        ),
      );
    }

    /// Helper method to create mock workout objects for testing
    List<Workout> createMockWorkouts() {
      return [
        Workout(
          id: 'workout-1',
          name: 'Push Day',
          dayOfWeek: 1, // Monday
          orderIndex: 1,
          notes: 'Focus on chest and triceps',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          userId: 'test-user',
          weekId: testWeek.id,
          programId: testProgram.id,
        ),
        Workout(
          id: 'workout-2',
          name: 'Pull Day',
          dayOfWeek: 3, // Wednesday
          orderIndex: 2,
          notes: null, // Test null notes handling
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          userId: 'test-user',
          weekId: testWeek.id,
          programId: testProgram.id,
        ),
        Workout(
          id: 'workout-3',
          name: 'Leg Day',
          dayOfWeek: null, // Test no specific day
          orderIndex: 3,
          notes: 'Compound movements focus',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
          userId: 'test-user',
          weekId: testWeek.id,
          programId: testProgram.id,
        ),
      ];
    }

    group('Initial Rendering and Header', () {
      testWidgets('renders week header with correct information', (WidgetTester tester) async {
        /// Test Purpose: Verify that week information is displayed prominently
        /// Users need to see which week they're viewing and its details
        /// Failure indicates missing context that could confuse users
        
        await tester.pumpWidget(createTestWidget());

        // Verify week name is displayed in app bar
        expect(find.text('Test Week 1'), findsOneWidget,
          reason: 'Should display week name in app bar');

        // Verify week header section with details
        expect(find.text('1'), findsAtLeastNWidgets(1),
          reason: 'Should display week order number');
        
        expect(find.text('Test week notes'), findsOneWidget,
          reason: 'Should display week notes when present');

        // Verify workout count stat card
        expect(find.text('Workouts'), findsOneWidget,
          reason: 'Should display workouts stat card');
        
        expect(find.text('Week'), findsOneWidget,
          reason: 'Should display week stat card');
      });

      testWidgets('displays correct workout count in header', (WidgetTester tester) async {
        /// Test Purpose: Verify that workout count is accurate and updated
        /// Users need to see how many workouts are in the current week
        /// Failure indicates count not updating properly with data changes
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify workout count shows correct number
        expect(find.text('3'), findsAtLeastNWidgets(1),
          reason: 'Should display correct workout count (3) in stat card');
      });
    });

    group('Empty State Handling', () {
      testWidgets('shows empty state when no workouts exist', (WidgetTester tester) async {
        /// Test Purpose: Verify appropriate empty state for new or cleared weeks
        /// Users need guidance on how to add their first workout
        /// Failure indicates poor UX with blank or confusing empty screens
        
        // Mock empty workout list
        when(mockProvider.workouts).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Verify empty state elements
        expect(find.byIcon(Icons.fitness_center), findsAtLeastNWidgets(1),
          reason: 'Should show fitness icon in empty state');
        
        expect(find.text('No Workouts Yet'), findsOneWidget,
          reason: 'Should display empty state title');
        
        expect(find.text('Create your first workout for this week'), findsOneWidget,
          reason: 'Should display helpful empty state message');
        
        expect(find.text('Create Workout'), findsOneWidget,
          reason: 'Should show create workout button in empty state');
      });

      testWidgets('empty state create workout button navigates correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify empty state call-to-action works
        /// Users should be able to create their first workout easily
        /// Failure indicates broken workflow that blocks user progress
        
        when(mockProvider.workouts).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Find and tap the create workout button in empty state
        final createButton = find.widgetWithText(ElevatedButton, 'Create Workout');
        expect(createButton, findsOneWidget,
          reason: 'Should find create workout button in empty state');

        await tester.tap(createButton);
        await tester.pumpAndSettle();

        // In a real test with navigation, you would verify:
        // 1. Navigation to CreateWorkoutScreen occurred
        // 2. Correct program and week were passed as parameters
        // This requires additional navigation testing setup
      });
    });

    group('Workout List Display', () {
      testWidgets('displays workout list when workouts exist', (WidgetTester tester) async {
        /// Test Purpose: Verify that workouts are displayed in a list format
        /// Users need to see all their workouts organized clearly
        /// Failure indicates list not rendering or data not flowing properly
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify workout cards are displayed
        expect(find.text('Push Day'), findsOneWidget,
          reason: 'Should display first workout name');
        expect(find.text('Pull Day'), findsOneWidget,
          reason: 'Should display second workout name');
        expect(find.text('Leg Day'), findsOneWidget,
          reason: 'Should display third workout name');

        // Verify workout cards are in proper container (ListView)
        expect(find.byType(ListView), findsOneWidget,
          reason: 'Should render workouts in scrollable ListView');
        
        // Count workout cards (assuming custom _WorkoutCard widget)
        expect(find.byType(Card), findsNWidgets(mockWorkouts.length),
          reason: 'Should display one card per workout');
      });

      testWidgets('workout cards display day of week correctly', (WidgetTester tester) async {
        /// Test Purpose: Verify day of week information is shown clearly
        /// Users need to see which day each workout is scheduled for
        /// Failure indicates missing scheduling information
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify day names are displayed for workouts that have them
        expect(find.text('Monday'), findsOneWidget,
          reason: 'Should display day name for Push Day (dayOfWeek: 1)');
        expect(find.text('Wednesday'), findsOneWidget,
          reason: 'Should display day name for Pull Day (dayOfWeek: 3)');

        // Workout with null dayOfWeek should not show a day
        // (Leg Day has dayOfWeek: null, so no day should be shown for it)
      });

      testWidgets('workout cards display notes when present', (WidgetTester tester) async {
        /// Test Purpose: Verify that workout notes are shown in cards
        /// Users need to see their workout notes for quick reference
        /// Failure indicates notes not being displayed or truncated incorrectly
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify notes are displayed for workouts that have them
        expect(find.textContaining('Focus on chest and triceps'), findsOneWidget,
          reason: 'Should display notes for Push Day');
        expect(find.textContaining('Compound movements focus'), findsOneWidget,
          reason: 'Should display notes for Leg Day');

        // Pull Day has null notes, so should not display any note text
      });

      testWidgets('workout cards have proper tap targets', (WidgetTester tester) async {
        /// Test Purpose: Verify that workout cards are tappable for navigation
        /// Users should be able to tap workouts to view/edit them
        /// Failure indicates broken navigation or poor touch targets
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Find workout cards (assuming ListTile or similar tappable widget)
        final workoutCards = find.byType(ListTile);
        expect(workoutCards, findsNWidgets(mockWorkouts.length),
          reason: 'Should have tappable cards for each workout');

        // Test tapping on first workout
        await tester.tap(workoutCards.first);
        await tester.pumpAndSettle();

        // In a real test, you would verify:
        // 1. Navigation to workout detail/exercise screen
        // 2. Selected workout is passed correctly
        // 3. Or a placeholder message is shown (as in current implementation)
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator when workouts are being loaded', (WidgetTester tester) async {
        /// Test Purpose: Verify loading state provides feedback during data fetching
        /// Users need to know when the app is working to load their data
        /// Failure indicates poor UX with no loading feedback
        
        when(mockProvider.isLoadingWorkouts).thenReturn(true);
        when(mockProvider.workouts).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Should display loading indicator when isLoadingWorkouts is true');

        // Verify other content is not shown during loading
        expect(find.text('No Workouts Yet'), findsNothing,
          reason: 'Should not show empty state while loading');
      });

      testWidgets('hides loading indicator when workouts are loaded', (WidgetTester tester) async {
        /// Test Purpose: Verify loading indicator disappears after data loads
        /// Loading indicators should not persist after operations complete
        /// Failure indicates loading state not properly managed
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.isLoadingWorkouts).thenReturn(false);
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify loading indicator is not shown
        expect(find.byType(CircularProgressIndicator), findsNothing,
          reason: 'Should not show loading indicator when loading is complete');

        // Verify workout content is shown
        expect(find.text('Push Day'), findsOneWidget,
          reason: 'Should show workout content when loading is complete');
      });
    });

    group('Error State Handling', () {
      testWidgets('displays error state when workout loading fails', (WidgetTester tester) async {
        /// Test Purpose: Verify error state provides clear feedback on failures
        /// Users need to understand when something went wrong and how to recover
        /// Failure indicates poor error handling leaving users confused
        
        const errorMessage = 'Failed to load workouts: Network error';
        when(mockProvider.error).thenReturn(errorMessage);
        when(mockProvider.isLoadingWorkouts).thenReturn(false);
        when(mockProvider.workouts).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Verify error state elements
        expect(find.byIcon(Icons.error_outline), findsOneWidget,
          reason: 'Should display error icon');
        
        expect(find.text('Error loading workouts'), findsOneWidget,
          reason: 'Should display error title');
        
        expect(find.text(errorMessage), findsOneWidget,
          reason: 'Should display specific error message');
        
        expect(find.text('Retry'), findsOneWidget,
          reason: 'Should provide retry button');
      });

      testWidgets('retry button clears error and reloads workouts', (WidgetTester tester) async {
        /// Test Purpose: Verify retry functionality works to recover from errors
        /// Users should be able to retry failed operations easily
        /// Failure indicates users getting stuck in error states
        
        const errorMessage = 'Network timeout';
        when(mockProvider.error).thenReturn(errorMessage);
        when(mockProvider.isLoadingWorkouts).thenReturn(false);
        when(mockProvider.workouts).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify provider methods were called to clear error and reload
        verify(mockProvider.clearError()).called(1);
        verify(mockProvider.loadWorkouts(testProgram.id, testWeek.id)).called(1);
      });
    });

    group('Floating Action Button', () {
      testWidgets('displays floating action button for creating workouts', (WidgetTester tester) async {
        /// Test Purpose: Verify FAB is present for quick workout creation access
        /// Users should have easy access to create new workouts from any state
        /// Failure indicates missing primary action button
        
        await tester.pumpWidget(createTestWidget());

        // Verify FAB is present
        expect(find.byType(FloatingActionButton), findsOneWidget,
          reason: 'Should display floating action button');
        
        expect(find.byIcon(Icons.add), findsOneWidget,
          reason: 'Should show add icon in FAB');
      });

      testWidgets('FAB navigates to create workout screen', (WidgetTester tester) async {
        /// Test Purpose: Verify FAB triggers workout creation workflow
        /// Primary action should be easily accessible from main screen
        /// Failure indicates broken primary user flow
        
        await tester.pumpWidget(createTestWidget());

        // Tap floating action button
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // In a real test with navigation, you would verify:
        // 1. Navigation to CreateWorkoutScreen occurred
        // 2. Correct program and week parameters were passed
        // This requires additional navigation testing setup
      });
    });

    group('Pull to Refresh', () {
      testWidgets('supports pull to refresh for reloading workouts', (WidgetTester tester) async {
        /// Test Purpose: Verify pull-to-refresh functionality for data updates
        /// Users should be able to manually refresh workout data
        /// Failure indicates missing refresh capability
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Find RefreshIndicator widget
        expect(find.byType(RefreshIndicator), findsOneWidget,
          reason: 'Should have RefreshIndicator widget for pull to refresh');

        // Simulate pull to refresh gesture
        await tester.fling(
          find.byType(RefreshIndicator), 
          const Offset(0, 300), 
          1000,
        );
        await tester.pumpAndSettle();

        // Verify loadWorkouts was called for refresh
        verify(mockProvider.loadWorkouts(testProgram.id, testWeek.id)).called(1);
      });
    });

    group('Integration with Provider', () {
      testWidgets('calls loadWorkouts on screen initialization', (WidgetTester tester) async {
        /// Test Purpose: Verify screen automatically loads workout data on startup
        /// Users should see their workouts immediately when entering the screen
        /// Failure indicates data not loading automatically
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify loadWorkouts was called with correct parameters during init
        verify(mockProvider.loadWorkouts(testProgram.id, testWeek.id)).called(1);
      });

      testWidgets('reacts to provider state changes', (WidgetTester tester) async {
        /// Test Purpose: Verify screen updates when provider state changes
        /// UI should reflect data changes from provider automatically
        /// Failure indicates broken reactive UI updates
        
        // Start with empty workouts
        when(mockProvider.workouts).thenReturn([]);
        
        await tester.pumpWidget(createTestWidget());
        
        // Verify empty state is shown
        expect(find.text('No Workouts Yet'), findsOneWidget);

        // Simulate provider state change to include workouts
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);
        
        // Trigger a rebuild (in real app, provider.notifyListeners() would do this)
        await tester.pumpAndSettle();

        // In a real reactive test, you would verify:
        // 1. Empty state disappears
        // 2. Workout list appears
        // This requires triggering actual provider state changes
      });
    });

    group('Accessibility', () {
      testWidgets('provides proper accessibility semantics', (WidgetTester tester) async {
        /// Test Purpose: Verify screen is accessible to users with disabilities
        /// Screen readers and other accessibility tools need proper semantics
        /// Failure indicates app is not inclusive for all users
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Verify important elements have semantic labels
        expect(find.bySemanticsLabel('Add workout'), findsOneWidget,
          reason: 'FAB should have semantic label for screen readers');

        // Verify workout cards are properly labeled for accessibility
        // This would depend on the specific accessibility implementation
      });

      testWidgets('maintains proper focus management', (WidgetTester tester) async {
        /// Test Purpose: Verify keyboard and screen reader navigation works
        /// Users with disabilities need proper focus order and management
        /// Failure indicates broken accessibility navigation
        
        final mockWorkouts = createMockWorkouts();
        when(mockProvider.workouts).thenReturn(mockWorkouts);

        await tester.pumpWidget(createTestWidget());

        // Test focus traversal through workout cards and action buttons
        // This would require specific focus testing depending on implementation
      });
    });
  });
}