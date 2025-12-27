# Authentication Documentation

## Overview

The FitTrack authentication system is built on Firebase Authentication with custom user profile management in Firestore. The system provides secure user registration, sign-in, profile management, and session handling with comprehensive error handling and user feedback.

## Architecture Components

### Core Components
1. **AuthProvider** - State management for authentication
2. **AuthWrapper** - Route-level authentication guard  
3. **UserProfile** - Extended user data model
4. **Firebase Auth** - Core authentication service
5. **Firestore Integration** - User profile storage

### Authentication Flow
```
App Launch → AuthWrapper → Check Auth State → Route to Screen
                    ↓
            [Authenticated] → Check Email Verified
                    ↓                    ↓
            [Not Verified]        [Verified]
                    ↓                    ↓
         EmailVerificationScreen    HomeScreen
                    ↓
            [Unauthenticated] → SignInScreen
```

## AuthProvider (Core Authentication Manager)

### Responsibilities
- Firebase Authentication integration
- User session management  
- Profile data synchronization
- Password policy enforcement
- Error handling and user feedback
- Authentication state broadcasting

### State Management
```dart
class AuthProvider extends ChangeNotifier {
  User? _user;                    // Firebase Auth user
  UserProfile? _userProfile;      // Extended profile data
  bool _isLoading = false;       // Operation loading state
  String? _error;                // Current error message
  String? _successMessage;       // Success feedback
}
```

### Public Interface

#### Authentication Status
```dart
bool get isAuthenticated;      // True if user is signed in
bool get isEmailVerified;     // True if user's email is verified
User? get user;               // Current Firebase user
UserProfile? get userProfile; // Extended profile data
bool get isLoading;           // Loading state for UI
String? get error;            // Current error message
String? get successMessage;   // Success message
```

#### Authentication Operations
```dart
// User Registration
Future<bool> signUpWithEmail({
  required String email,
  required String password,
  String? displayName,
});

// User Sign-In
Future<void> signInWithEmail({
  required String email,
  required String password,
});

// Email Verification
Future<void> sendEmailVerification();  // Send verification email
Future<void> checkEmailVerified();     // Check verification status

// Sign Out
Future<void> signOut();

// Password Reset
Future<void> resetPassword(String email);

// Profile Updates
Future<void> updateProfile({
  String? displayName,
  Map<String, dynamic>? settings,
});
```

#### State Management
```dart
void clearError();            // Clear error state
void clearSuccessMessage();   // Clear success state
```

### Authentication State Lifecycle

#### Initialization
```dart
AuthProvider() {
  // Listen to Firebase Auth state changes
  _auth.authStateChanges().listen((User? user) {
    _user = user;
    if (user != null) {
      _loadUserProfile();
    } else {
      _userProfile = null;
    }
    notifyListeners();
  });
}
```

#### User Registration Flow
1. **Validation**: Password policy enforcement
2. **Firebase Registration**: Create auth account
3. **Profile Creation**: Create Firestore user profile document
4. **Display Name Update**: Update Firebase Auth display name
5. **Success Feedback**: Set success message for UI

```dart
Future<bool> signUpWithEmail({
  required String email,
  required String password,
  String? displayName,
}) async {
  try {
    _setLoading(true);
    _clearError();
    
    // Validate password policy
    if (!_isValidPassword(password)) {
      throw Exception('Password must be at least 8 characters with at least one letter and one number');
    }

    // Create Firebase Auth account
    final UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (result.user != null) {
      // Create Firestore profile document
      await _createUserProfile(result.user!, displayName);
      
      // Update Firebase Auth display name
      if (displayName != null && displayName.trim().isNotEmpty) {
        await result.user!.updateDisplayName(displayName.trim());
      }
      
      _setSuccessMessage('Account created successfully!');
      return true;
    }
    return false;
  } catch (e) {
    _setError(_getAuthErrorMessage(e));
    return false;
  } finally {
    _setLoading(false);
  }
}
```

#### Sign-In Flow
1. **Email/Password Authentication**: Firebase Auth sign-in
2. **Profile Loading**: Load extended user data from Firestore
3. **Last Login Update**: Update last login timestamp
4. **State Broadcasting**: Notify listeners of auth state change

