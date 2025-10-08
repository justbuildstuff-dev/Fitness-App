import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Configure emulators in debug mode
  if (kDebugMode) {
    FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
  }

  // Enable Firestore offline persistence (spec requirement from Section 11)
  try {
    await FirestoreService.enableOfflinePersistence();
  } catch (e) {
    // Offline persistence may fail if already enabled
    debugPrint('Firestore offline persistence: $e');
  }

  // Initialize notifications
  await NotificationService.instance.initialize();

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