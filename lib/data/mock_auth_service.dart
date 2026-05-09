import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';
import 'mock_data.dart';

class MockAuthService implements AuthService {
  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<UserModel?> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final expectedPassword = MockData.credentials[email.toLowerCase()];
    if (expectedPassword == null || expectedPassword != password) return null;
    try {
      return MockData.users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
