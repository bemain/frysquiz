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

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: UserRole.values.byName(json['role'] as String),
    groupIds: List<String>.from(json['group_ids'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'group_ids': groupIds,
  };

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
