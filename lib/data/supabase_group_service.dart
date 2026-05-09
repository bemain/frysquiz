import '../core/models/group_model.dart';
import '../core/services/group_service.dart';
import 'database.dart';

class SupabaseGroupService implements GroupService {
  final _client = Database.client;

  Future<GroupModel> _buildGroup(Map<String, dynamic> row) async {
    final members = await _client
        .from('group_members')
        .select('user_id, is_admin')
        .eq('group_id', row['id'] as String);
    final memberIds = (members as List)
        .map((m) => m['user_id'] as String)
        .toList();
    final adminIds = members
        .where((m) => m['is_admin'] == true)
        .map((m) => m['user_id'] as String)
        .toList();
    return GroupModel.fromJson({
      ...row,
      'member_ids': memberIds,
      'admin_ids': adminIds,
    });
  }

  @override
  Future<List<GroupModel>> getAllGroups() async {
    final rows = await _client.from('groups').select();
    return Future.wait((rows as List).map((r) => _buildGroup(r)));
  }

  @override
  Future<List<GroupModel>> getGroupsForUser(String userId) async {
    final memberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    final ids = (memberships as List)
        .map((m) => m['group_id'] as String)
        .toList();
    if (ids.isEmpty) return [];
    final rows = await _client.from('groups').select().inFilter('id', ids);
    return Future.wait((rows as List).map((r) => _buildGroup(r)));
  }

  @override
  Future<GroupModel?> getGroupById(String id) async {
    final row = await _client
        .from('groups')
        .select()
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _buildGroup(row);
  }

  @override
  Future<GroupModel> createGroup({
    required String name,
    required String description,
    required bool isOpen,
    required String creatorId,
  }) async {
    final row = await _client
        .from('groups')
        .insert({'name': name, 'description': description, 'is_open': isOpen})
        .select()
        .single();
    await _client.from('group_members').insert({
      'group_id': row['id'],
      'user_id': creatorId,
      'is_admin': true,
    });
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> addMember(String groupId, String userId) async {
    await _client.from('group_members').upsert({
      'group_id': groupId,
      'user_id': userId,
      'is_admin': false,
    });
    final row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> removeMember(String groupId, String userId) async {
    await _client
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
    final row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    return _buildGroup(row);
  }

  @override
  Future<GroupModel> setAdminStatus(
    String groupId,
    String userId, {
    required bool isAdmin,
  }) async {
    await _client
        .from('group_members')
        .update({'is_admin': isAdmin})
        .eq('group_id', groupId)
        .eq('user_id', userId);
    final row = await _client
        .from('groups')
        .select()
        .eq('id', groupId)
        .single();
    return _buildGroup(row);
  }
}
