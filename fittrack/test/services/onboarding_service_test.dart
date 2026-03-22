import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/onboarding_service.dart';

/// Unit tests for OnboardingService.
///
/// Uses SharedPreferences.setMockInitialValues() to avoid Mockito generation
/// and test with a real in-memory SharedPreferences instance.
///
/// Verifies:
/// - hasCompletedOnboarding returns false when key is absent
/// - hasCompletedOnboarding returns true when key is true
/// - markComplete() writes the correct key and value
/// - resetOnboarding() removes the key
void main() {
  group('OnboardingService', () {
    setUp(() async {
      // Reset to empty prefs for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      OnboardingService.initialize(prefs);
    });

    group('hasCompletedOnboarding', () {
      test('returns false when key is absent', () async {
        /// First-time users have no stored value — onboarding should show
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        OnboardingService.initialize(prefs);

        expect(OnboardingService.instance.hasCompletedOnboarding, isFalse,
            reason: 'Should return false when key is absent');
      });

      test('returns false when key is explicitly false', () async {
        SharedPreferences.setMockInitialValues(
            {'fittrack_onboarding_complete': false});
        final prefs = await SharedPreferences.getInstance();
        OnboardingService.initialize(prefs);

        expect(OnboardingService.instance.hasCompletedOnboarding, isFalse,
            reason: 'Should return false when key is false');
      });

      test('returns true when key is true', () async {
        /// Returning users who completed onboarding should skip it
        SharedPreferences.setMockInitialValues(
            {'fittrack_onboarding_complete': true});
        final prefs = await SharedPreferences.getInstance();
        OnboardingService.initialize(prefs);

        expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
            reason: 'Should return true when key is true');
      });
    });

    group('markComplete', () {
      test('persists true to the correct key', () async {
        /// After marking complete, hasCompletedOnboarding must return true
        await OnboardingService.instance.markComplete();

        // Re-read from prefs to confirm persistence
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('fittrack_onboarding_complete'), isTrue,
            reason: 'markComplete should write true to fittrack_onboarding_complete');
      });

      test('hasCompletedOnboarding returns true after markComplete', () async {
        expect(OnboardingService.instance.hasCompletedOnboarding, isFalse);

        await OnboardingService.instance.markComplete();

        expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
            reason: 'Should return true immediately after markComplete');
      });
    });

    group('resetOnboarding', () {
      test('removes the key so hasCompletedOnboarding returns false', () async {
        /// Reset is used in tests and debug flows to re-trigger onboarding
        await OnboardingService.instance.markComplete();
        expect(OnboardingService.instance.hasCompletedOnboarding, isTrue);

        await OnboardingService.instance.resetOnboarding();

        expect(OnboardingService.instance.hasCompletedOnboarding, isFalse,
            reason: 'Should return false after resetOnboarding');
      });
    });

    group('singleton', () {
      test('instance getter returns the same object', () async {
        final first = OnboardingService.instance;
        final second = OnboardingService.instance;
        expect(identical(first, second), isTrue,
            reason: 'instance should always return the same object');
      });

      test('re-initialising replaces the instance', () async {
        SharedPreferences.setMockInitialValues(
            {'fittrack_onboarding_complete': true});
        final prefs2 = await SharedPreferences.getInstance();

        OnboardingService.initialize(prefs2);

        expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
            reason: 'New instance with different prefs should take effect');
      });
    });
  });
}
