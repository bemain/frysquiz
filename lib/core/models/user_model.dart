enum UserRole { user, admin, superadmin }

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.groupIds,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> groupIds;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    List<String>? groupIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      groupIds: groupIds ?? this.groupIds,
    );
  }
}
