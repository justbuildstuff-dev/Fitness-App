import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Converter class for UserProfile model Firestore serialization/deserialization
class UserProfileConverter {
  /// Convert UserProfile to Firestore format
  static Map<String, dynamic> toFirestore(UserProfile profile) {
    return {
      'displayName': profile.displayName,
      'email': profile.email,
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'lastLogin': profile.lastLogin != null ? Timestamp.fromDate(profile.lastLogin!) : null,
      'settings': profile.settings,
    };
  }

  /// Create UserProfile from Firestore DocumentSnapshot
  static UserProfile fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null ? (data['lastLogin'] as Timestamp).toDate() : null,
      settings: data['settings'],
    );
  }
}