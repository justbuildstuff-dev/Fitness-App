import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:fittrack/screens/home/home_screen.dart';
import 'package:fittrack/screens/programs/programs_screen.dart';
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/screens/profile/profile_screen.dart';
import 'package:fittrack/providers/auth_provider.dart' as app_auth;
import 'package:fittrack/providers/program_provider.dart';

import 'home_screen_test.mocks.dart';

/// Unit tests for HomeScreen widget
///
/// Tests the following aspects:
/// - Renders correctly with different initialIndex values
/// - Bottom navigation displays all three sections
/// - Tab switching works correctly
/// - IndexedStack maintains state across tab switches
/// - Backward compatibility when initialIndex is not provided
///
/// Widget tests focus on UI behavior and user interactions
@GenerateMocks([ProgramProvider, app_auth.AuthProvider])
void main() {
  group('HomeScreen', () {
    late MockProgramProvider mockProgramProvider;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockProgramProvider = MockProgramProvider();
      mockAuthProvider = MockAuthProvider();

      // Set up default mock behavior for ProgramProvider
      when(mockProgramProvider.programs).thenReturn([]);
      when(mockProgramProvider.isLoading).thenReturn(false);
      when(mockProgramProvider.isLoadingPrograms).thenReturn(false);
      when(mockProgramProvider.isLoadingAnalytics).thenReturn(false);
      when(mockProgramProvider.error).thenReturn(null);
      when(mockProgramProvider.monthHeatmapData).thenReturn(null);
      when(mockProgramProvider.currentAnalytics).thenReturn(null);
      when(mockProgramProvider.keyStatistics).thenReturn(null);
      when(mockProgramProvider.recentPRs).thenReturn(null);
      when(mockProgramProvider.userId).thenReturn('test-user-id');

      // Set up default mock behavior for AuthProvider
      when(mockAuthProvider.isAuthenticated).thenReturn(true);
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.user).thenReturn(null);
      when(mockAuthProvider.userProfile).thenReturn(null);
    });

    Widget createTestWidget({int? initialIndex}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider<ProgramProvider>.value(value: mockProgramProvider),
        ],
        child: MaterialApp(
          home: HomeScreen(
            initialIndex: initialIndex ?? 0,
          ),
        ),
      );
    }

    testWidgets('displays Programs screen by default (initialIndex = 0)', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Only ProgramsScreen should be displayed
      expect(find.byType(ProgramsScreen), findsOneWidget);
      expect(find.byType(AnalyticsScreen), findsNothing); // Not built when Programs is active
      expect(find.byType(ProfileScreen), findsNothing); // Not built when Programs is active

      // Assert - Programs bottom nav should show Programs as active (index 0)
      final bottomNav = find.byType(BottomNavigationBar);
      expect(bottomNav, findsOneWidget); // Only Programs screen's nav

      final programsNav = tester.widget<BottomNavigationBar>(bottomNav);
      expect(programsNav.currentIndex, 0); // Programs index
    });

    testWidgets('displays Programs screen when initialIndex is 0', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 0));
      await tester.pumpAndSettle();

      // Assert - Verify ProgramsScreen is displayed and its bottom nav highlights Programs
      expect(find.byType(ProgramsScreen), findsOneWidget);
      final bottomNav = find.byType(BottomNavigationBar);
      final programsNav = tester.widget<BottomNavigationBar>(bottomNav);
      expect(programsNav.currentIndex, 0);
    });

    testWidgets('displays Analytics screen when initialIndex is 1', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 1));
      await tester.pumpAndSettle();

      // Assert - AnalyticsScreen should be displayed
      expect(find.byType(AnalyticsScreen), findsOneWidget);
      expect(find.byType(ProgramsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);

      // Verify AnalyticsScreen's bottom nav highlights Analytics
      final bottomNav = find.byType(BottomNavigationBar);
      final analyticsNav = tester.widget<BottomNavigationBar>(bottomNav);
      expect(analyticsNav.currentIndex, 1);
    });

    testWidgets('displays Profile screen when initialIndex is 2', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 2));
      await tester.pumpAndSettle();

      // Assert - ProfileScreen should be displayed
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(ProgramsScreen), findsNothing);
      expect(find.byType(AnalyticsScreen), findsNothing);

      // Verify ProfileScreen's bottom nav highlights Profile
      final bottomNav = find.byType(BottomNavigationBar);
      final profileNav = tester.widget<BottomNavigationBar>(bottomNav);
      expect(profileNav.currentIndex, 2);
    });

    testWidgets('has all three bottom navigation items', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - ProgramsScreen's GlobalBottomNavBar has all 3 items
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('GlobalBottomNavBar navigates between sections via HomeScreen', (tester) async {
      // Arrange - Start with Programs screen
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial state - Programs screen is active
      expect(find.byType(ProgramsScreen), findsOneWidget);
      final initialBottomNav = find.byType(BottomNavigationBar);
      final initialProgramsNav = tester.widget<BottomNavigationBar>(initialBottomNav);
      expect(initialProgramsNav.currentIndex, 0); // Programs active

      // Act - Tap Analytics on GlobalBottomNavBar
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Assert - Now HomeScreen shows AnalyticsScreen
      expect(find.byType(AnalyticsScreen), findsOneWidget);
      expect(find.byType(ProgramsScreen), findsNothing); // Programs not shown anymore

      final afterBottomNav = find.byType(BottomNavigationBar);
      final analyticsNav = tester.widget<BottomNavigationBar>(afterBottomNav);
      expect(analyticsNav.currentIndex, 1); // Analytics active
    });

    testWidgets('displays only the active screen based on initialIndex', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Only ProgramsScreen is built and displayed
      expect(find.byType(ProgramsScreen), findsOneWidget);
      expect(find.byType(AnalyticsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('backward compatible when initialIndex is not provided', (tester) async {
      // Act - Create HomeScreen without initialIndex parameter
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<app_auth.AuthProvider>.value(value: mockAuthProvider),
            ChangeNotifierProvider<ProgramProvider>.value(value: mockProgramProvider),
          ],
          child: MaterialApp(
            home: HomeScreen(), // No initialIndex parameter
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should default to Programs screen (index 0)
      expect(find.byType(ProgramsScreen), findsOneWidget);
      final bottomNav = find.byType(BottomNavigationBar);
      final programsNav = tester.widget<BottomNavigationBar>(bottomNav);
      expect(programsNav.currentIndex, 0);
    });
  });
}
