/// Integration tests for OnboardingService.
///
/// OnboardingService uses SharedPreferences only (no Firebase).
/// These tests use SharedPreferences.setMockInitialValues() to test
/// real read/write/remove cycles end-to-end without mocking the service
/// itself. Firebase emulators are not required as no Firestore operations
/// are performed by this service.
///
/// Tests validate the full lifecycle:
/// - Service initialization from real prefs
/// - Persistence of onboarding completion across re-initialization
/// - Reset clears persisted state

@Timeout(Duration(seconds: 30))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/onboarding_service.dart';

void main() {
  group('OnboardingService - Integration (SharedPreferences lifecycle)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      OnboardingService.initialize(prefs);
    });

    test('new user has not completed onboarding', () async {
      /// Validates the real default state: absent key → not complete
      expect(OnboardingService.instance.hasCompletedOnboarding, isFalse,
          reason: 'New users should see onboarding');
    });

    test('markComplete persists across re-initialization', () async {
      /// Validates that completion survives app restart (re-init from same prefs)
      await OnboardingService.instance.markComplete();

      // Re-initialize from the same prefs instance (simulates app restart
      // where prefs are pre-loaded and passed to initialize())
      final prefs = await SharedPreferences.getInstance();
      OnboardingService.initialize(prefs);

      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue,
          reason: 'Completed state should persist after re-initialization');
    });

    test('resetOnboarding clears persisted state', () async {
      /// Validates full reset: complete → reset → not complete
      await OnboardingService.instance.markComplete();
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue);

      await OnboardingService.instance.resetOnboarding();
      expect(OnboardingService.instance.hasCompletedOnboarding, isFalse,
          reason: 'State should be cleared after reset');
    });

    test('full onboarding lifecycle: new → complete → reset', () async {
      /// Validates the complete lifecycle in a single test
      // New user
      expect(OnboardingService.instance.hasCompletedOnboarding, isFalse);

      // User completes onboarding
      await OnboardingService.instance.markComplete();
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue);

      // Debug reset
      await OnboardingService.instance.resetOnboarding();
      expect(OnboardingService.instance.hasCompletedOnboarding, isFalse);

      // Complete again
      await OnboardingService.instance.markComplete();
      expect(OnboardingService.instance.hasCompletedOnboarding, isTrue);
    });
  });
}