```dart
Future<void> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    _setLoading(true);
    _clearError();

    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update last login time
    if (_user != null) {
      await _updateLastLogin();
    }
  } catch (e) {
    _setError(_getAuthErrorMessage(e));
  } finally {
    _setLoading(false);
  }
}
```

### Password Policy

Per technical specification requirements:

```dart
bool _isValidPassword(String password) {
  if (password.length < 8) return false;
  
  bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
  bool hasDigit = password.contains(RegExp(r'[0-9]'));
  
  return hasLetter && hasDigit;
}
```

**Requirements**:
- Minimum 8 characters
- At least one letter (a-z, A-Z)
- At least one digit (0-9)
- Client-side validation with user feedback
- Firebase Auth provides additional server-side validation

### Error Handling

#### Firebase Auth Error Mapping
```dart
String _getAuthErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
      return 'No user found with this email address.';
    case 'wrong-password':
      return 'Incorrect password.';
    case 'email-already-in-use':
      return 'An account already exists with this email address.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password is too weak. Please choose a stronger password.';
    case 'network-request-failed':
      return 'Network error. Please check your connection and try again.';
    case 'too-many-requests':
      return 'Too many failed attempts. Please try again later.';
    default:
      return e.message ?? 'An error occurred during authentication.';
  }
}
```

#### Error State Management
```dart
void _setError(String error) {
  _error = error;
  notifyListeners();
}

void _clearError() {
  _error = null;
}

// Public method for UI error clearing
void clearError() {
  _clearError();
  notifyListeners();
}
```

## UserProfile Model

### Purpose
Extended user data beyond Firebase Auth's basic user object, stored in Firestore for rich querying and offline access.

### Data Structure
```dart
class UserProfile {
  final String id;                      // Matches Firebase Auth UID
  final String? displayName;            // User's display name
  final String? email;                  // User's email address
  final DateTime createdAt;             // Account creation timestamp
  final DateTime? lastLogin;            // Last login timestamp
  final Map<String, dynamic>? settings; // App-specific settings
}
```

### Default Settings Structure
```dart
// Default settings on user creation
{
  'unitPreference': 'metric',    // 'metric' or 'imperial'
  'theme': 'system',            // 'light', 'dark', 'system'
  'notifications': {
    'workoutReminders': true,
    'progressUpdates': false,
  },
  'privacy': {
    'dataSharing': false,
    'analytics': true,
  }
}
```

### Profile Management
```dart
// Creating user profile during registration
Future<void> _createUserProfile(User user, String? displayName) async {
  final userProfile = UserProfile(
    id: user.uid,
    displayName: displayName?.trim() ?? user.displayName,
    email: user.email,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
    settings: {
      'unitPreference': 'metric',
      'theme': 'system',
    },
  );

  await _firestore
      .collection('users')
      .doc(user.uid)
      .set(userProfile.toFirestore());
}
```

## Email Verification

### Purpose
Ensures users verify their email addresses before accessing the app, preventing spam accounts and confirming email ownership.

### Email Verification Screen

#### Features
- **Auto-Check Timer**: Checks verification status every 3 seconds
- **Resend Email**: 60-second cooldown to prevent spam
- **Sign Out Option**: Allows switching to different account
- **User Feedback**: Success/error messages for operations
- **Spam Folder Tip**: Helpful reminder to check spam folder

#### Implementation
```dart
class EmailVerificationScreen extends StatefulWidget {
  // Auto-check timer runs every 3 seconds
  Timer.periodic(const Duration(seconds: 3), (timer) {
    if (mounted) {
      authProvider.checkEmailVerified();
    }
  });

  // Resend email with cooldown
  Future<void> _resendVerificationEmail() async {
    await authProvider.sendEmailVerification();
    setState(() {
      _canResend = false;
      _resendCooldown = 60;
    });
  }
}
```

#### User Experience
- Screen displays immediately after registration
- Automatically refreshes when email is verified
- Clear instructions and email address display
- Visual feedback for all operations
- Accessible sign-out option

### Email Verification Flow

