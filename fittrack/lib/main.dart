import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/program_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/auth_wrapper.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // CRITICAL: Configure emulators BEFORE Firebase.initializeApp()
  // Emulator configuration must happen before any Firebase connection is established
  // kDebugMode = true: Local dev (uses emulators)
  // kProfileMode = true: Integration tests via flutter drive (uses emulators)
  // kReleaseMode = true: Beta + Production builds (uses production Firebase)
  if (kDebugMode || kProfileMode) {
    try {
      // Use 10.0.2.2 for Android emulator (localhost alias on Android)
      FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
      debugPrint('✅ Firebase emulators configured (Auth: 10.0.2.2:9099, Firestore: 10.0.2.2:8080)');
    } catch (e) {
      // Emulator config can only be set once - ignore if already configured
      debugPrint('⚠️  Emulator configuration: $e');
    }
  }

  // Initialize Firebase with timeout to prevent indefinite hangs
  // Emulator configuration above ensures debug/profile builds connect to emulators
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out after 10 seconds. Check your internet connection and Firebase configuration.');
      },
    );

    if (kDebugMode || kProfileMode) {
      debugPrint('✅ Firebase initialized with emulator configuration');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Run app with error state - AuthProvider will handle the error gracefully
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

  runApp(FitTrackApp(prefs: prefs));
}

class FitTrackApp extends StatelessWidget {
  final SharedPreferences prefs;

  const FitTrackApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProxyProvider<app_auth.AuthProvider, ProgramProvider>(
          create: (_) => ProgramProvider(null),
          update: (_, authProvider, previousProgramProvider) =>
              ProgramProvider(authProvider.user?.uid),
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
                seedColor: const Color(0xFF2196F3),
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
                seedColor: const Color(0xFF2196F3),
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