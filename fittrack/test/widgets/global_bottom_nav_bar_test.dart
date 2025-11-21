import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/global_bottom_nav_bar.dart';
import 'package:fittrack/models/navigation_section.dart';
import 'package:fittrack/screens/home/home_screen.dart';

void main() {
  group('GlobalBottomNavBar Widget', () {
    testWidgets('displays all three navigation items', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.programs,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Programs'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.analytics), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('highlights Programs section when currentSection is programs', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.programs,
            ),
          ),
        ),
      );

      // Assert
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 0); // Programs index
    });

    testWidgets('highlights Analytics section when currentSection is analytics', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          ),
        ),
      );

      // Assert
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 1); // Analytics index
    });

    testWidgets('highlights Profile section when currentSection is profile', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.profile,
            ),
          ),
        ),
      );

      // Assert
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.currentIndex, 2); // Profile index
    });

    testWidgets('uses BottomNavigationBarType.fixed', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.programs,
            ),
          ),
        ),
      );

      // Assert
      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bottomNav.type, BottomNavigationBarType.fixed);
    });

    testWidgets('navigates to Analytics when Analytics tab is tapped from Programs', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Programs Screen')),
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.programs,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Assert - should navigate to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to Programs when Programs tab is tapped from Analytics', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Analytics Screen')),
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.analytics,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      // Assert - should navigate to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to Profile when Profile tab is tapped from Programs', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Programs Screen')),
            bottomNavigationBar: GlobalBottomNavBar(
              currentSection: NavigationSection.programs,
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Assert - should navigate to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('does not navigate when tapping current section', (tester) async {
      // Arrange
      int navigationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(child: Text('Programs Screen')),
                bottomNavigationBar: GlobalBottomNavBar(
                  currentSection: NavigationSection.programs,
                ),
              );
            },
          ),
          navigatorObservers: [
            _TestNavigatorObserver(() => navigationCount++),
          ],
        ),
      );

      // Act - tap the already active Programs tab
      await tester.tap(find.text('Programs'));
      await tester.pumpAndSettle();

      // Assert - no navigation should occur
      expect(navigationCount, 0);
    });

    testWidgets('clears navigation stack when navigating to different section', (tester) async {
      // Arrange - Start with a navigation stack
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: Text('Screen 1')),
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: Text('Screen 2')),
                          body: Center(child: Text('Deep Screen')),
                          bottomNavigationBar: GlobalBottomNavBar(
                            currentSection: NavigationSection.programs,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text('Go to Screen 2'),
                ),
              );
            },
          ),
        ),
      );

      // Navigate to create a stack
      await tester.tap(find.text('Go to Screen 2'));
      await tester.pumpAndSettle();
      expect(find.text('Deep Screen'), findsOneWidget);

      // Act - Tap Analytics to navigate
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Assert - Should be at HomeScreen, previous screens cleared
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Deep Screen'), findsNothing);
      expect(find.text('Screen 1'), findsNothing);
    });
  });

  group('NavigationSection Enum', () {
    test('programs has index 0', () {
      expect(NavigationSection.programs.index, 0);
    });

    test('analytics has index 1', () {
      expect(NavigationSection.analytics.index, 1);
    });

    test('profile has index 2', () {
      expect(NavigationSection.profile.index, 2);
    });

    test('all sections can be accessed via values', () {
      expect(NavigationSection.values.length, 3);
      expect(NavigationSection.values[0], NavigationSection.programs);
      expect(NavigationSection.values[1], NavigationSection.analytics);
      expect(NavigationSection.values[2], NavigationSection.profile);
    });
  });
}

/// Test observer to track navigation events
class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigation;

  _TestNavigatorObserver(this.onNavigation);

  @override
  void didPush(Route route, Route? previousRoute) {
    onNavigation();
  }
}
