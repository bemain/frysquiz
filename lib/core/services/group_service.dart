import '../models/group_model.dart';

abstract interface class GroupService {
  Future<List<GroupModel>> getAllGroups();
  Future<List<GroupModel>> getGroupsForUser(String userId);
  Future<GroupModel?> getGroupById(String id);
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required bool isOpen,
    required String creatorId,
  });
  Future<GroupModel> addMember(String groupId, String userId);
  Future<GroupModel> removeMember(String groupId, String userId);
  Future<GroupModel> setAdminStatus(
    String groupId,
    String userId, {
    required bool isAdmin,
  });
  Future<void> deleteGroup(String groupId);
}
