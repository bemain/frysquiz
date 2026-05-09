import '../models/user_model.dart';

abstract interface class AuthService {
  Future<UserModel?> login(String email, String password);
  Future<void> logout();
}
