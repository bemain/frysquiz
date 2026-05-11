import '../core/models/user_model.dart';
import '../core/services/user_service.dart';
import 'database.dart';

class SupabaseUserService implements UserService {
  final _client = Database.client;

  @override
  Future<List<UserModel>> getAllUsers() async {
    final rows = await _client.from('profiles').select();
    return (rows as List).map((r) => UserModel.fromJson(r)).toList();
  }
}