```dart
// After successful registration
Future<bool> signUpWithEmail({...}) async {
  final result = await _auth.createUserWithEmailAndPassword(...);

  if (result.user != null) {
    await _createUserProfile(result.user!, displayName);

    // Send verification email automatically
    await result.user!.sendEmailVerification();

    return true;
  }
}

// Check verification status (called by auto-check timer)
Future<void> checkEmailVerified() async {
  await _user?.reload();
  final verified = _user?.emailVerified ?? false;

  if (verified != (_emailVerified ?? false)) {
    _emailVerified = verified;
    notifyListeners();
  }
}

// Manual resend
Future<void> sendEmailVerification() async {
  try {
    await _user?.sendEmailVerification();
    _setSuccessMessage('Verification email sent! Please check your inbox.');
  } catch (e) {
    _setError('Failed to send verification email: ${e.toString()}');
  }
}
```

### Timer Management
```dart
// Auto-check timer
Timer? _verificationCheckTimer;

@override
void initState() {
  super.initState();

  // Start auto-check timer
  _verificationCheckTimer = Timer.periodic(
    const Duration(seconds: 3),
    (timer) {
      if (mounted) {
        context.read<AuthProvider>().checkEmailVerified();
      }
    },
  );
}

@override
void dispose() {
  // Critical: Cancel timer to prevent memory leak
  _verificationCheckTimer?.cancel();
  super.dispose();
}
```

## AuthWrapper (Route Guard)

### Purpose
Centralized authentication routing that determines which screen to display based on authentication and verification state.

### Implementation
```dart
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Loading state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Route based on authentication state
        if (authProvider.isAuthenticated) {
          // Check email verification
          if (!authProvider.isEmailVerified) {
            return const EmailVerificationScreen();
          }
          return const HomeScreen();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}
```

### Usage in App Structure
```dart
// main.dart
MaterialApp(
  home: const AuthWrapper(),  // Root level authentication routing
  // ... other app configuration
)
```

### State Handling
- **Loading**: Shows loading indicator during auth state checks
- **Authenticated + Verified**: Routes to HomeScreen (main app)
- **Authenticated + Unverified**: Routes to EmailVerificationScreen
- **Unauthenticated**: Routes to SignInScreen (login flow)
- **Automatic Updates**: Rebuilds when authentication or verification state changes

## Firebase Configuration

### Emulator Setup (Development)
```dart
// main.dart
if (kDebugMode) {
  FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
}
```

### Production Configuration
- Firebase project configuration in `firebase_options.dart`
- Platform-specific configuration (iOS, Android, Web)
- Security rules deployment for user profile protection

## Security Considerations

### Authentication Security
- **Firebase Auth Tokens**: Automatic token management and refresh
- **Secure Transmission**: HTTPS for all authentication requests  
- **Password Hashing**: Handled by Firebase Auth
- **Session Management**: Automatic session handling and expiration

### User Profile Security
- **Firestore Rules**: User can only access own profile document
- **Admin Access**: Custom claims for support operations
- **Data Validation**: Server-side validation in Firestore rules

### Security Rules for User Profiles
```javascript
// firestore.rules
match /users/{userId} {
  // User can read/write own profile
  allow read, write: if request.auth != null 
                     && request.auth.uid == userId;
  
  // Admin access for support
  allow read: if request.auth != null 
              && request.auth.token.admin == true;
}
```

## UI Integration Patterns

