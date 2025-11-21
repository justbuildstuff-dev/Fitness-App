/// Represents the main navigation sections in the app.
///
/// Used by [GlobalBottomNavBar] to determine which section is currently active
/// and to handle navigation between sections.
enum NavigationSection {
  /// Programs section - includes Programs, Program Details, Weeks, and Workouts
  programs(0),

  /// Analytics section - workout analytics and statistics
  analytics(1),

  /// Profile section - user settings and preferences
  profile(2);

  /// The index position in the bottom navigation bar
  final int index;

  const NavigationSection(this.index);
}
