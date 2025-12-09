/// Basic user information for ride context.
class UserBasic {
  const UserBasic({
    required this.id,
    required this.name,
    required this.phone,
  });

  final String id;
  final String name;
  final String phone;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
    };
  }

  factory UserBasic.fromMap(Map<String, dynamic> map) {
    return UserBasic(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
    );
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

