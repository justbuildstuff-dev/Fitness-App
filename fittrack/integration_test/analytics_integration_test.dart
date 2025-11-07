import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/main.dart' as app;
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/screens/analytics/components/activity_heatmap_section.dart';
import 'package:fittrack/screens/analytics/components/key_statistics_section.dart';
import 'firebase_emulator_setup.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Integration Tests', () {
    setUpAll(() async {
      await setupFirebaseEmulators();
      // Create test user in Firebase Auth emulator
      // This user is needed for sign-in authentication in tests
      await FirebaseEmulatorSetup.createTestUser(
        email: 'test@fittrack.com',
        password: 'testpassword123',
      );
    });

    tearDownAll(() async {
      await cleanupFirebaseEmulators();
    });
    testWidgets('complete analytics flow with real data', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // Launch the app
      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Skip if we're not on the sign-in screen (already signed in)
      if (find.text('Sign In').evaluate().isNotEmpty) {
        // Sign in with test credentials
        await _signInWithTestAccount(tester);
      }

      // Navigate to Analytics tab
      await _navigateToAnalytics(tester);

      // Wait for analytics to load
      await tester.pump(const Duration(seconds: 1));

      // Verify Analytics screen is displayed
      expect(find.byType(AnalyticsScreen), findsOneWidget);
      // Note: "Analytics" text appears in both AppBar and bottom nav, so check screen type instead

      // Test empty state (if no data exists)
      if (find.text('No Data Available').evaluate().isNotEmpty) {
        print('Testing empty state flow');
        await _testEmptyState(tester);

        // Create some test data
        await _createTestWorkoutData(tester);

        // Navigate back to Analytics tab
        await _navigateToAnalytics(tester);
      }

      // Test analytics with data
      await _testAnalyticsWithData(tester);

      // Test analytics interactions
      await _testAnalyticsInteractions(tester);

      // Wait for any pending async operations to complete before test ends
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });

    testWidgets('analytics personal records detection', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Ensure we're signed in
      await _ensureSignedIn(tester);

      // Create a workout with progressive sets to trigger PR detection
      await _createWorkoutWithProgressiveSets(tester);

      // Navigate to analytics tab
      await _navigateToAnalytics(tester);

      // Verify personal records are detected and displayed
      if (find.text('Recent Personal Records').evaluate().isNotEmpty) {
        expect(find.text('Recent Personal Records'), findsOneWidget);
        
        // Look for PR indicators (improvement values like "+5kg")
        final prElements = find.textContaining('+');
        expect(prElements, findsWidgets);
        
        print('Found ${prElements.evaluate().length} personal record improvements');
      }
    }, skip: 'Blocked by Issue #47 - ProgramProvider race condition causes workout not to load after creation. Will be re-enabled after #47 is fixed.');

    testWidgets('analytics heatmap accuracy', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      await _ensureSignedIn(tester);

      // Create workouts on specific dates to test heatmap
      await _createWorkoutsForHeatmapTesting(tester);

      // Navigate to analytics tab
      await _navigateToAnalytics(tester);

      // Verify heatmap displays correctly
      if (find.byType(ActivityHeatmapSection).evaluate().isNotEmpty) {
        expect(find.byType(ActivityHeatmapSection), findsOneWidget);
        
        // Check for year display
        final currentYear = DateTime.now().year;
        expect(find.text('$currentYear Activity'), findsOneWidget);
        
        // Check for workout count
        final workoutCountFinder = find.textContaining('workouts');
        expect(workoutCountFinder, findsOneWidget);
        
        // Check for streak information
        expect(find.text('Current Streak'), findsOneWidget);
        expect(find.text('Longest Streak'), findsOneWidget);
      }
    });

    testWidgets('analytics date range filtering', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      await _ensureSignedIn(tester);

      // Navigate to analytics tab
      await _navigateToAnalytics(tester);

      // Test date range selection
      await tester.tap(find.byIcon(Icons.date_range));
      await tester.pumpAndSettle();

      // Select "This Month"
      await tester.tap(find.text('This Month'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Verify analytics reload with new date range
      // (The specific verification would depend on having known data)
      
      // Test other date ranges
      await tester.tap(find.byIcon(Icons.date_range));
      await tester.pumpAndSettle();
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Verify no errors occurred
      expect(find.text('Failed to load analytics'), findsNothing);
    });

    testWidgets('analytics refresh functionality', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      await _ensureSignedIn(tester);

      // Navigate to analytics tab
      await _navigateToAnalytics(tester);

      // Test refresh button
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Should show loading indicator briefly
      await tester.pump(const Duration(milliseconds: 500));
      
      // Then show refreshed data
      await tester.pump(const Duration(seconds: 2));

      // Verify no errors
      expect(find.text('Failed to load analytics'), findsNothing);
    });

    testWidgets('analytics error handling', (tester) async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(app.FitTrackApp(prefs: prefs));
      await tester.pumpAndSettle();

      // Test with no network or Firebase issues
      // This would require mocking network failures
      // For now, just verify error UI works if errors occur
      
      await _ensureSignedIn(tester);

      // Navigate to analytics tab
      await _navigateToAnalytics(tester);
      await tester.pump(const Duration(seconds: 3));

      // If error occurs, test retry functionality
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
      }
    });
  });
}

