import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../converters/user_profile_converter.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  StreamSubscription<User?>? _authStateSubscription;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Listen to auth state changes
    _authStateSubscription = _auth.authStateChanges().listen((User? user) {
      debugPrint('[AuthProvider] Auth state changed - userId: ${user?.uid ?? 'null'}');
      _user = user;
      if (user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      _clearSuccessMessage();

      // Validate password policy
      if (!_isValidPassword(password)) {
        throw Exception('Password must be at least 8 characters with at least one letter and one number');
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        // Create user profile document
        await _createUserProfile(result.user!, displayName);
        
        // Update display name if provided
        if (displayName != null && displayName.trim().isNotEmpty) {
          await result.user!.updateDisplayName(displayName.trim());
        }
        
        // Set success message
        _setSuccessMessage('Account created successfully! Please sign in with your new credentials.');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

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
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      
      await _auth.signOut();
      _userProfile = null;
    } catch (e) {
      _setError('Failed to sign out: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    Map<String, dynamic>? settings,
  }) async {
    if (_user == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Update Firebase Auth display name
      if (displayName != null && displayName.trim() != _user!.displayName) {
        await _user!.updateDisplayName(displayName.trim());
      }

      // Update Firestore profile
      final updates = <String, dynamic>{};
      if (displayName != null) updates['displayName'] = displayName.trim();
      if (settings != null) updates['settings'] = settings;
      
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .update(updates);
            
        await _loadUserProfile(); // Refresh profile
      }
    } catch (e) {
      _setError('Failed to update profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

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
        .set(UserProfileConverter.toFirestore(userProfile));
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(_user!.uid)
          .get();

      if (doc.exists) {
        _userProfile = UserProfile.fromFirestore(doc);
      } else {
        // Create profile if it doesn't exist
        await _createUserProfile(_user!, _user!.displayName);
        await _loadUserProfile();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _updateLastLogin() async {
    if (_user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    
    return hasLetter && hasDigit;
  }

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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setSuccessMessage(String message) {
    _successMessage = message;
    notifyListeners();
  }

  void _clearSuccessMessage() {
    _successMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearSuccessMessage() {
    _clearSuccessMessage();
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}