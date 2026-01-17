import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/program_provider.dart';
import '../programs/programs_screen.dart';
import '../analytics/analytics_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  /// The initial tab index to display when the screen is first shown.
  ///
  /// Defaults to 0 (Programs screen). Used by GlobalBottomNavBar to navigate
  /// to specific sections.
  ///
  /// Valid values: 0 (Programs), 1 (Analytics), 2 (Profile)
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Use initialIndex from widget, defaulting to 0 if not provided
    _currentIndex = widget.initialIndex;

    _screens = [
      const ProgramsScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];

    // No need to manually load programs - ProgramProvider auto-loads when userId is set
    // Removed manual loadPrograms() call to prevent race condition
  }

  @override
  Widget build(BuildContext context) {
    // HomeScreen acts as a container that displays one of the three main screens.
    // Each child screen (Programs, Analytics, Profile) has its own GlobalBottomNavBar
    // for navigation, so HomeScreen itself doesn't need a bottom nav.
    //
    // We use a simple conditional to show the current screen based on _currentIndex.
    // This is simpler than IndexedStack and avoids layout issues with nested Scaffolds.
    // State preservation isn't critical here since navigating between sections is rare
    // and each screen loads its own data from providers.
    Widget currentScreen;
    switch (_currentIndex) {
      case 0:
        currentScreen = _screens[0]; // ProgramsScreen
        break;
      case 1:
        currentScreen = _screens[1]; // AnalyticsScreen
        break;
      case 2:
        currentScreen = _screens[2]; // ProfileScreen
        break;
      default:
        currentScreen = _screens[0]; // Default to Programs
    }

    return currentScreen;
  }
}