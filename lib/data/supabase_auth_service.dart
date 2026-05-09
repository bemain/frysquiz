import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import 'database.dart';

class SupabaseAuthService implements AuthService {
  final _client = Database.client;

  @override
  Future<UserModel?> login(String email, String password) async {
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (res.user == null) return null;
    return _fetchProfile(res.user!.id);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    return _fetchProfile(userId);
  }

  Future<UserModel?> _fetchProfile(String userId) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (profile == null) return null;
    final memberships = await _client
        .from('group_members')
        .select('group_id')
        .eq('user_id', userId);
    final groupIds = (memberships as List)
        .map((m) => m['group_id'] as String)
        .toList();
    return UserModel.fromJson({...profile, 'group_ids': groupIds});
  }

  @override
  Future<void> logout() async {
    await _client.auth.signOut();
  }
}
