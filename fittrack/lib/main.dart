import 'dart:async';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/program_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weight_unit_provider.dart';
import 'providers/exercise_library_provider.dart';
import 'providers/template_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with timeout to prevent indefinite hangs
  // Skip if already initialized (e.g., by integration tests)
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Firebase initialization timed out after 10 seconds. Check your internet connection and Firebase configuration.');
        },
      );

      // Disable Crashlytics in debug builds to keep the production dashboard clean
      if (kDebugMode) {
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      }

      // Pass all uncaught Flutter framework errors to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Pass all uncaught async/platform errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Run app with error state - AuthProvider will handle the error gracefully
    }
  } else {
    debugPrint('Firebase already initialized (likely by integration tests), skipping initialization');
  }

  // Enable Firestore offline persistence (spec requirement from Section 11)
  // Non-blocking: Run in background, don't wait for completion
  FirestoreService.enableOfflinePersistence().catchError((e) {
    // Offline persistence may fail if already enabled
    debugPrint('Firestore offline persistence: $e');
  });

  // Initialize notifications
  // Non-blocking: Run in background, don't wait for completion
  NotificationService.instance.initialize().catchError((e) {
    debugPrint('Notification service initialization: $e');
  });

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize onboarding state service (must be before runApp)
  OnboardingService.initialize(prefs);

  runZonedGuarded(
    () => runApp(FitTrackApp(prefs: prefs)),
    (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}

class FitTrackApp extends StatelessWidget {
  final SharedPreferences prefs;

  const FitTrackApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    // Initialize OnboardingService here so E2E tests that pump FitTrackApp
    // directly (bypassing main()) still get proper initialization.
    OnboardingService.initialize(prefs);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => WeightUnitProvider(prefs)),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, ProgramProvider>(
          create: (_) {
            debugPrint('[Provider] Creating initial ProgramProvider with null userId');
            return ProgramProvider(null);
          },
          update: (_, authProvider, previousProgramProvider) {
            final userId = authProvider.user?.uid;
            debugPrint('[Provider] Updating ProgramProvider with userId: ${userId ?? 'null'}');

            // CRITICAL: Always create new instance to ensure auto-load triggers
            // The provider constructor handles auto-loading data when userId is set
            // Reusing instances can cause stale subscriptions and failed load states
            return ProgramProvider(userId);
          },
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, ExerciseLibraryProvider>(
          create: (_) {
            debugPrint('[Provider] Creating initial ExerciseLibraryProvider with null userId');
            return ExerciseLibraryProvider(null);
          },
          update: (_, authProvider, previousProvider) {
            final userId = authProvider.user?.uid;
            debugPrint('[Provider] Updating ExerciseLibraryProvider with userId: ${userId ?? 'null'}');

            // Create new instance to ensure proper initialization with userId
            return ExerciseLibraryProvider(userId);
          },
        ),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, TemplateProvider>(
          create: (_) {
            debugPrint('[Provider] Creating initial TemplateProvider with null userId');
            return TemplateProvider(null);
          },
          update: (_, authProvider, previousProvider) {
            final userId = authProvider.user?.uid;
            debugPrint('[Provider] Updating TemplateProvider with userId: ${userId ?? 'null'}');

            // Create new instance to ensure proper initialization with userId
            // The provider constructor handles auto-loading data when userId is set
            return TemplateProvider(userId);
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FitTrack',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.currentThemeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: themeProvider.seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
              ),
            ),
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}