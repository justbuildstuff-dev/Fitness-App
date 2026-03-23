import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../../services/onboarding_service.dart';

/// Placeholder for the onboarding carousel screen.
///
/// Full implementation with 4-screen value prop carousel is in task #416.
/// This stub allows AuthWrapper routing to compile and be tested before
/// the full carousel UI is built.
class OnboardingCarouselScreen extends StatelessWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to FitTrack'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await OnboardingService.instance.markComplete();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }
}
