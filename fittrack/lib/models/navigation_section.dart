/// Represents the main navigation sections in the app.
///
/// Used by [GlobalBottomNavBar] to determine which section is currently active
/// and to handle navigation between sections.
///
/// Each enum value has a built-in [index] property:
/// - [NavigationSection.programs.index] = 0
/// - [NavigationSection.analytics.index] = 1
/// - [NavigationSection.profile.index] = 2
enum NavigationSection {
  /// Programs section - includes Programs, Program Details, Weeks, and Workouts
  programs,

  /// Analytics section - workout analytics and statistics
  analytics,

  /// Profile section - user settings and preferences
  profile,
}