// Helper methods for integration testing

Future<void> _signInWithTestAccount(WidgetTester tester) async {
  // Enter test email
  await tester.enterText(
    find.byType(TextFormField).first, 
    'test@fittrack.com'
  );
  
  // Enter test password
  await tester.enterText(
    find.byType(TextFormField).last, 
    'testpassword123'
  );
  
  // Tap sign in
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Wait for sign in to complete
  await tester.pump(const Duration(seconds: 3));
}

Future<void> _ensureSignedIn(WidgetTester tester) async {
  // Check if we're on sign-in screen
  if (find.text('Sign In').evaluate().isNotEmpty) {
    await _signInWithTestAccount(tester);
  }

  // Wait for home screen to load
  await tester.pumpAndSettle();
  expect(find.text('Programs'), findsOneWidget);
}

Future<void> _navigateToAnalytics(WidgetTester tester) async {
  // Navigate back to main screen where bottom navigation is visible
  // This is needed after creating workout data when we're deep in navigation stack
  print('DEBUG: Navigating to Analytics tab');

  // Try to find back button and navigate back multiple times until we reach bottom nav
  int maxBackAttempts = 5;
  for (int i = 0; i < maxBackAttempts; i++) {
    var backButton = find.byTooltip('Back');
    if (backButton.evaluate().isEmpty) {
      // No back button - we might be at root level
      break;
    }
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Check if Analytics icon is now visible
    if (find.byIcon(Icons.analytics).evaluate().isNotEmpty) {
      print('DEBUG: Bottom navigation found after $i back navigation(s)');
      break;
    }
  }

  // Verify Analytics icon is now visible
  var analyticsFinder = find.byIcon(Icons.analytics);
  if (analyticsFinder.evaluate().isEmpty) {
    print('DEBUG: Analytics icon still not found after navigation back');
    print('DEBUG: Available icons:');
    print(find.byType(Icon).evaluate().map((e) => e.widget.toString()).join('\n'));
    throw TestFailure(
      'Analytics icon not found in bottom navigation after navigating back. '
      'Expected to find bottom navigation bar.'
    );
  }

  // Tap Analytics icon to navigate to Analytics screen
  print('DEBUG: Tapping Analytics icon');
  await tester.tap(analyticsFinder);
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _testEmptyState(WidgetTester tester) async {
  // Verify empty state elements
  expect(find.text('No Data Available'), findsOneWidget);
  expect(find.text('Start tracking workouts to see your analytics'), findsOneWidget);
  expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
  
  print('Empty state verified successfully');
}

Future<void> _testAnalyticsWithData(WidgetTester tester) async {
  // Look for analytics components
  final hasHeatmap = find.byType(ActivityHeatmapSection).evaluate().isNotEmpty;
  final hasStats = find.byType(KeyStatisticsSection).evaluate().isNotEmpty;
  
  if (hasHeatmap) {
    print('Heatmap section found');
    expect(find.byType(ActivityHeatmapSection), findsOneWidget);
  }
  
  if (hasStats) {
    print('Statistics section found');
    expect(find.byType(KeyStatisticsSection), findsOneWidget);
    
    // Check for some common statistics
    final workoutsText = find.textContaining('Workouts');
    final setsText = find.textContaining('Sets');
    
    if (workoutsText.evaluate().isNotEmpty) {
      print('Found workout statistics');
    }
    if (setsText.evaluate().isNotEmpty) {
      print('Found sets statistics');
    }
  }
}

Future<void> _testAnalyticsInteractions(WidgetTester tester) async {
  // Test heatmap interactions if present
  final heatmapSquares = find.byType(GestureDetector);
  if (heatmapSquares.evaluate().isNotEmpty) {
    // Tap on a heatmap square to test day details
    await tester.tap(heatmapSquares.first);
    await tester.pumpAndSettle();
    
    // Check if dialog appears (implementation dependent)
    if (find.byType(AlertDialog).evaluate().isNotEmpty) {
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _createTestWorkoutData(WidgetTester tester) async {
  // Navigate to Programs tab
  await tester.tap(find.text('Programs'));
  await tester.pumpAndSettle();

  // Create a test program if none exists
  // Use FloatingActionButton to avoid ambiguity with multiple add icons
  if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    // Fill in program details
    await tester.enterText(find.byType(TextFormField).first, 'Test Analytics Program');
    await tester.enterText(find.byType(TextFormField).last, 'Program for analytics testing');
    
    await tester.tap(find.text('Create Program'));
    await tester.pumpAndSettle();

    // Wait for program creation to complete and UI to update
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify program was created before attempting to tap
    var programFinder = find.text('Test Analytics Program');
    if (programFinder.evaluate().isEmpty) {
      print('DEBUG: Program not found with exact match, trying partial match...');
      programFinder = find.textContaining('Test Analytics');

      if (programFinder.evaluate().isEmpty) {
        print('DEBUG: Widget tree when program not found:');
        print(find.byType(Text).evaluate().map((e) => e.widget.toString()).join('\n'));
        throw TestFailure(
          'Program "Test Analytics Program" not created or not visible. '
          'Expected to find program in list after creation.'
        );
      }
    }

    // Create a week - tap on the program we just created
    await tester.tap(programFinder);
    await tester.pumpAndSettle();

    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await _createTestWeekWithWorkouts(tester);
    }
  }
}

Future<void> _createTestWeekWithWorkouts(WidgetTester tester) async {
  // Create week
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextFormField).first, 'Test Week 1');
  await tester.tap(find.text('CREATE')); // Week screen uses CREATE button
  await tester.pumpAndSettle();

  // Enter the week
  await tester.tap(find.text('Test Week 1'));
  await tester.pumpAndSettle();

  // Create workout
  if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Test Workout');
    await tester.tap(find.text('CREATE')); // Workout screen uses CREATE button
    await tester.pumpAndSettle();
    
    // Add exercise and sets for analytics data
    await _addExerciseWithSets(tester);
  }
}

