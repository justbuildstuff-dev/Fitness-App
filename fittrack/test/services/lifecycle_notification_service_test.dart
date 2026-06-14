@Timeout(Duration(seconds: 30))
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/services/lifecycle_notification_service.dart';

import 'lifecycle_notification_service_test.mocks.dart';

@GenerateMocks([FirebaseMessaging])
void main() {
  late MockFirebaseMessaging mockMessaging;

  setUp(() async {
    mockMessaging = MockFirebaseMessaging();

    when(mockMessaging.requestPermission(
      alert: anyNamed('alert'),
      badge: anyNamed('badge'),
      sound: anyNamed('sound'),
    )).thenAnswer((_) async => const NotificationSettings(
          authorizationStatus: AuthorizationStatus.authorized,
          alert: AppleNotificationSetting.enabled,
          announcement: AppleNotificationSetting.notSupported,
          badge: AppleNotificationSetting.enabled,
          carPlay: AppleNotificationSetting.notSupported,
          criticalAlert: AppleNotificationSetting.notSupported,
          lockScreen: AppleNotificationSetting.enabled,
          notificationCenter: AppleNotificationSetting.enabled,
          showPreviews: AppleShowPreviewSetting.always,
          sound: AppleNotificationSetting.enabled,
          timeSensitive: AppleNotificationSetting.notSupported,
          providesAppNotificationSettings: AppleNotificationSetting.notSupported,
        ));
    when(mockMessaging.getToken()).thenAnswer((_) async => 'fake-fcm-token');
  });

  Future<LifecycleNotificationService> makeService({
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return LifecycleNotificationService.forTest(prefs, mockMessaging);
  }

  group('LifecycleNotificationService - install date', () {
    test('records install date on first construction', () async {
      final s = await makeService();
      expect(s.installDate, isNotNull);
    });

    test('does not overwrite existing install date', () async {
      final past =
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final s = await makeService(
          prefsValues: {'overload_lifecycle_install_date': past});
      expect(s.installDate!.day,
          DateTime.now().subtract(const Duration(days: 5)).day);
    });

    test('daysSinceInstall is 0 on day of install', () async {
      final s = await makeService();
      expect(s.daysSinceInstall, 0);
    });

    test('daysSinceInstall reflects stored past date', () async {
      final tenDaysAgo =
          DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
      final s = await makeService(
          prefsValues: {'overload_lifecycle_install_date': tenDaysAgo});
      expect(s.daysSinceInstall, 10);
    });
  });

  group('LifecycleNotificationService - workout recording', () {
    test('workout count starts at 0', () async {
      final s = await makeService();
      expect(s.workoutCount, 0);
    });

    test('recordWorkoutLogged increments count', () async {
      final s = await makeService();
      s.recordWorkoutLogged();
      expect(s.workoutCount, 1);
    });

    test('recordWorkoutLogged accumulates across calls', () async {
      final s = await makeService();
      s.recordWorkoutLogged();
      s.recordWorkoutLogged();
      s.recordWorkoutLogged();
      expect(s.workoutCount, 3);
    });

    test('recordWorkoutLogged sets lastWorkoutDate', () async {
      final s = await makeService();
      expect(s.lastWorkoutDate, isNull);
      s.recordWorkoutLogged();
      expect(s.lastWorkoutDate, isNotNull);
    });
  });

  group('LifecycleNotificationService - daysSinceLastWorkout', () {
    test('uses install date when no workout logged', () async {
      final fiveDaysAgo =
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final s = await makeService(
          prefsValues: {'overload_lifecycle_install_date': fiveDaysAgo});
      expect(s.daysSinceLastWorkout, 5);
    });

    test('uses lastWorkoutDate when workout was logged', () async {
      final twoDaysAgo =
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      final s = await makeService(prefsValues: {
        'overload_lifecycle_install_date':
            DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'overload_lifecycle_last_workout_date': twoDaysAgo,
        'overload_lifecycle_workout_count': 3,
      });
      expect(s.daysSinceLastWorkout, 2);
    });
  });

  group('LifecycleNotificationService - onAppLaunch analytics', () {
    test('does not throw on fresh install', () async {
      final s = await makeService();
      await expectLater(s.onAppLaunch(), completes);
    });

    test('does not throw with existing workout history', () async {
      final s = await makeService(prefsValues: {
        'overload_lifecycle_workout_count': 2,
        'overload_lifecycle_install_date': DateTime.now().toIso8601String(),
      });
      await expectLater(s.onAppLaunch(), completes);
    });
  });

  group('LifecycleNotificationService - retention session tracking', () {
    const d1Key = 'overload_analytics_d1_session_fired';
    const d7Key = 'overload_analytics_d7_session_fired';
    const d30Key = 'overload_analytics_d30_session_fired';

    test('sets d1 flag on first launch at day >= 1', () async {
      final oneDayAgo =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues(
          {'overload_lifecycle_install_date': oneDayAgo});
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(prefs, mockMessaging);
      await s.onAppLaunch();
      expect(prefs.getBool(d1Key), isTrue);
    });

    test('does not set d1 flag when install is today', () async {
      final s = await makeService();
      await s.onAppLaunch();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(d1Key), isNull);
    });

    test('d1 flag not re-set on subsequent launch', () async {
      final oneDayAgo =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({
        'overload_lifecycle_install_date': oneDayAgo,
        d1Key: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(prefs, mockMessaging);
      await s.onAppLaunch();
      expect(prefs.getBool(d1Key), isTrue);
    });

    test('sets d7 flag on launch at day >= 7', () async {
      final sevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      SharedPreferences.setMockInitialValues(
          {'overload_lifecycle_install_date': sevenDaysAgo});
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(prefs, mockMessaging);
      await s.onAppLaunch();
      expect(prefs.getBool(d7Key), isTrue);
    });

    test('sets d30 flag on launch at day >= 30', () async {
      final thirtyDaysAgo =
          DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      SharedPreferences.setMockInitialValues(
          {'overload_lifecycle_install_date': thirtyDaysAgo});
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(prefs, mockMessaging);
      await s.onAppLaunch();
      expect(prefs.getBool(d30Key), isTrue);
    });

    test('does not set d7 or d30 flags on day 1', () async {
      final oneDayAgo =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues(
          {'overload_lifecycle_install_date': oneDayAgo});
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(prefs, mockMessaging);
      await s.onAppLaunch();
      expect(prefs.getBool(d7Key), isNull);
      expect(prefs.getBool(d30Key), isNull);
    });
  });

  group('LifecycleNotificationService - activation analytics', () {
    test('recordWorkoutLogged increments count from 0 to 1', () async {
      final s = await makeService();
      expect(s.workoutCount, 0);
      s.recordWorkoutLogged();
      expect(s.workoutCount, 1);
    });

    test('recordWorkoutLogged accumulates to 5 for milestone', () async {
      final s = await makeService();
      for (var i = 0; i < 5; i++) {
        s.recordWorkoutLogged();
      }
      expect(s.workoutCount, 5);
    });

    test('daysSinceLastWorkout resets to 0 after recordWorkoutLogged', () async {
      final twoDaysAgo =
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
      final s = await makeService(prefsValues: {
        'overload_lifecycle_install_date':
            DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
        'overload_lifecycle_last_workout_date': twoDaysAgo,
        'overload_lifecycle_workout_count': 2,
      });
      expect(s.daysSinceLastWorkout, 2);
      s.recordWorkoutLogged();
      expect(s.daysSinceLastWorkout, 0);
    });
  });

  group('LifecycleNotificationService - permission request', () {
    test('requestPermissionIfEligible does nothing before first workout',
        () async {
      final s = await makeService();
      await s.requestPermissionIfEligible();
      verifyNever(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
      ));
      expect(s.permissionRequested, isFalse);
    });

    test('requestPermissionIfEligible fires after first workout', () async {
      final s = await makeService(
          prefsValues: {'overload_lifecycle_workout_count': 1});
      await s.requestPermissionIfEligible();
      verify(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
      )).called(1);
      expect(s.permissionRequested, isTrue);
    });

    test('requestPermissionIfEligible only fires once', () async {
      final s = await makeService(
          prefsValues: {'overload_lifecycle_workout_count': 5});
      await s.requestPermissionIfEligible();
      await s.requestPermissionIfEligible();
      verify(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
      )).called(1);
    });

    test('persists permission-requested flag', () async {
      final s = await makeService(
          prefsValues: {'overload_lifecycle_workout_count': 1});
      await s.requestPermissionIfEligible();
      expect(s.permissionRequested, isTrue);

      SharedPreferences.setMockInitialValues({
        'overload_lifecycle_workout_count': 1,
        'overload_notif_permission_requested': true,
      });
      final prefs2 = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(prefs2, mockMessaging);
      expect(s2.permissionRequested, isTrue,
          reason: 'Permission flag must survive re-initialisation');
    });
  });
}
