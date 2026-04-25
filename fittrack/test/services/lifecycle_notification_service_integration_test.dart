/// Integration tests for LifecycleNotificationService.
///
/// LifecycleNotificationService uses SharedPreferences only for state
/// persistence (no Firebase Firestore required). These tests exercise the
/// real SharedPreferences lifecycle end-to-end — install date recording,
/// workout count accumulation, last-workout tracking, and the
/// permission-requested flag — across simulated app restarts.
///
/// FlutterLocalNotificationsPlugin and FirebaseMessaging (platform channels)
/// are mocked so tests run in CI without a device. The "integration" value
/// is the SharedPreferences persistence lifecycle.

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

import 'lifecycle_notification_service_integration_test.mocks.dart';

@GenerateMocks([FlutterLocalNotificationsPlugin, FirebaseMessaging])
void main() {
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockFirebaseMessaging mockMessaging;

  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  setUp(() {
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

  const installDateKey = 'overload_lifecycle_install_date';
  const lastWorkoutDateKey = 'overload_lifecycle_last_workout_date';
  const workoutCountKey = 'overload_lifecycle_workout_count';
  const permissionRequestedKey = 'overload_notif_permission_requested';

  group('LifecycleNotificationService - SharedPreferences lifecycle', () {
    test('install date is written on first construction and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      LifecycleNotificationService.forTest(prefs, mockNotifications, mockMessaging);

      // Re-initialise from same prefs instance (simulates app restart)
      final prefs2 = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs2, mockNotifications, mockMessaging);

      expect(s2.installDate, isNotNull,
          reason: 'Install date must survive re-initialisation');
      expect(prefs2.getString(installDateKey), isNotNull);
    });

    test('install date is not overwritten on subsequent constructions', () async {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      SharedPreferences.setMockInitialValues({installDateKey: yesterday});
      var prefs = await SharedPreferences.getInstance();
      final s1 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);
      final originalDate = s1.installDate;

      // Re-initialise
      prefs = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);

      expect(s2.installDate!.day, originalDate!.day,
          reason: 'Install date must not be overwritten');
    });

    test('workout count accumulates and persists across re-initialisation',
        () async {
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      final s1 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);
      s1.recordWorkoutLogged();
      s1.recordWorkoutLogged();
      s1.recordWorkoutLogged();

      // Re-initialise
      prefs = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);

      expect(s2.workoutCount, 3,
          reason: 'Workout count must survive app restart');
      expect(prefs.getInt(workoutCountKey), 3);
    });

    test('last workout date persists across re-initialisation', () async {
      SharedPreferences.setMockInitialValues({});
      var prefs = await SharedPreferences.getInstance();
      final s1 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);
      s1.recordWorkoutLogged();
      expect(s1.lastWorkoutDate, isNotNull);

      // Re-initialise
      prefs = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);

      expect(s2.lastWorkoutDate, isNotNull,
          reason: 'Last workout date must survive app restart');
      expect(prefs.getString(lastWorkoutDateKey), isNotNull);
    });

    test('permission-requested flag persists across re-initialisation',
        () async {
      SharedPreferences.setMockInitialValues(
          {workoutCountKey: 1});
      var prefs = await SharedPreferences.getInstance();
      final s1 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);
      await s1.requestPermissionIfEligible();
      expect(s1.permissionRequested, isTrue);

      // Re-initialise
      prefs = await SharedPreferences.getInstance();
      final s2 = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);

      expect(s2.permissionRequested, isTrue,
          reason: 'Permission flag must survive re-initialisation');
      expect(prefs.getBool(permissionRequestedKey), isTrue);
    });

    test('permission not re-requested after flag set in new session', () async {
      SharedPreferences.setMockInitialValues({
        workoutCountKey: 3,
        permissionRequestedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = LifecycleNotificationService.forTest(
          prefs, mockNotifications, mockMessaging);

      await s.requestPermissionIfEligible();

      verifyNever(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
      ));
    });
  });
}
