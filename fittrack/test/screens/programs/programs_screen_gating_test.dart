import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/screens/programs/programs_screen.dart';
import 'package:fittrack/providers/program_provider.dart';
import 'package:fittrack/providers/subscription_provider.dart';
import 'package:fittrack/models/program.dart';
import 'package:fittrack/models/subscription.dart';

import 'programs_screen_gating_test.mocks.dart';

Program _makeProgram(String id) => Program(
      id: id,
      name: 'Program $id',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      userId: 'user1',
    );

@GenerateMocks([ProgramProvider])
void main() {
  late MockProgramProvider mockProgramProvider;
  late SubscriptionProvider sub;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    mockProgramProvider = MockProgramProvider();
    sub = SubscriptionProvider();

    when(mockProgramProvider.isLoadingPrograms).thenReturn(false);
    when(mockProgramProvider.error).thenReturn(null);
    when(mockProgramProvider.programs).thenReturn([]);
    when(mockProgramProvider.isLoading).thenReturn(false);
    when(mockProgramProvider.isLoadingAnalytics).thenReturn(false);
    when(mockProgramProvider.monthHeatmapData).thenReturn(null);
    when(mockProgramProvider.currentAnalytics).thenReturn(null);
    when(mockProgramProvider.keyStatistics).thenReturn(null);
    when(mockProgramProvider.recentPRs).thenReturn(null);
    when(mockProgramProvider.userId).thenReturn('user1');
    when(mockProgramProvider.selectedProgram).thenReturn(null);
  });

  tearDown(() {
    sub.dispose();
  });

  Widget buildSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProgramProvider>.value(value: mockProgramProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: sub),
      ],
      child: const MaterialApp(home: ProgramsScreen()),
    );
  }

  group('ProgramsScreen - FAB gating (free tier)', () {
    testWidgets('shows paywall when free user has reached program limit', (tester) async {
      final programs = List.generate(3, (i) => _makeProgram('p$i'));
      when(mockProgramProvider.programs).thenReturn(programs);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsOneWidget);
      expect(find.text('Unlock unlimited programs'), findsOneWidget);
    });

    testWidgets('paywall subtext shows free limit', (tester) async {
      final programs = List.generate(3, (i) => _makeProgram('p$i'));
      when(mockProgramProvider.programs).thenReturn(programs);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('free plan limit of 3 programs'),
        findsOneWidget,
      );
    });

    testWidgets('does not show paywall when free user is under the limit', (tester) async {
      final programs = List.generate(2, (i) => _makeProgram('p$i'));
      when(mockProgramProvider.programs).thenReturn(programs);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsNothing);
    });

    testWidgets('empty state create button also gates at limit', (tester) async {
      // programs is empty — shows the empty state with Create Program button
      when(mockProgramProvider.programs).thenReturn([]);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Empty state shows the Create Program button — but limit is 3 so no gate yet
      // (0 programs < 3 limit). Verify no paywall appears.
      await tester.tap(find.text('Create Program'));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsNothing);
    });
  });

  group('ProgramsScreen - FAB gating (pro tier)', () {
    setUp(() {
      sub.setSubscriptionInfoForTest(
        const SubscriptionInfo(
          tier: SubscriptionTier.pro,
          status: SubscriptionStatus.active,
        ),
      );
    });

    testWidgets('pro user with 3+ programs sees no paywall', (tester) async {
      final programs = List.generate(5, (i) => _makeProgram('p$i'));
      when(mockProgramProvider.programs).thenReturn(programs);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsNothing);
    });
  });

  group('ProgramsScreen - FAB gating (isProOverride)', () {
    testWidgets('override user with 3+ programs sees no paywall', (tester) async {
      sub.setProOverrideForTest(value: true);
      final programs = List.generate(4, (i) => _makeProgram('p$i'));
      when(mockProgramProvider.programs).thenReturn(programs);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Overload Pro'), findsNothing);
    });
  });
}
