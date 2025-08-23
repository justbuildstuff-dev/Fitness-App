import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? settings;

  UserProfile({
    required this.id,
    this.displayName,
    this.email,
    required this.createdAt,
    this.lastLogin,
    this.settings,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'],
      email: data['email'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : null,
      settings: data['settings'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'settings': settings,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    DateTime? lastLogin,
    Map<String, dynamic>? settings,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? this.settings,
    );
  }
}