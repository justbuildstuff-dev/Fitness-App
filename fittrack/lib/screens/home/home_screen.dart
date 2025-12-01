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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
      ),
    );
  }
}