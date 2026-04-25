@Timeout(Duration(seconds: 30))
library;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:fittrack/services/lifecycle_notification_service.dart';

import 'lifecycle_notification_service_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin, FirebaseMessaging])
void main() {
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockFirebaseMessaging mockMessaging;

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() async {
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    mockMessaging = MockFirebaseMessaging();

    when(mockNotifications.initialize(
      any,
      onDidReceiveNotificationResponse:
          anyNamed('onDidReceiveNotificationResponse'),
    )).thenAnswer((_) async => true);
    when(mockNotifications.cancel(any)).thenAnswer((_) async {});
    when(mockNotifications.show(any, any, any, any,
            payload: anyNamed('payload')))
        .thenAnswer((_) async {});
    when(mockNotifications.zonedSchedule(
      any, any, any, any, any,
      androidScheduleMode: anyNamed('androidScheduleMode'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async {});

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
        ));
    when(mockMessaging.getToken()).thenAnswer((_) async => 'fake-fcm-token');
  });

  Future<LifecycleNotificationService> makeService({
    Map<String, Object> prefsValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefsValues);
    final prefs = await SharedPreferences.getInstance();
    return LifecycleNotificationService.forTest(
        prefs, mockNotifications, mockMessaging);
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

    test('recordWorkoutLogged cancels day-1 and day-3 notifications', () async {
      final s = await makeService();
      s.recordWorkoutLogged();
      verify(mockNotifications.cancel(1001)).called(1);
      verify(mockNotifications.cancel(1002)).called(1);
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

  group('LifecycleNotificationService - onAppLaunch scheduling', () {
    test('schedules day-1 notification when install is today and no workouts',
        () async {
      final s = await makeService();
      await s.onAppLaunch();
      verify(mockNotifications.zonedSchedule(
        1001, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('schedules day-3 notification when install is today and no workouts',
        () async {
      final s = await makeService();
      await s.onAppLaunch();
      verify(mockNotifications.zonedSchedule(
        1002, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('cancels activation notifications when workouts > 0', () async {
      final s = await makeService(prefsValues: {
        'overload_lifecycle_workout_count': 2,
        'overload_lifecycle_install_date':
            DateTime.now().toIso8601String(),
      });
      await s.onAppLaunch();
      verify(mockNotifications.cancel(1001)).called(1);
      verify(mockNotifications.cancel(1002)).called(1);
      verifyNever(mockNotifications.zonedSchedule(
        1001, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      ));
    });

    test('schedules day-10 retention notification from install date', () async {
      final s = await makeService();
      await s.onAppLaunch();
      verify(mockNotifications.zonedSchedule(
        1003, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('schedules day-30 retention notification from install date', () async {
      final s = await makeService();
      await s.onAppLaunch();
      verify(mockNotifications.zonedSchedule(
        1004, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      )).called(1);
    });

    test('does not schedule day-10 when already past 10 days since last workout',
        () async {
      final elevenDaysAgo =
          DateTime.now().subtract(const Duration(days: 11)).toIso8601String();
      final s = await makeService(prefsValues: {
        'overload_lifecycle_install_date': elevenDaysAgo,
        'overload_lifecycle_last_workout_date': elevenDaysAgo,
        'overload_lifecycle_workout_count': 3,
      });
      await s.onAppLaunch();
      verifyNever(mockNotifications.zonedSchedule(
        1003, any, any, any, any,
        androidScheduleMode: anyNamed('androidScheduleMode'),
        payload: anyNamed('payload'),
      ));
    });
  });

  group('LifecycleNotificationService - PR notification', () {
    test('recordPRAchieved calls show with exercise name and value', () async {
      final s = await makeService();
      await s.recordPRAchieved('Bench Press', '100kg');
      verify(mockNotifications.show(
        argThat(greaterThanOrEqualTo(2000)),
        'New PR: Bench Press',
        argThat(contains('100kg')),
        any,
        payload: anyNamed('payload'),
      )).called(1);
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

      // Re-initialise from same prefs
      SharedPreferences.setMockInitialValues(
          {'overload_lifecycle_workout_count': 1,
           'overload_notif_permission_requested': true});
      final prefs2 = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs2, mockNotifications, mockMessaging);
      expect(s2.permissionRequested, isTrue,
          reason: 'Permission flag must survive re-initialisation');
    });
  });
}
