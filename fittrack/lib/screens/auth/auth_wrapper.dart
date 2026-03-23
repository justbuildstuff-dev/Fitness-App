import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import 'sign_in_screen.dart';
import 'email_verification_screen.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_carousel_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show appropriate screen based on authentication state
        if (authProvider.isAuthenticated) {
          // Check email verification
          if (!authProvider.isEmailVerified) {
            return const EmailVerificationScreen();
          }
          // Route new users to onboarding before HomeScreen
          if (!OnboardingService.instance.hasCompletedOnboarding) {
            return const OnboardingCarouselScreen();
          }
          return const HomeScreen();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}
