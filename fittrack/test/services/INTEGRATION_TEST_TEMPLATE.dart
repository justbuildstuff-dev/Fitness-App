/// TEMPLATE: Real Firebase Integration Test
///
/// **HOW TO USE THIS TEMPLATE:**
/// 1. Copy this file and rename to: `[feature_name]_integration_test.dart`
/// 2. Replace all [PLACEHOLDERS] with your actual values
/// 3. Delete this header comment block
/// 4. Implement your test cases
///
/// **IMPORTANT: This is for REAL integration tests that:**
/// - Connect to Firebase emulators (NOT mocks)
/// - Create real data in Firestore
/// - Validate actual Firebase operations
/// - Run on Ubuntu CI runner (use `localhost`, not `10.0.2.2`)
///
/// **Example filename:** `firestore_cascade_delete_integration_test.dart`
///
/// ---

@Timeout(Duration(seconds: 120))
library;

import 'package:test/test.dart';
import 'package:fittrack/services/firestore_service.dart'; // [REPLACE] with your service
import '../helpers/firebase_integration_test_helper.dart';

void main() {
  // Connect to Firebase emulators before any tests run
  setUpAll(() async {
    await FirebaseIntegrationTestHelper.initializeFirebaseEmulators();
  });

  // Clear Firestore data before each test for isolation
  setUp(() async {
    await FirebaseIntegrationTestHelper.clearFirestore();
  });

  // Sign out after each test for cleanup
  tearDown(() async {
    await FirebaseIntegrationTestHelper.signOut();
  });

  group('[FEATURE_NAME] - REAL Firebase Integration', () {
    // [REPLACE] Initialize your service and test variables
    late FirestoreService firestoreService;
    late String userId;

    setUp(() async {
      // Create test user with unique email
      final user = await FirebaseIntegrationTestHelper.createTestUser();
      userId = user.uid;

      // Initialize your service
      firestoreService = FirestoreService();
    });

    test('[DESCRIPTION] - validates actual Firebase behavior', () async {
      /// Test Purpose: [Describe what this test validates]
      /// Expected: [Describe expected outcome]

      // Step 1: Seed test data if needed
      final testData = await FirebaseIntegrationTestHelper.seedProgramHierarchy(
        userId: userId,
        weekCount: 2,        // [ADJUST] as needed
        workoutsPerWeek: 3,  // [ADJUST] as needed
      );

      // Step 2: Call the actual service method you're testing
      // [REPLACE] with your actual service call
      // final result = await firestoreService.yourMethod(
      //   userId: userId,
      //   programId: testData['programId']!,
      // );

      // Step 3: Assert against REAL Firebase data
      // [REPLACE] with your actual assertions
      // expect(result, equals(expectedValue));

      // Step 4: (Optional) Verify data was written to Firestore
      // final snapshot = await FirebaseFirestore.instance
      //     .collection('users')
      //     .doc(userId)
      //     .collection('programs')
      //     .doc(testData['programId'])
      //     .get();
      // expect(snapshot.exists, isTrue);
    });

    test('[DESCRIPTION] - handles error conditions correctly', () async {
      /// Test Purpose: [Describe error scenario being tested]
      /// Expected: [Describe expected error handling]

      // Test with invalid data or edge cases
      // [REPLACE] with your error test scenario
      expect(
        () async => await firestoreService.yourMethod(
          userId: userId,
          programId: 'non-existent-id',
        ),
        throwsA(isA<Exception>()),
        reason: 'Should throw exception for invalid input',
      );
    });

    // [ADD MORE TESTS] as needed for your feature
    // Each test should:
    // - Have a clear purpose documented
    // - Use REAL Firebase data
    // - Validate actual behavior
    // - Test both success and error cases
  });
}
