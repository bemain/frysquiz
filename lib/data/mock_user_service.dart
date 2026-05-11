import 'package:frysquiz/core/models/user_model.dart';

import '../core/services/user_service.dart';
import 'mock_data.dart';

class MockUserService implements UserService {
  final List<UserModel> _users = List.from(MockData.users);

  @override
  Future<List<UserModel>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_users);
  }
}
