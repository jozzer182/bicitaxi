/// User model for Firebase Auth + Firestore integration.
/// This model represents the full user profile stored in Firestore.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
  });

  /// Firebase Auth UID
  final String uid;

  /// User email address
  final String email;

  /// Display name (can be null for new users)
  final String? displayName;

  /// Phone number with country code (e.g., +57 300 123 4567)
  final String? phoneNumber;

  /// Profile photo URL (Firebase Storage or provider URL)
  final String? photoUrl;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last login timestamp
  final DateTime? lastLoginAt;

  /// Whether email is verified
  final bool isEmailVerified;

  /// Converts to a map suitable for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastLoginAt': lastLoginAt?.millisecondsSinceEpoch,
      'isEmailVerified': isEmailVerified,
    };
  }

  /// Converts to a map for Firestore creation with server timestamps.
  /// Use this when creating a new user document.
  Map<String, dynamic> toFirestoreCreate() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      // Note: When Firebase is integrated, replace with:
      // 'createdAt': FieldValue.serverTimestamp(),
      // 'lastLoginAt': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
      'isEmailVerified': isEmailVerified,
    };
  }

  /// Creates an AppUser from a Firestore document map.
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastLoginAt'] as int)
          : null,
      isEmailVerified: map['isEmailVerified'] as bool? ?? false,
    );
  }

  /// Creates a copy of this user with the given fields replaced.
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
