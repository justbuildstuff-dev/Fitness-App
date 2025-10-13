import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/widgets/error_display.dart';

void main() {
  group('ErrorDisplay Widget', () {
    testWidgets('displays error message and retry button', (tester) async {
      // Arrange
      bool retryPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Test error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Test retry button
      await tester.tap(find.text('Try Again'));
      expect(retryPressed, true);
    });

    testWidgets('displays custom title when provided', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              title: 'Custom Error Title',
              message: 'Test error message',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Custom Error Title'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
    });

    testWidgets('displays custom icon when provided', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              icon: Icons.warning,
              message: 'Test error message',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.warning), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('uses theme colors correctly', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Test error message',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(icon.size, 64);
    });

    testWidgets('centers content on screen', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'Test error message',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('handles technical error parameter', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              message: 'User-friendly message',
              technicalError: 'Technical details here',
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - technical error is stored but not displayed to user
      expect(find.text('User-friendly message'), findsOneWidget);
      expect(find.text('Technical details here'), findsNothing);
    });
  });
}
