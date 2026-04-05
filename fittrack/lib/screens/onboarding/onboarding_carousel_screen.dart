import 'package:flutter/material.dart';
import '../../services/app_analytics_service.dart';
import '../../services/onboarding_service.dart';
import '../home/home_screen.dart';
import 'onboarding_wizard_screen.dart';

/// Value proposition carousel shown to new users before the wizard.
///
/// 4 pages highlighting app features. Users can:
/// - Swipe through pages
/// - Tap Skip (AppBar) on any page → wizard
/// - Tap "Next" on pages 1-3 → next page
/// - Tap "Set Up My First Program" on page 4 → wizard
/// - Tap "Skip to App" on page 4 → markComplete + HomeScreen
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key});

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _CarouselPageData(
      icon: Icons.account_tree_outlined,
      title: 'Structured Training',
      description:
          'Organise your training into Programs → Weeks → Workouts → Exercises. No more guessing what to do next.',
    ),
    _CarouselPageData(
      icon: Icons.checklist_rtl,
      title: 'Track Every Set',
      description:
          'Log reps, weight, duration, distance and rest time for every exercise type — strength, cardio, bodyweight and more.',
    ),
    _CarouselPageData(
      icon: Icons.insights,
      title: 'See Your Progress',
      description:
          'Your activity heatmap, personal records, and workout stats help you understand if your training is actually working.',
    ),
    _CarouselPageData(
      icon: Icons.rocket_launch_outlined,
      title: 'Start for Free',
      description:
          'Up to 3 programs, unlimited weeks and workouts, full set tracking, and basic analytics — no payment required.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    AppAnalyticsService.instance.logOnboardingStarted();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToWizard() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
    );
  }

  Future<void> _skipToApp() async {
    await OnboardingService.instance.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _navigateToWizard,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return _CarouselPage(data: _pages[index]);
              },
            ),
          ),
          // Dot indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Semantics(
                  label: 'Page ${index + 1} of ${_pages.length}',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.2),
                    ),
                  ),
                );
              }),
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isLastPage ? _navigateToWizard : _onNextPage,
                    child: Text(
                      isLastPage ? 'Set Up My First Program' : 'Next',
                    ),
                  ),
                ),
                if (isLastPage) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _skipToApp,
                    child: const Text('Skip to App'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _CarouselPageData {
  final IconData icon;
  final String title;
  final String description;

  const _CarouselPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}

// ─── Page widget ─────────────────────────────────────────────────────────────

class _CarouselPage extends StatelessWidget {
  final _CarouselPageData data;

  const _CarouselPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            data.icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
