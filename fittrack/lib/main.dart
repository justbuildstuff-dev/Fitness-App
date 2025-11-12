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

  // Initialize Firebase with timeout to prevent indefinite hangs
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timed out after 10 seconds. Check your internet connection and Firebase configuration.');
      },
    );
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
          create: (_) {
            debugPrint('[Provider] Creating initial ProgramProvider with null userId');
            return ProgramProvider(null);
          },
          update: (_, authProvider, previousProgramProvider) {
            final userId = authProvider.user?.uid;
            debugPrint('[Provider] Updating ProgramProvider with userId: ${userId ?? 'null'}');
            return ProgramProvider(userId);
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