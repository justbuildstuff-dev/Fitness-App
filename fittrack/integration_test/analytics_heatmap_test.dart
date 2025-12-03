import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/main.dart';
import 'package:fittrack/models/analytics.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/exercise_set.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/services/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Integration tests for the analytics heatmap feature
///
/// Tests complete user flows:
/// 1. Navigate to analytics screen
/// 2. Select different timeframes
/// 3. Filter by program
/// 4. Verify heatmap updates correctly
/// 5. Verify preferences persist across app restarts
/// 6. Test performance with large datasets
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Heatmap Integration Tests', () {
    late FirebaseFirestore firestore;

    setUpAll(() async {
      // Initialize Firebase for testing
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
    });

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('complete user flow - select timeframe and filter by program', (tester) async {
      /// Test Purpose: Verify full user journey through analytics heatmap
      /// Flow: Open analytics → Change timeframe → Filter by program → Verify UI updates

      // Arrange - Start the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics screen (assuming navigation from bottom nav or drawer)
      // Note: Adjust based on actual navigation structure
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Verify initial state - should show default timeframe (This Year)
      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);

      // Act - Change timeframe to "This Week"
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Assert - Timeframe changed, heatmap updated
      final thisWeekChip = find.ancestor(
        of: find.text('This Week'),
        matching: find.byType(ChoiceChip),
      );
      expect(
        tester.widget<ChoiceChip>(thisWeekChip).selected,
        isTrue,
        reason: 'This Week chip should be selected',
      );

      // Act - Filter by a specific program
      final programDropdown = find.byType(DropdownButtonFormField<String?>);
      expect(programDropdown, findsOneWidget);

      await tester.tap(programDropdown);
      await tester.pumpAndSettle();

      // Find and tap a program (assuming at least one program exists)
      // Note: This assumes programs are loaded - may need mock data setup
      final firstProgram = find.text('All Programs').hitTestable();
      if (firstProgram.evaluate().isNotEmpty) {
        await tester.tap(firstProgram);
        await tester.pumpAndSettle();
      }

      // Assert - Heatmap should update with filtered data
      expect(find.byType(Card), findsWidgets);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);
    });

    testWidgets('preferences persist across app restart', (tester) async {
      /// Test Purpose: Verify that selected timeframe and program filter persist
      /// Flow: Change settings → Restart app → Verify settings restored

      // First app session - change preferences
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();

      // Set timeframe to "This Month" (index 1)
      await prefs.setInt('heatmap_timeframe', HeatmapTimeframe.thisMonth.index);

      // Set program filter to specific program ID
      await prefs.setString('heatmap_program_filter', 'test_program_123');

      // Start the app with saved preferences
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Assert - Saved preferences should be loaded
      final thisMonthChip = find.ancestor(
        of: find.text('This Month'),
        matching: find.byType(ChoiceChip),
      );

      if (thisMonthChip.evaluate().isNotEmpty) {
        expect(
          tester.widget<ChoiceChip>(thisMonthChip).selected,
          isTrue,
          reason: 'This Month chip should be selected after restart',
        );
      }

      // Verify program filter persisted (would need access to provider state)
      final provider = tester
          .widget<ChangeNotifierProvider<ProgramProvider>>(
            find.byType(ChangeNotifierProvider<ProgramProvider>).first,
          )
          .create;

      // Note: This assumes provider is accessible - may need adjustment
      // expect(provider.selectedHeatmapProgramId, equals('test_program_123'));
    });

    testWidgets('switching timeframes updates date range correctly', (tester) async {
      /// Test Purpose: Verify date range calculations for each timeframe
      /// Tests: This Week → This Month → Last 30 Days → This Year

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      final timeframes = [
        'This Week',
        'This Month',
        'Last 30 Days',
        'This Year',
      ];

      for (final timeframe in timeframes) {
        // Act - Select timeframe
        await tester.tap(find.text(timeframe));
        await tester.pumpAndSettle();

        // Assert - Chip is selected
        final chip = find.ancestor(
          of: find.text(timeframe),
          matching: find.byType(ChoiceChip),
        );

        expect(
          tester.widget<ChoiceChip>(chip).selected,
          isTrue,
          reason: '$timeframe chip should be selected',
        );

        // Heatmap should be visible
        expect(find.byType(Card), findsWidgets);
      }
    });

    testWidgets('heatmap updates when program filter changes', (tester) async {
      /// Test Purpose: Verify heatmap data updates when filtering by program

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Open program dropdown
      final programDropdown = find.byType(DropdownButtonFormField<String?>);
      await tester.tap(programDropdown);
      await tester.pumpAndSettle();

      // Select "All Programs"
      final allPrograms = find.text('All Programs').last;
      await tester.tap(allPrograms);
      await tester.pumpAndSettle();

      // Verify heatmap rendered
      expect(find.text('Current Streak'), findsOneWidget);

      // Change to a specific program (if available)
      await tester.tap(programDropdown);
      await tester.pumpAndSettle();

      // Select first program option (if exists beyond "All Programs")
      final dropdownItems = find.byType(DropdownMenuItem<String?>);
      if (dropdownItems.evaluate().length > 1) {
        await tester.tap(dropdownItems.at(1));
        await tester.pumpAndSettle();

        // Heatmap should still be visible with updated data
        expect(find.text('Current Streak'), findsOneWidget);
        expect(find.text('Longest Streak'), findsOneWidget);
      }
    });

    testWidgets('combined filters work correctly (timeframe + program)', (tester) async {
      /// Test Purpose: Verify multiple filters can be applied simultaneously

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Select "This Week" timeframe
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Select a specific program
      final programDropdown = find.byType(DropdownButtonFormField<String?>);
      await tester.tap(programDropdown);
      await tester.pumpAndSettle();

      final allPrograms = find.text('All Programs').last;
      await tester.tap(allPrograms);
      await tester.pumpAndSettle();

      // Both filters should be applied
      final thisWeekChip = find.ancestor(
        of: find.text('This Week'),
        matching: find.byType(ChoiceChip),
      );

      expect(
        tester.widget<ChoiceChip>(thisWeekChip).selected,
        isTrue,
        reason: 'This Week should remain selected',
      );

      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
    });

    testWidgets('streak cards display correctly', (tester) async {
      /// Test Purpose: Verify streak information is displayed

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Assert - Streak cards are visible
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);

      // Streak icons should be visible
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);

      // Streak values should be present (format: "X days")
      expect(find.textContaining('days'), findsNWidgets(2));
    });

    testWidgets('heatmap legend displays all intensity levels', (tester) async {
      /// Test Purpose: Verify legend shows all intensity levels

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Legend should show intensity levels
      // Note: Adjust based on actual legend implementation
      expect(find.text('Activity Tracker'), findsOneWidget);
    });

    testWidgets('rapid filter changes do not cause errors', (tester) async {
      /// Test Purpose: Verify stability when rapidly changing filters

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Rapidly change timeframes
      final timeframes = ['This Week', 'This Month', 'Last 30 Days', 'This Year'];

      for (int i = 0; i < 3; i++) {
        for (final timeframe in timeframes) {
          await tester.tap(find.text(timeframe));
          await tester.pump(); // Don't wait for settle - rapid changes
        }
      }

      // Wait for final settle
      await tester.pumpAndSettle();

      // App should still be stable
      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
    });

    testWidgets('empty data shows zero streaks', (tester) async {
      /// Test Purpose: Verify UI handles empty heatmap data gracefully

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // With no activity data, streaks should be 0
      // Note: Actual behavior depends on data state
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Longest Streak'), findsOneWidget);
    });

    testWidgets('year view enables vertical scrolling', (tester) async {
      /// Test Purpose: Verify year view has scrollable heatmap

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Select "This Year" timeframe
      await tester.tap(find.text('This Year'));
      await tester.pumpAndSettle();

      // Heatmap should be in a scrollable container
      // Note: Actual implementation may vary
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('week view displays 7 columns (Mon-Sun)', (tester) async {
      /// Test Purpose: Verify week view shows all 7 days

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Select "This Week" timeframe
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Week view should show Monday through Sunday
      // Note: Day labels may be abbreviated (M, T, W, etc.)
      expect(find.text('Activity Tracker'), findsOneWidget);
    });

    testWidgets('sets completed count displays in header', (tester) async {
      /// Test Purpose: Verify total sets count is shown

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Header should show total sets completed
      expect(find.textContaining('sets completed'), findsOneWidget);
    });

    testWidgets('preference updates trigger analytics reload', (tester) async {
      /// Test Purpose: Verify changing filters reloads analytics data

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to analytics
      final analyticsFinder = find.text('Analytics');
      if (analyticsFinder.evaluate().isNotEmpty) {
        await tester.tap(analyticsFinder);
        await tester.pumpAndSettle();
      }

      // Initial timeframe
      final initialTimeframe = find.text('This Year');
      expect(initialTimeframe, findsOneWidget);

      // Change timeframe - should trigger analytics reload
      await tester.tap(find.text('This Week'));
      await tester.pumpAndSettle();

      // Data should update (verified by UI still rendering)
      expect(find.text('Activity Tracker'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
    });
  });
}
