import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fittrack/screens/home/home_screen.dart';
import 'package:fittrack/screens/programs/programs_screen.dart';
import 'package:fittrack/screens/analytics/analytics_screen.dart';
import 'package:fittrack/screens/profile/profile_screen.dart';
import 'package:fittrack/providers/auth_provider.dart';
import 'package:fittrack/providers/program_provider.dart';

void main() {
  group('HomeScreen', () {
    late MockFirebaseAuth mockAuth;
    late FakeFirebaseFirestore mockFirestore;
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser(
        isAnonymous: false,
        uid: 'test-user-id',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      mockFirestore = FakeFirebaseFirestore();
    });

    Widget createTestWidget({int? initialIndex}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(mockAuth),
          ),
          ChangeNotifierProvider(
            create: (_) => ProgramProvider(mockFirestore, 'test-user-id'),
          ),
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

      // Assert - Programs screen should be visible
      expect(find.byType(ProgramsScreen), findsOneWidget);
      expect(find.byType(AnalyticsScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsNothing);
    });

    testWidgets('displays Programs screen when initialIndex is 0', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 0));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProgramsScreen), findsOneWidget);

      // Verify bottom nav highlights Programs
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });

    testWidgets('displays Analytics screen when initialIndex is 1', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 1));
      await tester.pumpAndSettle();

      // Assert - AnalyticsScreen should be visible (via IndexedStack)
      // Note: IndexedStack keeps all children in widget tree, so we check the index
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 1);
    });

    testWidgets('displays Profile screen when initialIndex is 2', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(initialIndex: 2));
      await tester.pumpAndSettle();

      // Assert - ProfileScreen should be visible (via IndexedStack)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 2);
    });

    testWidgets('has all three bottom navigation items', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('can switch between tabs using bottom navigation', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial state - Programs
      var bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);

      // Act - Tap Analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Assert - Analytics selected
      bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 1);

      // Act - Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert - Profile selected
      bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 2);
    });

    testWidgets('uses IndexedStack to maintain state across tab switches', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - IndexedStack should be present
      expect(find.byType(IndexedStack), findsOneWidget);

      // Verify all three screens are children of IndexedStack
      final indexedStack = tester.widget<IndexedStack>(
        find.byType(IndexedStack),
      );
      expect(indexedStack.children.length, 3);
    });

    testWidgets('backward compatible when initialIndex is not provided', (tester) async {
      // Act - Create HomeScreen without initialIndex parameter
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthProvider(mockAuth),
            ),
            ChangeNotifierProvider(
              create: (_) => ProgramProvider(mockFirestore, 'test-user-id'),
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(), // No initialIndex parameter
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should default to Programs screen (index 0)
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0);
    });
  });
}