### Consumer Pattern
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    if (authProvider.error != null) {
      return ErrorBanner(
        message: authProvider.error!,
        onDismiss: () => authProvider.clearError(),
      );
    }
    
    if (authProvider.successMessage != null) {
      return SuccessBanner(
        message: authProvider.successMessage!,
        onDismiss: () => authProvider.clearSuccessMessage(),
      );
    }
    
    return AuthenticatedContent();
  },
)
```

### Loading States
```dart
// In sign-in form
ElevatedButton(
  onPressed: authProvider.isLoading 
      ? null 
      : () => _handleSignIn(),
  child: authProvider.isLoading
      ? CircularProgressIndicator()
      : Text('Sign In'),
)
```

### Form Integration
```dart
void _handleSignIn() async {
  final authProvider = context.read<AuthProvider>();
  
  await authProvider.signInWithEmail(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  // Error handling is automatic via Consumer
  // Success navigation handled by AuthWrapper
}
```

## Testing Strategies

### AuthProvider Testing
```dart
group('AuthProvider', () {
  late AuthProvider provider;
  late MockFirebaseAuth mockAuth;
  late MockFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirestore();
    provider = AuthProvider();
    provider._auth = mockAuth;
    provider._firestore = mockFirestore;
  });

  test('signs in user successfully', () async {
    // Arrange
    when(mockAuth.signInWithEmailAndPassword(any, any))
        .thenAnswer((_) async => MockUserCredential());

    // Act
    await provider.signInWithEmail(
      email: 'test@example.com',
      password: 'password123',
    );

    // Assert
    expect(provider.error, isNull);
    expect(provider.isLoading, isFalse);
  });

  test('handles authentication errors', () async {
    // Arrange
    when(mockAuth.signInWithEmailAndPassword(any, any))
        .thenThrow(FirebaseAuthException(code: 'wrong-password'));

    // Act
    await provider.signInWithEmail(
      email: 'test@example.com',
      password: 'wrongpassword',
    );

    // Assert
    expect(provider.error, equals('Incorrect password.'));
    expect(provider.isLoading, isFalse);
  });
});
```

### Widget Testing
```dart
testWidgets('AuthWrapper shows login when unauthenticated', (tester) async {
  final mockProvider = MockAuthProvider();
  when(mockProvider.isAuthenticated).thenReturn(false);
  when(mockProvider.isLoading).thenReturn(false);

  await tester.pumpWidget(
    ChangeNotifierProvider<AuthProvider>.value(
      value: mockProvider,
      child: MaterialApp(home: AuthWrapper()),
    ),
  );

  expect(find.byType(SignInScreen), findsOneWidget);
});
```

### Integration Testing
```dart
testWidgets('complete authentication flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Should show login screen initially
  expect(find.byType(SignInScreen), findsOneWidget);
  
  // Enter credentials
  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  
  // Tap sign in
  await tester.tap(find.byKey(Key('sign_in_button')));
  await tester.pumpAndSettle();
  
  // Should navigate to home screen
  expect(find.byType(HomeScreen), findsOneWidget);
});
```

## Best Practices

### Error Handling
1. **User-Friendly Messages**: Map technical errors to readable messages
2. **Loading States**: Prevent duplicate operations during loading
3. **Retry Mechanisms**: Allow users to retry failed operations
4. **Offline Handling**: Graceful behavior when network is unavailable

### Security
1. **Input Validation**: Validate email format and password strength
2. **Secure Storage**: Use Firebase Auth for token management
3. **Session Management**: Handle automatic token refresh
4. **Profile Protection**: Restrict profile access to owner only

### User Experience
1. **Loading Feedback**: Show progress during auth operations
2. **Clear Error Messages**: Provide actionable error information
3. **Success Confirmation**: Confirm successful registration/login
4. **Remember State**: Persist authentication across app restarts

### State Management
1. **Centralized Auth State**: Single source of truth in AuthProvider
2. **Automatic Updates**: UI updates automatically on auth state changes
3. **Cleanup**: Proper disposal of listeners and subscriptions
4. **Error Recovery**: Clear error states after user actions

## Extension Guidelines

### Adding New Auth Methods
1. Add method to AuthProvider
2. Implement Firebase Auth integration
3. Handle method-specific errors
4. Add UI components for new method
5. Update AuthWrapper routing if needed
6. Add comprehensive tests

### Profile Extensions
1. Update UserProfile model with new fields
2. Add validation logic
3. Update Firestore security rules
4. Create migration strategy for existing users
5. Add profile management UI

### Admin Features
1. Implement custom claims in Firebase Auth
2. Update Firestore rules for admin access
3. Add admin role management
4. Create admin-specific UI components
5. Add audit logging for admin actions

This authentication system provides a secure, user-friendly foundation for the FitTrack application with comprehensive error handling, state management, and extensibility for future enhancements.