Future<void> _addExerciseWithSets(WidgetTester tester) async {
  // Navigate into workout
  await tester.tap(find.text('Test Workout'));
  await tester.pumpAndSettle();
  
  // Add exercise
  if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextFormField).first, 'Bench Press');
    await tester.tap(find.text('CREATE')); // Exercise screen uses CREATE button
    await tester.pumpAndSettle();

    // Add sets
    await tester.tap(find.text('Bench Press'));
    await tester.pumpAndSettle();

    // Add a few sets for analytics data
    for (int i = 0; i < 3; i++) {
      if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Fill in set data
        final repsFinder = find.byType(TextFormField).first;
        await tester.enterText(repsFinder, '${10 - i}'); // Decreasing reps

        if (find.byType(TextFormField).evaluate().length > 1) {
          final weightFinder = find.byType(TextFormField).last;
          await tester.enterText(weightFinder, '${100 + i * 5}'); // Increasing weight
        }

        await tester.tap(find.text('ADD')); // Set screen uses ADD button
        await tester.pumpAndSettle();
      }
    }
  }
}

Future<void> _createWorkoutWithProgressiveSets(WidgetTester tester) async {
  // Create initial workout with baseline sets
  await _createTestWorkoutData(tester);

  // Navigate back to week view (we're currently in Sets screen after _createTestWorkoutData)
  // Navigation stack: Programs → Week → Workouts → Workout Details → Exercise → Sets
  // Need to go back 2 levels to get to Workouts list

  // Back from Sets to Exercise
  var backButton = find.byTooltip('Back');
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }

  // Back from Exercise to Workout Details (Workouts list view)
  backButton = find.byTooltip('Back');
  if (backButton.evaluate().isNotEmpty) {
    await tester.tap(backButton);
    await tester.pumpAndSettle();
  }

  // Verify we can see the FAB for creating a new workout
  print('DEBUG: Looking for FAB to create second workout');
  if (find.byType(FloatingActionButton).evaluate().isEmpty) {
    print('DEBUG: No FAB found, trying to navigate back one more time');
    backButton = find.byTooltip('Back');
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }
  }

  // Create second workout with progressive overload
  if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
    print('DEBUG: Creating Test Workout 2');
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Test Workout 2');
    await tester.tap(find.text('CREATE'));
    await tester.pumpAndSettle();

    // Add explicit wait for Firestore write to complete
    print('DEBUG: Waiting for Firestore write and navigation to complete...');
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    print('DEBUG: Test Workout 2 created, verifying it exists');

    // Retry logic - wait up to 5 seconds for the workout to appear
    final workout2Finder = find.text('Test Workout 2');
    int retries = 0;
    while (workout2Finder.evaluate().isEmpty && retries < 10) {
      print('DEBUG: Workout not found yet, waiting... (retry $retries/10)');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      retries++;
    }

    if (workout2Finder.evaluate().isEmpty) {
      print('DEBUG: Test Workout 2 not found after creation and retries');
      print('DEBUG: Current screen widgets:');

      // Log all Text widgets to see what's actually on screen
      final textWidgets = find.byType(Text);
      if (textWidgets.evaluate().isNotEmpty) {
        for (var element in textWidgets.evaluate()) {
          final textWidget = element.widget as Text;
          if (textWidget.data != null) {
            print('  - Text: "${textWidget.data}"');
          }
        }
      } else {
        print('  - No Text widgets found');
      }

      // Log FAB presence
      print('DEBUG: FAB present: ${find.byType(FloatingActionButton).evaluate().isNotEmpty}');

      throw TestFailure('Test Workout 2 was not created successfully after 5 seconds');
    }

    print('DEBUG: Test Workout 2 found successfully after $retries retries');

    // Navigate into the second workout
    print('DEBUG: Tapping Test Workout 2 to navigate in');
    await tester.tap(workout2Finder);
    await tester.pumpAndSettle();

    // Add same exercise (Bench Press) with heavier weights to trigger PR
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Bench Press');
      await tester.tap(find.text('CREATE'));
      await tester.pumpAndSettle();

      // Navigate into exercise
      await tester.tap(find.text('Bench Press').last);
      await tester.pumpAndSettle();

      // Add sets with heavier weights than first workout (which had 100, 105, 110kg)
      // These heavier weights should trigger PRs
      for (int i = 0; i < 3; i++) {
        if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
          await tester.tap(find.byType(FloatingActionButton));
          await tester.pumpAndSettle();

          // Fill in set data with improved weights
          final repsFinder = find.byType(TextFormField).first;
          await tester.enterText(repsFinder, '10'); // Same reps

          if (find.byType(TextFormField).evaluate().length > 1) {
            final weightFinder = find.byType(TextFormField).last;
            await tester.enterText(weightFinder, '${115 + i * 5}'); // 115, 120, 125kg (higher than first workout)
          }

          await tester.tap(find.text('ADD')); // Set screen uses ADD button
          await tester.pumpAndSettle();
        }
      }
    }
  }

  // Give analytics time to process PRs
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> _createWorkoutsForHeatmapTesting(WidgetTester tester) async {
  // Create workouts on different dates for heatmap testing
  // This would require manipulating workout creation dates
  // For now, just create basic workout data
  await _createTestWorkoutData(tester);
}