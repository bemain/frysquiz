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
