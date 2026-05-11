class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isOpen,
    required this.memberIds,
    required this.adminIds,
  });

  final String id;
  final String name;
  final String description;
  final bool isOpen;
  final List<String> memberIds;
  final List<String> adminIds;

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    isOpen: json['is_open'] as bool,
    memberIds: List<String>.from(json['member_ids'] as List? ?? []),
    adminIds: List<String>.from(json['admin_ids'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'is_open': isOpen,
    'member_ids': memberIds,
    'admin_ids': adminIds,
  };

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isOpen,
    List<String>? memberIds,
    List<String>? adminIds,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
    );
  }
}
