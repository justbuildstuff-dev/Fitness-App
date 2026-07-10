import 'package:shared_preferences/shared_preferences.dart';

const bool _kSkipOnboarding = bool.fromEnvironment('SKIP_ONBOARDING', defaultValue: false);

/// Manages onboarding completion state via SharedPreferences.
///
/// Singleton initialized once in main.dart after SharedPreferences.getInstance().
/// Reads are synchronous (prefs is pre-loaded), making it safe to call in
/// StatelessWidget build methods such as AuthWrapper.
class OnboardingService {
  static const String _onboardingKey = 'fittrack_onboarding_complete';

  static OnboardingService? _instance;

  /// Access the singleton instance.
  /// Throws if [initialize] has not been called first.
  static OnboardingService get instance => _instance!;

  final SharedPreferences _prefs;

  OnboardingService._internal(this._prefs);

  /// Initialise the singleton. Must be called in main() after
  /// SharedPreferences.getInstance(), before runApp().
  static void initialize(SharedPreferences prefs) {
    _instance = OnboardingService._internal(prefs);
  }

  /// Returns true if the user has completed or skipped onboarding.
  bool get hasCompletedOnboarding =>
      _kSkipOnboarding || (_prefs.getBool(_onboardingKey) ?? false);

  /// Marks onboarding as complete. Persists to SharedPreferences.
  Future<void> markComplete() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  /// Resets onboarding state. Intended for testing and debug use only.
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingKey);
  }
}
