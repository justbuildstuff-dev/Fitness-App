import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:fittrack/services/app_analytics_service.dart';

import 'app_analytics_service_test.mocks.dart';

@GenerateMocks([FirebaseAnalytics])
void main() {
  group('AppAnalyticsService', () {
    late MockFirebaseAnalytics mockAnalytics;
    late AppAnalyticsService service;

    setUp(() {
      mockAnalytics = MockFirebaseAnalytics();
      service = AppAnalyticsService.withAnalytics(mockAnalytics);
      // Default: all log calls succeed
      when(mockAnalytics.logSignUp(signUpMethod: anyNamed('signUpMethod')))
          .thenAnswer((_) async {});
      when(mockAnalytics.logLogin(loginMethod: anyNamed('loginMethod')))
          .thenAnswer((_) async {});
      when(mockAnalytics.logEvent(
              name: anyNamed('name'),
              parameters: anyNamed('parameters')))
          .thenAnswer((_) async {});
      when(mockAnalytics.logTutorialComplete())
          .thenAnswer((_) async {});
    });

    test('logSignUp calls analytics.logSignUp with email method', () async {
      await service.logSignUp();
      verify(mockAnalytics.logSignUp(signUpMethod: 'email')).called(1);
    });

    test('logLogin calls analytics.logLogin with email method', () async {
      await service.logLogin();
      verify(mockAnalytics.logLogin(loginMethod: 'email')).called(1);
    });

    test('logSignOut fires sign_out event', () async {
      await service.logSignOut();
      verify(mockAnalytics.logEvent(name: 'sign_out')).called(1);
    });

    test('logOnboardingStarted fires onboarding_started event', () async {
      await service.logOnboardingStarted();
      verify(mockAnalytics.logEvent(name: 'onboarding_started')).called(1);
    });

    test('logOnboardingCompleted calls analytics.logTutorialComplete', () async {
      await service.logOnboardingCompleted();
      verify(mockAnalytics.logTutorialComplete()).called(1);
    });

    test('logProgramCreated fires program_created event', () async {
      await service.logProgramCreated();
      verify(mockAnalytics.logEvent(name: 'program_created')).called(1);
    });

    test('logWorkoutStarted fires workout_started event', () async {
      await service.logWorkoutStarted();
      verify(mockAnalytics.logEvent(name: 'workout_started')).called(1);
    });

    test('logSetCompleted fires set_completed event', () async {
      await service.logSetCompleted();
      verify(mockAnalytics.logEvent(name: 'set_completed')).called(1);
    });

    test('logReviewPromptTriggered fires review_prompt_triggered event', () async {
      await service.logReviewPromptTriggered();
      verify(mockAnalytics.logEvent(name: 'review_prompt_triggered')).called(1);
    });

    test('analytics failures are swallowed and do not throw', () async {
      when(mockAnalytics.logEvent(
              name: anyNamed('name'),
              parameters: anyNamed('parameters')))
          .thenThrow(Exception('network error'));

      // Should complete without throwing
      await expectLater(service.logProgramCreated(), completes);
      await expectLater(service.logWorkoutStarted(), completes);
      await expectLater(service.logSetCompleted(), completes);
    });
  });
}
