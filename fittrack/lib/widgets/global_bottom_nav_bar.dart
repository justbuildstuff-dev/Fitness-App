import 'package:flutter/material.dart';
import '../models/navigation_section.dart';
import '../screens/home/home_screen.dart';

/// A reusable bottom navigation bar widget that provides consistent navigation
/// across all full-page screens in the app.
///
/// This widget handles navigation between the three main sections:
/// - Programs (Home)
/// - Analytics
/// - Profile (Settings)
///
/// When a navigation item is tapped, the entire navigation stack is cleared
/// and the user is taken to the HomeScreen with the selected section active.
/// This provides a clean navigation experience and prevents deep navigation
/// stacks from accumulating.
///
/// Example usage:
/// ```dart
/// Scaffold(
///   appBar: AppBar(title: Text('My Screen')),
///   body: // ... screen content,
///   bottomNavigationBar: GlobalBottomNavBar(
///     currentSection: NavigationSection.programs,
///   ),
/// )
/// ```
class GlobalBottomNavBar extends StatelessWidget {
  /// The current section that should be highlighted in the navigation bar
  final NavigationSection currentSection;

  const GlobalBottomNavBar({
    super.key,
    required this.currentSection,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentSection.index,
      onTap: (index) => _handleNavigation(context, NavigationSection.values[index]),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Programs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  /// Handles navigation when a bottom nav item is tapped.
  ///
  /// If the tapped section is already the current section, no action is taken.
  /// Otherwise, navigates to the HomeScreen with the selected section active,
  /// clearing the entire navigation stack.
  ///
  /// This uses [Navigator.pushAndRemoveUntil] with a predicate that always
  /// returns false, ensuring all previous routes are removed from the stack.
  void _handleNavigation(BuildContext context, NavigationSection section) {
    // Don't navigate if already in this section
    if (section == currentSection) return;

    // Navigate to HomeScreen with selected tab, clearing navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomeScreen(initialIndex: section.index),
      ),
      (route) => false, // Remove all previous routes
    );
  }
}
