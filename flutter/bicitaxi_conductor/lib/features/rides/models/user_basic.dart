/// Firebase collection name for users.
/// Use this constant when integrating with Firestore.
const String kUsersCollection = 'users';

/// Basic user information for ride context.
/// 
/// This is a lightweight user reference used within Ride objects
/// and for quick display. Full user profiles are stored separately.
class UserBasic {
  const UserBasic({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  /// Converts to a map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  /// Creates from a map (e.g., from Firestore).
  factory UserBasic.fromMap(Map<String, dynamic> map) {
    return UserBasic(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
  }

  // MARK: - Firebase Helpers
  // TODO: These methods will be used when Firebase is integrated.

  /// Converts to Firestore document data.
  Map<String, dynamic> toFirestore() => toMap();

  /// Creates from Firestore document data.
  factory UserBasic.fromFirestore(Map<String, dynamic> data, {String? documentId}) {
    final map = Map<String, dynamic>.from(data);
    if (documentId != null) {
      map['id'] = documentId;
    }
    return UserBasic.fromMap(map);
  }

  UserBasic copyWith({
    String? id,
    String? name,
    String? phone,
  }) {
    return UserBasic(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}

