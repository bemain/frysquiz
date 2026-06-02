import '../core/models/group_model.dart';
import '../core/services/group_service.dart';
import 'mock_data.dart';

class MockGroupService implements GroupService {
  final List<GroupModel> _groups = List.from(MockData.groups);

  @override
  Future<List<GroupModel>> getAllGroups() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_groups);
  }

  @override
  Future<List<GroupModel>> getGroupsForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _groups.where((g) => g.memberIds.contains(userId)).toList();
  }

  @override
  Future<GroupModel?> getGroupById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _groups.firstWhere((g) => g.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required bool isOpen,
    required String creatorId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final group = GroupModel(
      id: 'g${_groups.length + 1}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      isOpen: isOpen,
      memberIds: [creatorId],
      adminIds: [creatorId],
    );
    _groups.add(group);
    return group;
  }

  @override
  Future<GroupModel> addMember(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw StateError('Group not found: $groupId');
    final updated = _groups[idx].copyWith(
      memberIds: [..._groups[idx].memberIds, userId],
    );
    _groups[idx] = updated;
    return updated;
  }

  @override
  Future<GroupModel> removeMember(String groupId, String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw StateError('Group not found: $groupId');
    final updated = _groups[idx].copyWith(
      memberIds: _groups[idx].memberIds.where((id) => id != userId).toList(),
      adminIds: _groups[idx].adminIds.where((id) => id != userId).toList(),
    );
    _groups[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _groups.removeWhere((g) => g.id == groupId);
  }

  @override
  Future<GroupModel> setAdminStatus(
    String groupId,
    String userId, {
    required bool isAdmin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _groups.indexWhere((g) => g.id == groupId);
    if (idx == -1) throw StateError('Group not found: $groupId');
    final current = _groups[idx];
    final updatedAdmins = isAdmin
        ? [...current.adminIds, userId]
        : current.adminIds.where((id) => id != userId).toList();
    final updated = current.copyWith(adminIds: updatedAdmins);
    _groups[idx] = updated;
    return updated;
  }
}
