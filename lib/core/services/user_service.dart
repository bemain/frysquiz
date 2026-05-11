import '../models/user_model.dart';

abstract interface class UserService {
  Future<List<UserModel>> getAllUsers();
}
